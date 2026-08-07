#!/bin/bash
# Generates the Interactive HTML BOM via CLI, bypassing KiCad's "Generate
# Interactive HTML BOM" menu action, which is broken in the 10.0.4 AppImage:
# it bundles wx.xrc's Python module but not its libwx_gtk3u_xrc-3.3.so.2
# shared library, so opening the plugin's settings dialog raises
# ImportError. The CLI entry point skips that dialog entirely.
set -euo pipefail

SHARUN_DIR="/home/usuario/kicad-10.0.4-extracted"
IBOM_PLUGIN="/home/usuario/.local/share/kicad/10.0/3rdparty/plugins/org_openscopeproject_InteractiveHtmlBom/generate_interactive_bom.py"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PCB_FILE="${REPO_DIR}/ra5_2022.kicad_pcb"

env -i HOME="$HOME" \
  APPDIR="${SHARUN_DIR}" \
  LD_LIBRARY_PATH="${SHARUN_DIR}/shared/lib:${SHARUN_DIR}/lib" \
  PYTHONHOME="${SHARUN_DIR}/shared" \
  PYTHONPATH="${SHARUN_DIR}/shared/lib/python3.11/dist-packages:${SHARUN_DIR}/shared/lib/python3.11/site-packages" \
  INTERACTIVE_HTML_BOM_NO_DISPLAY=1 \
  DISPLAY="${DISPLAY:-}" \
  "${SHARUN_DIR}/bin/python3.11" "${IBOM_PLUGIN}" \
  --dest-dir "${REPO_DIR}" \
  "$@" \
  "${PCB_FILE}"
