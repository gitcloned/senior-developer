# Senior Developer — Claude Code Skill

## What this is

A standalone Claude Code skill that works on GitHub issues with a structured workflow: analysis, TDD implementation, and PR delivery. Published as a Claude plugin.

## Project structure

```
.claude-plugin/          # Plugin registration (plugin.json, marketplace.json)
skills/work-on-issue/     # The skill itself
  SKILL.md               # Main instructions — Claude reads this on activation
  github-status-helper.md # GitHub Projects API commands (reference, loaded on demand)
evals/                   # Evaluation test cases
```

## Key conventions

- **SKILL.md is the product.** All behavior changes happen here. Keep it under 600 lines.
- **Eval-driven development.** Write or update an eval before changing behavior.
- **Test gate is non-negotiable.** The skill must always enforce running tests before committing.
- **User confirmation required.** Every external action (post comment, push code, update fields) needs user approval.

## Working on the skill

1. Read `skills/work-on-issue/SKILL.md` to understand current behavior
2. Check `evals/` for existing test coverage
3. Make changes to SKILL.md
4. Test manually on a real GitHub issue
5. Run evals to verify nothing broke

## Don't

- Don't add runtime code (Python, JS, etc.) — this is a markdown-only skill
- Don't weaken the test gate or remove user confirmation steps
- Don't let SKILL.md grow past 600 lines — split into reference files instead
