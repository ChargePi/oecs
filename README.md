# OECS — Open EV Charger Specification

A vendor-neutral **JSON Schema** for describing the functional and technical specification of an EV charger: hardware (
electrical, mechanical, connectors), software (communication protocols, configuration, smart-charging capability),
payment (accepted methods, terminal), pricing (MSRP, or on-request), and the compliance metadata (datasheets,
certificates) behind that data.

One OECS document describes one charger **model** - a machine-readable counterpart to a manufacturer's datasheet.

## Repository layout

```
schema/1.0.0/           JSON Schema (draft 2020-12), split into modules
schema/1.1.0/           Adds pricing (see Versioning below)
schema/1.1.1/           Extracts manufacturer into its own module, adds manufacturer.logoUrl (patch, see Versioning)
  charger.schema.json      root document schema — start here
  manufacturer.schema.json manufacturer identity, country, logo, contact (1.1.1+ only, split out of charger.schema.json)
  hardware.schema.json     housing, electrical I/O, protection, UI, connectivity, safety
  connector.schema.json    per-connector (plug) definition
  software.schema.json     firmware, protocols/profiles, smart charging, configuration
  payment.schema.json      accepted payment methods, ad-hoc payment, terminal hardware
  pricing.schema.json      manufacturer's MSRP, optionally by region, or enquiry-only (1.1.0+ only)
  metadata.schema.json     sources, certificates, document bookkeeping
  common.schema.json       shared primitives (quantities, ranges, ratings, dates)

examples/                Example documents validated against the schema
  minimal.json              smallest valid document (1.0.0)
  ac-wallbox-full.json      AC Level 2 wallbox with regional pricing, most fields populated (1.1.1)
  dc-fast-charger-full.json DC fast charger with two connectors (CCS2 + CHAdeMO), enquiry-only pricing (1.1.1)

docs/GUIDELINE.md        Narrative guide: how to fill out a spec, field-by-field

scripts/bundle.go        Generates dist/<version>/oecs.<version>.schema.json (see Bundled distribution below)
Makefile                 `make bundle` / `make clean`
```

## Bundled distribution

Each `schema/<version>/*.schema.json` is the maintained source for that version, split into modules for reuse and
easier review (see `docs/GUIDELINE.md`'s note on why). For consumers who want one self-contained file with no
cross-file `$ref`s, run:

```
make bundle
```

This regenerates `dist/<version>/oecs.<version>.schema.json` for every schema version — a single-file, fully
self-contained equivalent of that version's `charger.schema.json`, at a path derived from the schema's own declared
version. It's generated output, not hand-edited; re-run `make bundle` after any change under `schema/`. `make clean`
removes `dist/`.

## Versioning

Schema modules live under a version directory (`schema/1.0.0/`, `schema/1.1.0/`, `schema/1.1.1/`, ...), following
semver: a patch bump (`1.1.0` → `1.1.1`) covers changes that don't add a new capability a document could rely on —
reorganizing `$defs` across modules (e.g. splitting a section out into its own file) or a small optional field riding
along with such a reorganization; a minor bump (`1.0.0` → `1.1.0`) adds new optional fields/`$defs`/segments without
touching anything already committed to the prior version; a major bump gets its own directory for anything that
removes a field, tightens a constraint, or otherwise breaks existing valid documents. In every case, existing
documents written for a prior version keep validating unchanged. Documents declare `version` and validate against the
schema version they were written for.

## Contributing

Extend enums and add optional fields freely — the schema favors additive, non-breaking changes. Where a field's value
comes from an external, evolving standard (protocol names, connector types), prefer an `enum` with an `other`/
`otherName` escape hatch over an exhaustive closed list. See `docs/GUIDELINE.md` for the conventions used throughout (
units, ranges, extensibility).
