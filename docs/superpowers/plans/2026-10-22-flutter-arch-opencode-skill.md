# OpenCode Flutter Architecture Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an OpenCode-native counterpart to the existing opt-in `flutter-arch` Codex skill.

**Architecture:** Create one skill at `.opencode/skills/flutter-arch/SKILL.md`. Preserve the existing guidance, translate the invocation wording to OpenCode, and disable implicit advertisement with `metadata.opencode/autoinvoke: false`.

**Tech Stack:** Markdown with YAML frontmatter; OpenCode V2 Skills.

**Spec:** `docs/superpowers/specs/2026-10-22-flutter-arch-opencode-skill-design.md`

## Global Constraints

- Add `.opencode/skills/flutter-arch/SKILL.md` with the path-derived ID `flutter-arch`.
- Do not modify the Codex source, create OpenCode configuration, or add sync tooling.
- Do not copy the Codex-specific `.codex/skills/flutter-arch/agents/openai.yaml`.
- Additional skills, shared cross-tool skill storage, automatic synchronization, and changes to application code are out of scope.

## Review Focus

- Wrong project skill path makes OpenCode miss the skill; verify the target path exists.
- Wrong directory name changes the path-derived ID; verify explicit loading uses `flutter-arch`.
- Missing opt-in metadata allows implicit advertisement; assert `opencode/autoinvoke: false` is present.
- Retained Codex invocation syntax is wrong for OpenCode; assert `@flutter-arch` replaces `$flutter-arch`.
- Omitted project guidance changes the skill's behavior; assert the body matches the Codex source apart from that invocation token.

---

### Task 1: Add the OpenCode `flutter-arch` skill

**Files:**
- Create: `.opencode/skills/flutter-arch/SKILL.md`
- Reference: `.codex/skills/flutter-arch/SKILL.md`

**Interfaces:**
- Consumes: Existing Codex skill guidance and OpenCode V2 skill frontmatter conventions.
- Produces: Explicitly loadable OpenCode skill ID `flutter-arch`.

- [ ] **Step 1: Create the native skill file**

Copy the source skill body unchanged, replacing `$flutter-arch` with `@flutter-arch`. Use OpenCode frontmatter with `name: Flutter Architecture`, a non-empty description that specifies explicit invocation as `@flutter-arch`, and:

```yaml
metadata:
  opencode/autoinvoke: false
```

- [ ] **Step 2: Run an assertion-based content and metadata check**

Run from the repository root:

```bash
python3 - <<'PY'
from pathlib import Path

source = Path(".codex/skills/flutter-arch/SKILL.md").read_text()
target = Path(".opencode/skills/flutter-arch/SKILL.md").read_text()
frontmatter, body = target.split("---", 2)[1:]
source_body = source.split("---", 2)[2].lstrip()

assert "name: Flutter Architecture" in frontmatter
assert "description:" in frontmatter
assert "opencode/autoinvoke: false" in frontmatter
assert "@flutter-arch" in frontmatter
assert body.lstrip() == source_body.replace("$flutter-arch", "@flutter-arch")
assert "$flutter-arch" not in target
assert all(line.rstrip() == line for line in target.splitlines())
PY
```

Expected: no assertion failures.

- [ ] **Step 3: Commit the skill**

```bash
git add .opencode/skills/flutter-arch/SKILL.md
git diff --cached --check
git commit -m "docs: add OpenCode Flutter architecture skill"
```
