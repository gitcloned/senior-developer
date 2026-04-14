# Contributing

Thanks for your interest in improving the senior-developer skill.

## How the skill works

This is a **markdown-only** Claude Code skill. There's no runtime code — just structured instructions in `SKILL.md` that Claude follows. Changes to behavior mean changes to the markdown prompts.

### File structure

```
skills/senior-developer/
├── SKILL.md                  # Main skill instructions (the prompt)
└── github-status-helper.md   # GitHub Projects API reference commands
```

- `SKILL.md` — The core workflow. Claude reads this when the skill activates. Keep it under 600 lines.
- `github-status-helper.md` — Reference file loaded on demand. Contains `gh` CLI commands for reading/updating project fields.

## Making changes

### 1. Write an eval first

Before changing the skill, add or update an eval in `evals/` that captures the behavior you want. See [Writing evals](#writing-evals) below.

### 2. Make your change

Edit `SKILL.md` or `github-status-helper.md`. Key principles:

- **Be specific where it matters.** Fragile operations (posting comments, updating status) need exact commands. Flexible operations (writing code) need guidelines, not scripts.
- **Confirm before acting.** Every external side effect (post comment, push code, update field) must be confirmed with the user first.
- **Keep it concise.** Claude is intelligent — only add context it doesn't already have. Avoid restating obvious programming concepts.
- **Test gate is sacred.** The rule that tests must pass before committing is the skill's core quality guarantee. Don't weaken it.

### 3. Test with a real issue

The best test is using the skill on an actual GitHub issue. Create a test issue in your own repo and run through both flows:

1. **Analysis flow** — Does it explore the right code? Is the analysis structured and useful? Does it update project fields correctly?
2. **Development flow** — Does it create the task list? Follow TDD? Enforce the test gate? Create a clean PR?

### 4. Run evals

```bash
# From the repo root
claude evals run
```

Check that existing evals still pass and your new eval captures the intended behavior.

### 5. Submit a PR

- One logical change per PR
- Include the eval that validates your change
- Describe what behavior changed and why

## Writing evals

Evals live in `evals/` as JSON files. Each eval describes a scenario and expected behaviors.

### Eval structure

```json
{
  "name": "analysis-flow-basic",
  "description": "Skill correctly analyzes a Todo issue and posts structured analysis",
  "skills": ["senior-developer"],
  "query": "work on issue #42",
  "expected_behavior": [
    "Runs preflight checks (gh, jq, auth)",
    "Reads issue via gh issue view",
    "Detects Todo status from GitHub Projects",
    "Explores codebase with Explore subagent",
    "Presents analysis to user before posting",
    "Analysis has: What's the issue, Approaches, Recommended, Risks sections",
    "Posts analysis comment after user confirmation",
    "Updates Task Type, Size, Estimate fields",
    "Sets status to In Analysis",
    "Stops and waits — does NOT start development"
  ]
}
```

### What to eval

Cover these scenarios at minimum:

| Scenario | Key behaviors to check |
|----------|----------------------|
| Analysis flow (Todo issue) | Explores code, structured analysis, posts comment, updates fields, stops |
| Development flow (In Progress) | Task list created, TDD order, test gate enforced, PR created |
| Resume (In Review) | Informs user, asks what to do, doesn't restart work |
| Missing tools | Detects missing gh/jq, gives install instructions, stops |
| Issue not on board | Tells user, asks how to proceed |
| Existing analysis | Detects existing analysis comment, offers to proceed/revise/restart |

### Eval tips

- **Test one behavior per eval.** Don't combine "analysis flow" and "missing tools" in one eval.
- **Expected behaviors are assertions, not scripts.** Describe what should happen, not the exact words.
- **Test across models.** Run evals with `--model haiku`, `--model sonnet`, and `--model opus`. What works for Opus may need more detail for Haiku.

## Code of conduct

- Be constructive in reviews
- Test your changes on real issues before submitting
- Don't weaken safety rails (test gate, user confirmation) without strong justification
