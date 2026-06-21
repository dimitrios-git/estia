#!/usr/bin/env python3
"""Regenerate CLAUDE.md's deployment tables from the bootstrap manifest.

group_vars/all.yml is the single source of truth for what the `dotfiles` role
deploys; this keeps the human-facing tables in CLAUDE.md from drifting out of sync.
Two tables, each between its own BEGIN/END markers in CLAUDE.md (add them once if
missing):
  - active-symlinks   <- dotfile_links      (plain configs, symlinked)
  - rendered-templates <- templated_configs (path-generalised, rendered from .j2)
Idempotent — run after editing either list. See bootstrap/README.md.
"""
import pathlib
import re
import yaml

REPO = pathlib.Path(__file__).resolve().parent.parent
MANIFEST = REPO / "bootstrap" / "group_vars" / "all.yml"
CLAUDE = REPO / "CLAUDE.md"

GEN = "generated from bootstrap/group_vars/all.yml by bootstrap/gen-symlink-table.py — do not edit by hand"


def home_to_tilde(dest):
    return re.sub(r"\{\{\s*target_home\s*\}\}", "~", dest)


def fill_block(text, name, header, items):
    begin = f"<!-- BEGIN {name} ({GEN}) -->"
    end = f"<!-- END {name} -->"
    rows = [header, "|---|---|"]
    rows += [f"| `{i['src']}` | `{home_to_tilde(i['dest'])}` |" for i in items]
    block = begin + "\n" + "\n".join(rows) + "\n" + end
    pattern = re.compile(re.escape(begin) + r".*?" + re.escape(end), re.DOTALL)
    if not pattern.search(text):
        raise SystemExit(f"{name} BEGIN/END markers not found in CLAUDE.md")
    return pattern.sub(lambda _: block, text)


manifest = yaml.safe_load(MANIFEST.read_text())
links = manifest["dotfile_links"]
templated = manifest.get("templated_configs", [])

text = CLAUDE.read_text()
text = fill_block(text, "active-symlinks", "| Repo file | Symlinked to |", links)
text = fill_block(text, "rendered-templates", "| Repo template | Rendered to |", templated)
CLAUDE.write_text(text)
print(f"CLAUDE.md regenerated: {len(links)} symlinks, {len(templated)} templated.")
