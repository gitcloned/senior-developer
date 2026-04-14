# Senior Developer

A Claude Code skill that works on GitHub issues like a senior developer — structured analysis, TDD implementation, and clean PR delivery.

## What it does

Point it at a GitHub issue. It reads the issue's status from GitHub Projects and adapts:

| Issue status | What happens |
|-------------|--------------|
| **Todo / In Analysis** | Explores the codebase, drafts a structured analysis, posts it to the issue, updates project fields |
| **In Progress** | Creates a task list, writes failing tests first, implements, runs the full suite, commits, opens a PR |
| **In Review / Done** | Tells you the current state and asks what you want to do |

Every action is confirmed with you before it happens. Nothing gets posted or pushed without your approval.

## Install

```bash
# Add the marketplace (one-time)
claude plugin marketplace add gitcloned/senior-developer

# Install the plugin
claude plugin install senior-developer@lead-senior-developer --scope user
```

Then start a new Claude session.

> **Project-only install:** Use `--scope project` instead of `--scope user`.

## Usage

```
/senior-developer #123
/senior-developer https://github.com/owner/repo/issues/123
```

Or just mention an issue in conversation — the skill activates automatically when it sees a GitHub issue reference.

## Features

### Analysis phase
- Explores affected codebase areas using subagents
- Drafts structured analysis with approaches, tradeoffs, and recommendations
- Posts analysis as a comment on the issue
- Updates project fields: Task Type, Size, Estimate
- Sets status to "In Analysis" and stops — waits for you to say "develop"

### Development phase
- Creates a tracked task list with 12 steps
- Writes failing tests before implementation (TDD)
- Implements until tests pass
- **Hard test gate** — won't commit until the full test suite passes and output is shown
- Creates a PR with `Closes #N` to auto-close the issue
- Posts structured completion comment with PR link, changes summary, and test output
- Updates status through In Progress → In Review

### GitHub Projects integration
- Reads and updates Status, Task Type, Size, Estimate, Iteration, End date
- Uses GitHub Projects board fields (not labels) for workflow state
- Works with any project board that has these standard fields

## Requirements

| Tool | Install | Why |
|------|---------|-----|
| `gh` CLI | `brew install gh` | GitHub API access |
| `jq` | `brew install jq` | Parse project field IDs |
| `GITHUB_TOKEN` | [Create token](https://github.com/settings/tokens) | Screenshot uploads |

### GitHub CLI scopes

```bash
gh auth login --scopes "read:org,repo,workflow,read:project,project"
```

### GitHub Projects board

Your issues must be on a [GitHub Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects) board with these status values:

- Todo
- In Analysis
- In Progress
- In Review
- Done

See [SETUP.md](./SETUP.md) for detailed setup instructions.

## How it works

```
                    ┌─────────────┐
                    │  User says  │
                    │ "#123" or   │
                    │ issue URL   │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │  Preflight  │  gh, jq, auth
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │ Read issue  │  gh issue view
                    │ + status    │  + Projects API
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
       ┌──────▼──────┐ ┌──▼───┐ ┌──────▼──────┐
       │  Analysis   │ │ Dev  │ │   Inform    │
       │  flow       │ │ flow │ │   + ask     │
       └──────┬──────┘ └──┬───┘ └─────────────┘
              │            │
        Post analysis   Task list → TDD → Test gate
        Update fields   → Commit → PR → Completion
        STOP            → In Review
```

## Evals

See [evals/](./evals/) for evaluation test cases. Run them to verify the skill works correctly across different scenarios.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines on submitting changes, writing evals, and the review process.

## License

[Apache 2.0](./LICENSE)
