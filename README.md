# OECS — Open EV Charger Specification

A vendor-neutral **JSON Schema** for describing the functional and technical specification of an EV charger: hardware (
electrical, mechanical, connectors), software (communication protocols, configuration, smart-charging capability),
payment (accepted methods, terminal), and the compliance metadata (datasheets, certificates) behind that
data.

One OECS document describes one charger **model** - a machine-readable counterpart to a manufacturer's datasheet.

## Repository layout

```
schema/1.0.0/           JSON Schema (draft 2020-12), split into modules
  charger.schema.json      root document schema — start here
  hardware.schema.json     housing, electrical I/O, protection, UI, connectivity, safety
  connector.schema.json    per-connector (plug) definition
  software.schema.json     firmware, protocols/profiles, smart charging, configuration
  payment.schema.json      accepted payment methods, ad-hoc payment, terminal hardware
  metadata.schema.json     sources, certificates, document bookkeeping
  common.schema.json       shared primitives (quantities, ranges, ratings, dates)

examples/                Example documents validated against the schema
  minimal.json              smallest valid document
  ac-wallbox-full.json      AC Level 2 wallbox, most fields populated
  dc-fast-charger-full.json DC fast charger with two connectors (CCS2 + CHAdeMO)

docs/GUIDELINE.md        Narrative guide: how to fill out a spec, field-by-field

scripts/bundle.go        Generates dist/<version>/oecs.<version>.schema.json (see Bundled distribution below)
Makefile                 `make bundle` / `make clean`
```

## Bundled distribution

`schema/1.0.0/*.schema.json` is the maintained source, split into modules for reuse and easier review (see `docs/GUIDELINE.md`'s note on why). For consumers who want one self-contained file with no cross-file `$ref`s, run:

```
make bundle
```

This regenerates `dist/1.0.0/oecs.1.0.0.schema.json` — a single-file, fully self-contained equivalent of
`schema/1.0.0/charger.schema.json`, at a path derived from the schema's own declared version. It's generated output, not
hand-edited; re-run `make bundle` after any change under `schema/1.0.0/`. `make clean` removes `dist/`.

## Versioning

Schema modules live under a version directory (`schema/1.0.0/`). Breaking changes to the schema get a new version
directory (e.g. `schema/2.0.0/`) rather than mutating an existing one in place, so documents can declare `version`
and keep validating against the schema version they were written for.

## Contributing

Extend enums and add optional fields freely — the schema favors additive, non-breaking changes. Where a field's value
comes from an external, evolving standard (protocol names, connector types), prefer an `enum` with an `other`/
`otherName` escape hatch over an exhaustive closed list. See `docs/GUIDELINE.md` for the conventions used throughout (
units, ranges, extensibility).
