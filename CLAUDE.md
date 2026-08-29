# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A curated collection of system prompts, IDE rules, and templates for LLM-based tools. **This is a documentation-only repo** — no build system, no tests, no application code. All content is markdown files. The primary language of the content is **Spanish**.

There used to be a `claude/` directory here (Claude Code agent definitions, memory rules, backup scripts) — it has been removed. Don't recreate it or reference it unless the user asks; `README.md` still describes it and is stale on that point.

## Repository Structure

- `System Prompt/` — System prompts organized by domain:
  - `Base/` — Reasoning frameworks (ReAct, Tree of Thoughts, Chain of Thought), plus an `Experimentos/` subfolder for drafts
  - `SysP principales/` — Core prompts (executive, programming, reasoning)
  - `Trading/` — Crypto analysis system with layered prompts (`trading_pod_unified.md` is the current main one; `screening_pod_v1.2.md` and `Agente/` are related screening prompts; `Antiguos/` holds superseded/legacy versions)
  - `Creacion de app/` — App creation guidelines
  - `Varios/` — Miscellaneous (culinary, commercial proposals, an "IMPACTO" framework)
- `windsurf/` — Windsurf/Cascade IDE config:
  - `rules/` — Project rules (LangGraph, LangChain, Expo, migrations, global rules)
  - `workflows/` — Reusable workflows (plan, task implementation, finish-chat, contextual-new-chat)
- `Obsidian/Templates/` — Note templates (daily, weekly, monthly)

## Conventions

- Prompts use versioned headers (e.g., "v1.2", "v3.0 COMPACT")
- Legacy/superseded prompts go in `Antiguos/` subdirectories
- Trading prompts follow a layered POD system (data collection workflow with phases)
- Per `README.md`, each prompt should include: title/version, purpose description, implementation instructions, and usage examples where applicable

## Intended Usage (per README.md)

- **Claude Projects**: copy a prompt's `.md` content into a project's custom instructions
- **Windsurf/Cascade**: copy `rules/` files into `.windsurf/rules/` (or Global Rules), and `workflows/` files into `.windsurf/workflows/` to invoke with `/command`
- **Obsidian**: copy templates into the vault's template folder and configure under Settings > Templates
