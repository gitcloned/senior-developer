# Setup Guide

Get the senior-developer skill working in ~5 minutes.

---

## 1. Install Claude Code

```bash
npm install -g @anthropic-ai/claude-code
claude login
```

Verify: `claude --version`

---

## 2. Install this plugin

```bash
# Add the marketplace (one-time)
claude plugin marketplace add ashishlead/senior-developer

# Install the plugin
claude plugin install senior-developer@lead-senior-developer --scope user
```

Verify: `claude plugin list` — "senior-developer" should appear.

Start a **new** Claude session after installing — plugins load at startup.

---

## 3. Install GitHub CLI

```bash
brew install gh          # macOS
# or: sudo apt install gh   # Ubuntu/Debian
```

Authenticate with required scopes:

```bash
gh auth login --scopes "read:org,repo,workflow,read:project,project"
```

Follow the browser prompt. The `read:project` and `project` scopes are required for reading and updating GitHub Projects fields.

Verify:
```bash
gh auth status
# Check that Token scopes includes: read:org, repo, workflow, read:project, project
```

---

## 4. Install jq

```bash
brew install jq          # macOS
# or: sudo apt install jq   # Ubuntu/Debian
```

Verify: `jq --version`

---

## 5. Set GITHUB_TOKEN (optional — for screenshot uploads)

Only needed if you work on UI issues and want screenshots uploaded to GitHub.

```bash
echo 'export GITHUB_TOKEN="your-github-token"' >> ~/.zshrc
source ~/.zshrc
```

Create a token at [github.com/settings/tokens](https://github.com/settings/tokens) with `repo` scope.

---

## 6. Set up a GitHub Projects board

Your repository's issues must be tracked on a [GitHub Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects) board.

### Required status values

Create these status options on your board's Status field:

| Status | Purpose |
|--------|---------|
| `Todo` | Not started |
| `In Analysis` | Analysis posted, awaiting development decision |
| `In Progress` | Implementation underway |
| `In Review` | PR created, awaiting review |
| `Done` | Merged / complete |

### Optional project fields

The skill can also update these fields if they exist on your board:

| Field | Type | Purpose |
|-------|------|---------|
| Task Type | Single select | Bug, Feature, Chore, etc. |
| Size | Single select | XS, S, M, L, XL |
| Estimate | Number | Story points or effort estimate |
| Iteration | Iteration | Sprint/iteration assignment |
| End date | Date | Target completion date |
| branch_link | Text | Feature branch name |

If a field doesn't exist, the skill skips it silently.

---

## 7. Verify

Start a new Claude session and run:

```
/senior-developer #1
```

Expected: the skill reads the issue, checks its status, and confirms context with you before taking any action.

---

## Troubleshooting

**"gh: command not found"**
- Install with `brew install gh` (macOS) or `sudo apt install gh` (Linux)

**"not logged in" or auth errors**
- Run `gh auth login --scopes "read:org,repo,workflow,read:project,project"`

**"read:project scope missing"**
- Re-run `gh auth login` with the scopes flag — it adds scopes on top of existing ones

**"jq: command not found"**
- Install with `brew install jq` (macOS) or `sudo apt install jq` (Linux)

**"Issue not found on project board"**
- Add the issue to your GitHub Projects board first
- The skill uses Projects status fields, not labels

**Plugin not showing up**
- Start a **new** Claude session — plugins load at startup
- Check `claude plugin list` to confirm installation
