# Project instructions

## Shell commands

- Always prefix shell commands with `rtk`. Use `rtk proxy <command>` when raw output is needed.

## Planning and verification

- When creating or updating a plan, do not include screenshot capture or image-based UI verification by default.
- If image-based verification is genuinely necessary, explain why and ask the user before including it in the plan or performing it.
- Prefer code inspection, static analysis, and automated tests for routine verification.
