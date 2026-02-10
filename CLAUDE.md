# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A curated collection of system prompts, AI agents, IDE rules, and templates. **This is a documentation-only repo** — no build system, no tests, no application code. All content is markdown files.

The primary language of the content is **Spanish**.

## Repository Structure

- `System Prompt/` — System prompts organized by domain:
  - `Base/` — Reasoning frameworks (ReAct, Tree of Thoughts, Chain of Thought)
  - `SysP principales/` — Core prompts (executive, programming, reasoning)
  - `Trading/` — Crypto analysis system with layered prompts (`trading_pod_unified.md` is the main one, `Antiguos/` has legacy versions)
  - `Creacion de app/` — App creation guidelines
  - `Varios/` — Miscellaneous (culinary, commercial proposals, etc.)
- `claude/` — Claude Code configuration and backup:
  - `agents/` — Specialized agent definitions (`.md` files that go in `.claude/agents/`)
  - `memory.md` — Shared memory rules for other projects (Pydantic v2, FastAPI patterns, responsive frontend)
  - `backup-claude-config.sh` / `.ps1` — Scripts to backup Claude Code settings
- `windsurf/` — Windsurf/Cascade IDE config:
  - `rules/` — Project rules (LangGraph, LangChain, Expo, migrations)
  - `workflows/` — Reusable workflows (plan, task implementation, finish-chat)
- `Obsidian/Templates/` — Note templates (daily, weekly, monthly)

## Conventions

- Prompts use versioned headers (e.g., "v1.2", "v3.0 COMPACT")
- Legacy/superseded prompts go in `Antiguos/` subdirectories
- Trading prompts follow a layered POD system (data collection workflow with phases)
- Agent files in `claude/agents/` follow the Claude Code agent format with role, capabilities, and instructions sections

## Claude Code Backup

Config files that matter for backup/restore live at `~/.claude/`:
- `settings.json` — enabled plugins
- `plugins/installed_plugins.json` — installed plugin registry
- `projects/` — per-project settings and memory

Marketplace plugins (`plugins/cache/`) re-download automatically and don't need backup.
