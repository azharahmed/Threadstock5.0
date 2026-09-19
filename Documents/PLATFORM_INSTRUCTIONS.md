# AI Coding Platform Instructions

The pack includes repository-native instruction files for Cursor, Google Antigravity and VS Code/GitHub Copilot, plus `AGENTS.md` as a cross-agent source.

## Cursor

Project rules live in `.cursor/rules/*.mdc`.

Included:

- `.cursor/rules/00-threadstock-core.mdc`
- `.cursor/rules/10-flutter-ui.mdc`
- `.cursor/rules/20-supabase-data.mdc`
- `.cursor/rules/30-quality.mdc`

Keep rules version-controlled. `AGENTS.md` is also included as a plain-Markdown agent instruction source.

## Google Antigravity

Workspace rules live under `.agents/rules/`.

Included:

- `.agents/rules/threadstock-core.md`
- `.agents/rules/threadstock-ui.md`
- `.agents/rules/threadstock-data.md`

If you maintain personal global Antigravity rules, keep them generic; project behavior belongs in the workspace repository.

## VS Code / GitHub Copilot

Repository-wide instructions:

- `.github/copilot-instructions.md`

Path-specific instructions:

- `.github/instructions/flutter.instructions.md`
- `.github/instructions/supabase.instructions.md`
- `.github/instructions/testing.instructions.md`

`AGENTS.md` provides compatible project-level context for agent workflows that support it.

## Rule precedence philosophy

Keep the most important invariant in `AGENTS.md` and platform core rules; keep path-specific implementation guidance close to the relevant file glob. Do not duplicate large architecture documents into every rule file; link agents to the canonical docs.

## First prompt for a coding agent

Use:

> Read AGENTS.md, ARCHITECTURE.md, PRODUCT_BLUEPRINT.md, ROUTE_MANIFEST.md, DESIGN_SYSTEM.md and SECURITY.md. Then summarize the constraints relevant to the task before changing code. Do not implement placeholders. Build the smallest production-ready vertical slice with tests.
