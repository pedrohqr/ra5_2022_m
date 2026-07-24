# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

This is a KiCad 10 hardware design project (PCB + schematics), not a software application — there is no build, lint, or test suite to run. The board is named "RA 5 2022 M" (company: Raptor). Project files:

- `ra5_2022.kicad_pro` — project settings (design rules, net classes, ERC/DRC severities, BOM presets)
- `ra5_2022.kicad_sch` — top-level (root) schematic, which only instantiates two hierarchical sub-sheets:
  - `power_source.kicad_sch` — power path: buck regulator (`AP63203WU`), PMOS load switch, Schottky/Zener diodes, inductor, LED indicator, and the custom `B0303S-1W` power module and `KF250-3.5-2P-2` terminal block
  - `mcu.kicad_sch` — MCU section built around an `ESP32-C6-MINI-1` RF module, crystal, and decoupling caps
- `ra5_2022.kicad_pcb` — the PCB layout

When editing schematics/PCB, treat the `.kicad_sch`/`.kicad_pcb`/`.kicad_pro` files as structured S-expression/JSON data — edit them with precision (matching UUIDs, instance paths, etc. matter to KiCad) rather than free-form text edits.

## Roadmap: RA5 2044 (next revision, planned)

The next hardware revision, **RA5 2044**, is a CLP (Controlador Lógico Programável / PLC) built around the same `ESP32-C6` used in this project. Planned scope:

- 2x differential 4-20mA analog inputs, read via an external ADC (**ADS1115**) rather than the ESP32's built-in ADC
- 4x digital inputs
- 4x digital outputs
- An **Atmel/Microchip M90E32AS** three-phase energy meter IC, electrically isolated from the main power supply

This revision does not have its own schematic/PCB files yet in this repo — when work on it begins, expect a new hierarchical sheet (or new project) for the ADS1115 analog front-end and the M90E32AS metering section, plus an isolation barrier between the metering section and the main power rail.

## Custom parts library

Non-standard parts (anything not in KiCad's built-in libraries) live in a project-local library named `ra5_2022`, registered via `fp-lib-table` / `sym-lib-table` using `${KIPRJMOD}`-relative paths so the library is portable and version-controlled alongside the schematic:

- `libraries/ra5_2022.kicad_sym` — symbols
- `libraries/ra5_2022.pretty/` — footprints
- `libraries/ra5_2022.3dshapes/` — 3D models (`.step`/`.wrl`)

These parts (e.g. `ra5_2022:B0303S-1W_C883455`, `ra5_2022:KF250-3.5-2P-2`) are imported from LCSC/EasyEDA using the `easyeda2kicad` tool via the helper script:

```bash
./import_lcsc_component.sh C475163 [C123456 ...]
```

Notes on this script:
- It must be run with `--output` as an **absolute** path (a known bug in `easyeda2kicad` 1.0.1 breaks `--project-relative` when `--output` is relative), even though the resulting library entries are stored project-relative.
- `.easyeda_cache/` is the local cache for this tool and is gitignored (regenerable); the `libraries/` directory itself must always be committed.

## Net classes

Defined in `ra5_2022.kicad_pro` under `net_settings`, matched by name pattern:

| Net class | Pattern examples | Notes |
|---|---|---|
| `Power` | `VCC*`, `VDD*`, `+3V3`, `+5V*`, `*GND*`, `PWR*` | wider tracks/clearance |
| `HighSpeed` | `CLK*`, `SCK`, `SCL`, `PWM*`, `XTAL*` | tighter clearance |
| `HighVoltage` | `HV_*`, `MAINS*`, `AC_*`, `CT?*` | 3.0mm clearance, thicker tracks/vias |
| `JLCPCB` | (fab-specific) | tightest clearance, JLCPCB-oriented defaults |
| `Default` | everything else | |

Keep new net names consistent with these patterns so they get assigned the correct class automatically; don't hand-assign net classes unless a net doesn't fit any pattern.

## Gitignore conventions

`.easyeda_cache/`, `.history/` (VS Code local history), KiCad backup/temp files (`*-backups/`, `*.kicad_sch-bak`, `*.kicad_pcb-bak`, `*.kicad_prl`, `fp-info-cache`, `_autosave-*`, `*.tmp`) are all ignored. `libraries/` is explicitly tracked and must not be ignored.
