#!/usr/bin/env python3
"""Extrae el frontmatter de la SKILL.md de Hermes y lo reescribe con los campos
que OpenCode sabe interpretar (name, description, license, compatibility,
metadata como mapa string->string). Imprime el bloque YAML resultante."""
import re
import sys

src = sys.argv[1]
text = open(src, encoding='utf-8').read()
fm = {}
if text.startswith('---'):
    end = text.index('\n---', 3)
    block = text[3:end]
    for line in block.splitlines():
        m = re.match(r'^([A-Za-z0-9_-]+):\s*(.*)$', line)
        if m:
            fm[m.group(1)] = m.group(2).strip().strip('"').strip("'")

name = fm.get('name', 'hermes-agent')
desc = fm.get('description', 'Use, configure, theme, extend, and orchestrate Hermes Agent.')
version = fm.get('version', 'unknown')
author = fm.get('author', 'Hermes Agent')
license_ = fm.get('license', 'MIT')

print(f'''---
name: {name}
description: "{desc}"
license: {license_}
compatibility: "Skill de Hermes Agent v{version} ({author}); copia sincronizada desde ~/.hermes/skills/autonomous-ai-agents/hermes-agent"
metadata:
  source: hermes-agent skill v{version}
  upstream: https://github.com/NousResearch/hermes-agent
  docs: https://hermes-agent.nousresearch.com/docs
  synced-by: sync-hermes-agent-skill.sh
---''')
