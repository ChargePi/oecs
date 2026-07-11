# OECS Guideline

This is the narrative companion to `schema/1.0.0/charger.schema.json`. The schema is the source of truth for field
names, types, and constraints (every field carries a `description`); this document explains *why* the schema is shaped
the way it is and how to fill one out from real-world source material.

## What a document represents

An OECS document describes one charger **model** — a product a manufacturer sells, identified by `manufacturer` +
`model`. Everything else in the document is a claim about that product's capabilities, drawn from a datasheet, manual,
or certification report.

## Top-level shape

```
{
  version, manufacturer, model,       // identity
  hardware,                            // physical/electrical spec (required)
  software,                            // protocols, firmware, config (optional)
  payment,                             // accepted payment methods, terminal (optional)
  metadata                             // sources, certificates, provenance (optional)
}
```

`hardware` is required because every charger has *some* physical form; `software`, `payment`, and `metadata` are
optional so you can publish a partial spec (e.g. hardware-only, before software details are confirmed) and fill it in
incrementally. Prefer omitting a field entirely over guessing a value — an absent field is honest; a wrong one is worse
than no data.

## Conventions used throughout

**Quantities and ranges.** Numeric values are never bare numbers — they're always `{ "value": ..., "unit": "..." }` (a
`quantity`) or `{ "min"/"max"/"nominal": ..., "unit": "..." }` (a `valueRange`). This is the single most repeated
pattern in the schema; it exists so a consumer never has to guess whether `32` means amps, kW, or millimeters, and so a
range like "6–32 A" doesn't get flattened into a single misleading number. Most units are free-text strings — use the
unit as printed on the datasheet (`kW`, `A`, `V`, `%RH`, `mm`, `kg`, `dBA`, `m`, `s`) rather than inventing a symbol.
Temperature is the one exception: `operatingTemperature`/`storageTemperature` use a dedicated `temperatureRange` type
with `unit` restricted to `"C"` or `"F"`, so tooling can rely on it instead of parsing free text.

**Enums with an escape hatch.** Closed lists (connector types, protocol names, certificate types) cover the common cases
so tooling can rely on them, but real hardware surprises you. Where the schema anticipates that (
`software.protocols[].name`), pick `"other"` and fill the sibling `otherName` field. Where it doesn't (e.g.
`hardware.housing.material`), either pick the closest fit or open an issue/PR to extend the enum — enum extension is
treated as a non-breaking, additive change.

**Dates and versions.** Dates are ISO 8601 (`YYYY-MM-DD`); timestamps are RFC 3339. Version strings (firmware, protocol
versions) are loose free text rather than strict SemVer, because standards like ISO 15118 version themselves as
`ISO 15118-2:2014`, not `2.0.0` — use whatever the standard/vendor actually calls it.

**Feature clusters over boolean fields.** Where a section would otherwise be a run of independent yes/no properties
describing the same kind of thing (protection devices present, network interfaces present, safety features present,
smart-charging capabilities present), the schema uses a single `features` (or `interfaces`) string array instead — e.g.
`hardware.protection.features: ["overcurrent", "ground-fault", ...]` rather than
`overcurrentProtection: true, groundFaultProtection: true, ...`. This keeps the schema flatter as new features get added
over time (an enum value, not a new property) and makes "does it have X" a single array-membership check. A boolean
stays a boolean when it's the only fact of its kind on the object (e.g. `payment.adHocPaymentSupported`) or when it's a
genuine two-state fact about a specific other field rather than one of a family of features (e.g.
`connector.cable.attached`).

**Certification vs. self-reported capability.** A feature flag like `"v2g"` in `software.smartCharging.features` is a
capability claim; it says nothing about whether that capability was independently verified. Verified claims are
certificates (`type` + `standard` + issuing body), and a certificate is placed as close as possible to the thing it
certifies rather than in one catch-all list: `software.protocols[].certifications` for a certificate tied to one
specific protocol/version (an OCPP conformance certificate, an ISO 15118 security certification),
`hardware.certifications` for one covering the hardware/enclosure as a whole (safety, EMC, type approval).
When a capability claim and a certificate both exist, they should agree — a capability claim with no
corresponding certificate just means "vendor states this, unverified," which is fine and common, but don't invent a
certificate to back a guess.

## Section-by-section

### `manufacturer` / `model`

Product identity. `model.type` (`AC` / `DC` / `portable-evse` / `wireless`) plus `model.level` (a free-text power/speed
tier like `'Level 2'` or `'DC Fast'`) give a coarse classification for filtering a catalog of specs at a glance — the
real power figures live in `hardware.electrical.output`. `level` is free text rather than an enum because tier
terminology varies by standard and region (SAE J1772 "Level 1/2" vs. informal "DC Fast/Ultra-Fast" marketing tiers).
`model.status` tracks product lifecycle (`pre-release` / `active` / `discontinued` / `end-of-life`), useful for flagging
specs that describe something no longer sold. `brandingOptions` lists customization available to a network
operator/reseller who wants to brand the unit as their own (a custom faceplate, a rebrandable on-device/app UI, custom
LED accent color, or a full white-label offering with no manufacturer branding at all).

### `hardware`

- **`housing`** — enclosure, mounting, environmental ratings. `ingressProtection` and `impactRating` are validated
  against the `IPxx` / `IKxx` patterns (IEC 60529 / IEC 62262) — copy them straight off the datasheet.
- **`electrical`** — everything about the charger's electrical system, grouped into three sub-objects since they're all
  facets of the same thing:
    - `input` — the grid connection *feeding* the charger (supply voltage/current/frequency, hardwired vs. plug-in,
      standby draw). About what the charger consumes, not what it delivers.
    - `output` — aggregate delivery capability of the unit as a whole (e.g. "150 kW split across 2 connectors").
      Per-connector ratings belong on the connector itself; use `output` for whole-unit ceilings.
      `simultaneousChargingSupported` and `dynamicPowerSharing` only make sense with 2+ connectors — omit both on a
      single-connector charger rather than setting them to `false`.
    - `protection` — electrical safety devices. RCD `types` follow IEC 62955/60755 (`AC`, `A`, `B`, `F`,
      `integrated-6mA-DC`) — DC fast chargers typically need Type B or the integrated 6 mA DC variant, AC wallboxes
      typically Type A. `surgeProtection` and `overVoltageCategory` are their own fields since each carries a specific
      class/category value; the remaining simple presence/absence facts (overcurrent, short-circuit, insulation
      monitoring, ground fault, over-temperature, overload) are collected into one `features` array instead of six
      separate booleans.
- **`connectors`** — one entry per physical outlet/plug, each with its own `type` (CCS2, CHAdeMO, Type 2, NACS, etc.),
  `currentType` (AC/DC), and ratings. `label` is a free-text human identifier for readability only (e.g.
  `"CCS2 outlet A"`) — it is **not** required to be unique and carries no semantic meaning for tooling; don't build
  logic that keys off it. If you need to refer to "the connector that supports CCS2," filter by `type`, not by label.
- **`userInterface`** — the physical HMI: display type, supported authentication methods, language support.
- **`connectivity`** — the network hardware. `interfaces` is a single array (`ethernet`, `bluetooth`, `rs485`,
  `can-bus`, `powerline-communication`) rather than one boolean per interface; `wifi` and `cellular` stay as their own
  fields since each needs more than a yes/no (standards supported, generations, SIM slots). Distinct from
  `software.protocols`, which describes what runs *over* this connectivity.
- **`safety`** — mechanical/operational safety features beyond electrical protection, as a `features` array (
  `emergency-stop`, `tamper-detection`, `anti-theft-lock`).
- **`meter`** — the charger's primary energy meter: manufacturer/model, accuracy class, and legal metrology
  certification (MID, Eichrecht, ANSI C12.20, etc.) if it has one. A filled-in `certification` is what makes the meter
  billing-grade. Separate from `connectors[].meterAccuracyClass`, which covers sub-metering at an individual outlet.
- **`certifications`** — formal certifications covering the hardware/enclosure as a whole (safety, EMC, type approval),
  each with `type`, `standard`, issuing body, and dates where known.

### `software`

- **`firmware`** — current version and update mechanism, not a changelog.
- **`protocols`** — one entry per communication protocol/standard, each with `version` and a `profiles` array listing
  the specific feature blocks supported (e.g. OCPP 1.6's `Core`, `SmartCharging`, `RemoteTrigger`; OCPI's `locations`,
  `cdrs`, `tariffs`). `profiles` is intentionally free-text rather than a fixed enum per protocol — the set of profiles
  differs per protocol and version, and a closed enum would need constant maintenance as standards evolve.
  `certifications` holds any certificates tied specifically to that protocol/version (e.g. an OCPP conformance
  certificate); `configuration` holds settings surfaced by that protocol specifically (e.g. the OCPP configuration key
  `HeartbeatInterval`). Omit either if none apply. If a charger implements the same protocol at multiple versions, place
  a protocol-specific setting under whichever version entry it actually applies to.
- **`smartCharging`** — a `features` array (`local-load-balancing`, `backend-managed-profiles`, `dynamic-pricing`,
  `v2g`, `v2h`, `solar-integration`) plus which schedule types the unit supports.
- **`configuration`** — the exposed, settable configuration surface for settings *not* tied to a specific protocol (e.g.
  a site-configurable current cap enforced regardless of which protocol is active). Each entry has a `dataType`,
  optional bounds/allowed values, and whether changing it needs a reboot. This documents *what can be configured*, not
  the specific values chosen for a given deployment — deployment-specific values belong in your own commissioning
  records, outside the scope of this schema.
- **`integration`** — interfaces for local administration or building a custom/third-party integration, as distinct from
  `protocols`. `protocols` is for standardized EV-charging/cloud protocols (OCPP, OCPI, ISO 15118, ...); `integration`
  covers a local web admin UI (`webUI`) and the transport(s) available for talking to the charger directly (
  `localInterfaces`: `http`, `grpc`, `mqtt`, `modbus`, `websocket`, `webhooks`, `ssh`, `serial`) — meant for someone
  building their own tooling against this specific charger rather than a standard protocol.
- **`offlineChargingSupported`** — whether the unit can authorize and run sessions without a live backend/CSMS
  connection (standalone/offline mode).

### `payment`

A standalone section because payment spans both hardware (a card terminal) and policy (which methods are accepted)
without belonging cleanly to either `hardware` or `software`. `acceptedMethods` distinguishes *how a driver pays* from
`hardware.userInterface.authenticationMethods`, which is about *how a session is authorized/started* — the two often
overlap in practice (e.g. an RFID card can do both) but answer different questions. `adHocPaymentSupported` matters for
regulatory compliance: public DC chargers in the EU (AFIR) and increasingly other jurisdictions must accept card payment
without requiring an app or subscription. `terminal` is only relevant if the charger has its own integrated card reader
rather than relying entirely on an app/backend for billing.

### `metadata`

- **`sources`** — the documents this specification instance was compiled from (datasheet, manual, technical spec,
  conformance report). Always populate this when transcribing from a vendor PDF or webpage — it's what makes the spec
  auditable and re-derivable when the vendor updates their docs.
- **`certificates`** — formal certifications that don't fit under `hardware.certifications` or a specific protocol's
  `certifications` (e.g. a company-wide quality management certification), with `type`, `standard`, issuing body, and
  validity dates where known. See the "Certification vs. self-reported capability" convention above for the full
  placement rule.
- **`document`** — bookkeeping about the OECS document itself (who compiled it, when, under what license) — not about
  the product.

## Extending the schema

Prefer additive changes: new optional properties, new enum values, new `$defs`. Reserve a new `schema/<version>/`
directory for anything that removes a field, tightens a constraint, or otherwise breaks existing valid documents, and
bump `version` accordingly. See the examples in `examples/` before and after any schema change — they're the fastest way
to confirm a change is actually additive.
