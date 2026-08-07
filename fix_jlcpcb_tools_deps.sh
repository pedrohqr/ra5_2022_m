#!/bin/bash
# The kicad-jlcpcb-tools plugin imports `requests`, which isn't bundled with
# KiCad's embedded Python 3.11 and wasn't vendored into the plugin's lib/
# folder (unlike `packaging`, which is). Its __init__.py silently swallows
# the resulting ImportError, so the toolbar icon just never appears with no
# visible error. This installs requests + deps (cp311/manylinux2014, matching
# KiCad's embedded interpreter) straight into the plugin's lib/ folder, the
# same place it already vendors `packaging`.
#
# Re-run this after any JLCPCB Tools update/reinstall, since it will likely
# wipe out lib/requests again.
set -euo pipefail

PLUGIN_DIR="/home/usuario/.local/share/kicad/10.0/3rdparty/plugins/com_github_bouni_kicad-jlcpcb-tools"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

if [ ! -d "${PLUGIN_DIR}" ]; then
  echo "Plugin dir not found: ${PLUGIN_DIR}" >&2
  exit 1
fi

pip3 install --target="${WORKDIR}" --no-deps --only-binary=:all: \
  --python-version 3.11 --implementation cp --abi cp311 \
  --platform manylinux2014_x86_64 --platform manylinux_2_17_x86_64 \
  requests urllib3 idna certifi charset_normalizer

rm -rf "${WORKDIR}/bin"
cp -r "${WORKDIR}/." "${PLUGIN_DIR}/lib/"

echo "Done. Restart KiCad (or Tools > External Plugins > Refresh Plugins) to pick it up."
