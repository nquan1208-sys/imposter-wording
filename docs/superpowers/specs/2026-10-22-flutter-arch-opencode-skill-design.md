# OpenCode `flutter-arch` Skill Design

## Goal

Provide an OpenCode-native counterpart to the existing Codex `flutter-arch` skill while preserving its project guidance and opt-in behavior.

## Current state

- Source: `.codex/skills/flutter-arch/SKILL.md`.
- The source skill is explicitly opt-in. `.codex/skills/flutter-arch/agents/openai.yaml` contains Codex-specific UI and invocation metadata.
- The repository has no existing `.opencode/` skill directory.

## Design

Add `.opencode/skills/flutter-arch/SKILL.md`. Keep the existing architecture guidance intact, translate only the invocation wording and frontmatter needed by OpenCode, and set `metadata.opencode/autoinvoke: false` so OpenCode does not implicitly advertise the skill. The user can load it explicitly by its `flutter-arch` ID.

Do not modify the Codex source, create OpenCode configuration, or add sync tooling. The Codex `agents/openai.yaml` is not copied; its display name and opt-in intent are represented with OpenCode-supported skill metadata instead.

## Verification

Check that the OpenCode skill is at the documented discovery path, has the `flutter-arch` path-derived ID, includes a description and explicit-load opt-in metadata, and retains the source skill's project rules. Use the official [OpenCode V2 Skills documentation](https://opencode.ai/v2/docs/skills/) as the format reference.

## Out of scope

Additional skills, shared cross-tool skill storage, automatic synchronization, and changes to application code.
