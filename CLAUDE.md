# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

This is a KiCad 10 hardware design project (PCB + schematics), not a software application — there is no build, lint, or test suite to run. The board is named "RA 5 2022 M" (company: Raptor). Project files:

- `ra5_2022.kicad_pro` — project settings (design rules, net classes, ERC/DRC severities, BOM presets)
- `ra5_2022.kicad_sch` — top-level (root) schematic, which instantiates two hierarchical sub-sheets:
  - `power_source.kicad_sch` — power path: buck regulator (`TPS54202DDC`), AMS1117-3.3 linear reg (USB-powered path), load-switch transistor, Schottky/Zener diodes, inductor, LED indicator, and the custom `B0303S-1W` power module and `KF250-3.5-2P-2` terminal block
  - `mcu.kicad_sch` — no longer hosts an MCU itself (see "Architecture" below); today it's the M.2 Key-E socket (`J1`), digital isolators (`ISO7741N1-Y`, `CS817X20LS`), USB-C connector, AMS1117-3.3, and an `STM8S003F3P` housekeeping MCU. It instantiates three further sub-sheets:
    - `analog_io.kicad_sch` — 2x differential 4-20mA current-loop inputs into an **ADS1115** (I2C ADC)
    - `digital_io.kicad_sch` — 2x opto/divider-conditioned digital inputs, 2x transistor-driven digital outputs
    - `m90e32as.kicad_sch` — **ATM90E32AS** three-phase energy meter, galvanically isolated (own `GND2`/`VDD2` domain) from the rest of the board
- `ra5_2022.kicad_pcb` — the PCB layout

When editing schematics/PCB, treat the `.kicad_sch`/`.kicad_pcb`/`.kicad_pro` files as structured S-expression/JSON data — edit them with precision (matching UUIDs, instance paths, etc. matter to KiCad) rather than free-form text edits.

## Architecture: base board + M.2 modem shield

This project is the **base/carrier board** of a two-board system: a CLP (Controlador Lógico Programável / PLC) I/O front-end. No MCU of its own beyond a small housekeeping controller (see STM8 below) — its sensor/metering peripherals are meant to be driven by whatever card is plugged into the M.2 socket (`J1`, in `mcu.kicad_sch`):

- 2x differential 4-20mA analog inputs → **ADS1115** (I2C ADC), in `analog_io.kicad_sch`
- 2x digital inputs + 2x digital outputs, in `digital_io.kicad_sch`
- **ATM90E32AS** three-phase energy meter, isolated (`GND2`/`VDD2` domain) via `ISO7741N1-Y` (SPI) and `CS817X20LS` (`PM0`/`PM1`), in `m90e32as.kicad_sch`

The pluggable MCU+LTE modem card that plugs into `J1` (an MCU built to the M.2 Key-E mechanical form factor) now lives in **its own separate repository** (`ra5_shield_modem`) rather than as a sibling project in this repo — it was removed from here on 2026-08-11.

### The M.2 socket is a custom pinout, not a real Key-E device

`J1` (`Connector:Bus_M.2_Socket_E` symbol, `ra5_2022:CONN-SMD_AS0BC21-S48BE-7H` footprint) is repurposed as a **board-to-board connector between our own designs** (this base board ↔ `ra5_shield_modem`, or any future alternate base board using the same shield) — it is *not* meant to accept a real off-the-shelf M.2 Key-E card (WiFi/BT/WWAN module). Consequence: every signal runs at native **3.3V** logic; the 1.8V domain the PCI-SIG spec assigns to `SDIO_*`/`PCM_*` pins is intentionally ignored, and no level-shifters are used anywhere on this bus. Only reuse pin *positions/names* from the spec as a mnemonic convention — do not assume real Key-E electrical compliance.

Current `J1` pin assignment (all other pins unconnected/reserved for future expansion):

| Pin(s) | Native M.2 name | Signal | Notes |
|---|---|---|---|
| 1,7,18,33,39,45,51,57,63,69,75 | GND | `GND` | main digital ground |
| 2,4,72,74 | 3.3V | `VDD` | powers the shield from the base board |
| 3 / 5 | USB_D+ / USB_D- | `/MCU/USB_DP` / `/MCU/USB_DN` | passthrough of the base board's own USB-C, for flashing/debugging the shield's MCU |
| 9 / 11 / 13 / 19 | SDIO_CLK / SDIO_CMD / SDIO_DATA0 / SDIO_DATA3 | `SCLK` / `MOSI` / `MISO` / `CS` | M90E32AS SPI, reusing the SD/SDIO "SPI mode" pin convention |
| 58 / 60 / 62 | I2C_DATA / I2C_CLK / ALERT# | `SDA` / `SCL` / `ALERT` | shared I2C bus: ADS1115 + the STM8 housekeeping MCU |
| 38 / 40 | VENDOR_DEFINED | `PM0` / `PM1` | M90E32AS power-mode select (isolated side, via `CS817X20LS`) |
| 42, 64 | VENDOR_DEFINED / RESERVED | *free* | spare for future expansion |

### STM8 housekeeping MCU (digital IO → I2C bridge)

`digital_io.kicad_sch`'s 4 conditioned signals (`DIN1_MCU`, `DIN2_MCU`, `DO1_MCU`, `DO2_MCU`) don't get dedicated M.2 pins — an **`STM8S003F3P` (TSSOP20, KiCad native `MCU_ST_STM8:STM8S003F3P` symbol, no library import needed)** reads/drives them locally and exposes everything over the same I2C bus as the ADS1115 (pins `PB5`=`I2C_SDA`, `PB4`=`I2C_SCL`, fixed — not remappable on this part). Current pin usage:

| STM8 pin | Signal |
|---|---|
| `PC3` / `PC4` | `DIN1_MCU` / `DIN2_MCU` (inputs) |
| `PC5` / `PC6` | `DO1_MCU` / `DO2_MCU` (outputs, drive the field-output transistors) |
| `PA3` | `ALERT` (shared with ADS1115's open-drain ALERT#/J1 pin 62 — keep as input only, to avoid contention) |
| `VCAP` (pin 8) | needs a 1µF ceramic cap to `VSS` (pin 7) — internal 1.8V core regulator decoupling, **not yet placed** |
| `PD1`/`SWIM`, `NRST`, `VDD`, `VSS` | 4-pin SWIM programming header (keep `PD1` free of other uses) |

Known open item: `PB4`/`PB5` (I2C) are not yet wired to the shared bus — still needed before the STM8 is usable.

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

### Sharing this library with other projects

Other KiCad projects that are not part of this repo (e.g. the now-separate `ra5_shield_modem` repo, a shield PCB for this board) can still reuse the same `ra5_2022` library rather than duplicating it, by registering it in their own `sym-lib-table`/`fp-lib-table` with an absolute or relative path to this repo's `libraries/` directory (note: `${KIPRJMOD}`-relative paths only work while the library lived inside this repo as a sibling directory — an external repo must use a different relative path or an absolute one).

3D models are the one part of this that is **not** portable across machines: each `.kicad_mod` in `libraries/ra5_2022.pretty/` hardcodes its model path as `${RA5_2022_LIB}/libraries/ra5_2022.3dshapes/...` — `RA5_2022_LIB` is a KiCad environment variable (set per-machine via Preferences → Configure Paths, or in `~/.config/kicad/<version>/kicad_common.json` under `environment.vars`). Anyone opening `ra5_2022` or a project that reuses its library on a new machine needs `RA5_2022_LIB` set to the absolute path of this repo's root for 3D models to resolve.

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

## KiCad Design Variants — known gotcha

The project uses a single KiCad Design Variant, `Develop` (a `Production` variant existed briefly but was removed). Many parts imported via `easyeda2kicad` carry `(variant ...)` blocks per symbol (alternate MPN/LCSC data) — this is normal and harmless. **Never let a variant's `Footprint` field diverge from the symbol's default `Footprint` property.** KiCad 10 mishandles that combination: `Update PCB from Schematic` treats the variant's footprint as a second, separate component instead of an alternate for the same one, silently adding a duplicate footprint on the board every time it runs (this happened repeatedly with `C6`/`C7` in `power_source.kicad_sch` before the variant footprint was aligned to match the default). If a duplicate footprint mysteriously reappears after a sync, check whether that component has a variant with a different `Footprint` value before assuming it's a stale-session/cache issue.

Separately (not variant-related), a one-off sweep in August 2026 found **10 more orphaned duplicate footprints** already sitting in `ra5_2022.kicad_pcb` from older, unrelated design changes (`R11`, `R12`, `C14`, `C16`, `C17`, `C18`, `C29`, `C31`, `C32`, `C35`) — each had one footprint instance whose `(path ...)` no longer matched any current schematic symbol UUID at all (a true orphan, not a variant mismatch). `Update PCB from Schematic`'s "delete extra footprints" option should catch these but evidently hadn't been run with it enabled. If you suspect more are lurking, group every PCB footprint by its `Reference` property and flag any reference appearing more than once — for each duplicate, keep the instance whose `(path ...)` UUID matches the schematic symbol's own `uuid`, and remove the other.

## Gitignore conventions

`.easyeda_cache/`, `.history/` (VS Code local history), KiCad backup/temp files (`*-backups/`, `*.kicad_sch-bak`, `*.kicad_pcb-bak`, `*.kicad_prl`, `fp-info-cache`, `_autosave-*`, `*.tmp`) are all ignored. `libraries/` is explicitly tracked and must not be ignored.
