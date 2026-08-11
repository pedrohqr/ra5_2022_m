# RA5 2022 M — Base Board (Raptor)

Base/carrier board for a modular PLC (Programmable Logic Controller): an I/O
front-end with no main MCU of its own — sensing and metering peripherals are
driven by a separate MCU+LTE modem card that plugs into the onboard M.2
Key-E socket (`J1`, visible in the photos below). The socket follows the M.2
mechanical form factor but uses a custom pinout (native 3.3V logic) — it is
not meant to accept an off-the-shelf M.2 card. The pluggable MCU+modem card
itself now lives in its own separate repository, developed independently
from this base board.

Main blocks on this board:

- **Power**: input via the `B0303S-1W` isolated DC-DC module, `TPS54202DDC`
  buck regulator, `AMS1117-3.3` linear regulator (USB rail), and a USB-C
  connector that passes through to `J1` for flashing/debugging the plugged-in
  MCU card.
- **2x differential 4-20mA analog inputs** via an `ADS1115` I2C ADC.
- **2x digital inputs and 2x digital outputs**, opto/divider-conditioned and
  transistor-driven respectively.
- **`ATM90E32AS` three-phase energy meter**, in a galvanically isolated
  domain (`GND2`/`VDD2`) from the rest of the board, bridged via the
  `ISO7741N1-Y` digital isolator (SPI) and a `CS817X20LS`-family isolator
  (power-mode select).
- **`STM8S003F3P` housekeeping MCU**, reading/driving the digital I/O signals
  and intended to expose them over the shared I2C bus on `J1`.
- `KF250-3.5-2P-2` screw terminals for the current loops and other
  field-side connections.

## Renders of the finished board

![Board view 1](view/view1.png)
*Component-side view: the M.2 socket (`J1`) in the center, screw terminals
and field connectors along the edges, and the row of MOVs/varistors feeding
the energy-meter current inputs.*

![Board view 2](view/view2.png)
*Same side, rotated ~180°, showing the USB-C connector, the STM8
housekeeping MCU, and the power section.*
