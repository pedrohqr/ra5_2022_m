#!/usr/bin/env bash
# Importa um ou mais componentes LCSC/EasyEDA (ex: C475163) para a biblioteca
# local do projeto "ra5_2022" (libraries/ra5_2022.kicad_sym / .pretty / .3dshapes),
# usando paths relativos ao projeto (${KIPRJMOD}) para que a lib fique portavel
# e possa ser versionada no git junto com o schematic/pcb.
#
# Uso:
#   ./import_lcsc_component.sh C475163 [C123456 ...]

set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "Uso: $0 <LCSC_ID> [LCSC_ID ...]" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_BASE="${SCRIPT_DIR}/libraries/ra5_2022"

for id in "$@"; do
  echo "== Importando ${id} =="
  # --output precisa ser um path ABSOLUTO: o easyeda2kicad 1.0.1 tem um bug
  # em --project-relative quando --output e relativo (ValueError em relative_to).
  easyeda2kicad \
    --full \
    --lcsc_id "${id}" \
    --output "${OUTPUT_BASE}" \
    --project-relative \
    --overwrite \
    --use-cache
done

echo
echo "Pronto. Componentes disponiveis na lib 'ra5_2022' (sym-lib-table / fp-lib-table do projeto)."
