#!/usr/bin/env bash
# Sincroniza la skill hermes-agent de Hermes con el directorio global de
# skills de OpenCode (~/.config/opencode/skills/hermes-agent).
#
# Uso:  sync-hermes-agent-skill.sh [--dry-run]
#
# Copia SKILL.md (con frontmatter adaptado a OpenCode), references/ y
# templates/. Idempotente: borra el destino y lo vuelve a crear.

set -euo pipefail

SRC="${HERMES_AGENT_SKILL_SRC:-$HOME/.hermes/skills/autonomous-ai-agents/hermes-agent}"
DST="${OPENCODE_SKILLS_DIR:-$HOME/.config/opencode/skills}/hermes-agent"
DRY=0
[[ "${1:-}" == "--dry-run" ]] && DRY=1

[[ -f "$SRC/SKILL.md" ]] || { echo "ERROR: no existe $SRC/SKILL.md" >&2; exit 1; }
command -v python3 >/dev/null || { echo "ERROR: falta python3" >&2; exit 1; }

if [[ $DRY == 1 ]]; then
  echo "DRY-RUN: $SRC -> $DST"
  echo "--- frontmatter resultante ---"
  python3 "$(dirname "$0")/hermes_agent_skill_frontmatter.py" "$SRC/SKILL.md"
  exit 0
fi

rm -rf "$DST"
mkdir -p "$DST"
cp -r "$SRC/references" "$SRC/templates" "$SRC/SKILL.md" "$DST/" 2>/dev/null || true
[[ -d "$SRC/references" ]] || cp -r "$SRC/references" "$DST/"
[[ -d "$SRC/templates" ]] && cp -r "$SRC/templates" "$DST/" || true

NEWFM=$(python3 "$(dirname "$0")/hermes_agent_skill_frontmatter.py" "$SRC/SKILL.md")
python3 - "$SRC/SKILL.md" "$DST/SKILL.md" "$NEWFM" <<'PY'
import sys
src, dst, newfm = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(src, encoding='utf-8').read()
if text.startswith('---'):
    end = text.index('\n---', 3) + 4
    body = text[end:]
else:
    body = text

note = (
    "<!-- Copia para OpenCode de la skill `hermes-agent` de Hermes Agent.\n"
    "     No editar a mano: regenerar con ~/.local/bin/sync-hermes-agent-skill.sh\n"
    "     Los ficheros de apoyo (references/, templates/) viven junto a este SKILL.md;\n"
    "     las rutas de esta guía son relativas a ese directorio. Las llamadas\n"
    "     `terminal(...)`/`process(...)` de los ejemplos son herramientas de Hermes:\n"
    "     en OpenCode, tradúcelas a bash y a tus propias herramientas. -->\n\n"
)
open(dst, 'w', encoding='utf-8').write(newfm.rstrip('\n') + '\n' + note + body.lstrip('\n'))
PY

echo "OK -> $DST"
find "$DST" -type f | sed "s|$DST/||" | sort
