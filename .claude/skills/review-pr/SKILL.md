---
name: review-pr
description: Review a PR on scality/workflows (reusable GitHub Actions workflows for the Scality org)
argument-hint: <pr-number-or-url>
disable-model-invocation: true
allowed-tools: Bash(gh repo view *), Bash(gh pr view *), Bash(gh pr diff *), Bash(gh pr comment *), Bash(gh api *), Bash(git diff *), Bash(git log *), Bash(git show *)
---

# Review GitHub PR

You are an expert code reviewer. Review this PR:

## Determine PR target

Parse `` to extract the repo and PR number:

- If arguments contain `REPO:` and `PR_NUMBER:` (CI mode), use those values directly.
- If the argument is a GitHub URL (starts with `https://github.com/`), extract `owner/repo` and the PR number from it.
- If the argument is just a number, use the current repo from `gh repo view --json nameWithOwner -q .nameWithOwner`.

## Output mode

- **CI mode** (arguments contain `REPO:` and `PR_NUMBER:`): post inline comments and summary to GitHub.
- **Local mode** (all other cases): output the review as text directly. Do NOT post anything to GitHub.

## Repo context

This is the **Scality reusable GitHub Actions workflows repository**. It provides standardized CI/CD workflow templates consumed by downstream Scality repos. It contains:

- Reusable workflow definitions (`.github/workflows/*.yaml`) — Docker builds, Trivy scanning, LFS warnings, Claude code review
- MkDocs Material documentation (`docs/`, `mkdocs.yml`)
- Test fixtures (`tests/docker/`) — Dockerfiles used to validate workflows
- Dependabot configuration for automated dependency updates
- Python dependencies only for docs tooling (`requirements.txt`)

PRs typically involve: workflow YAML changes, action version bumps (Dependabot), documentation updates, and test Dockerfile modifications.

## Steps

1. **Fetch PR details:**

```bash
gh pr view <number> --repo <owner/repo> --json title,body,headRefOid,author,files
gh pr diff <number> --repo <owner/repo>
```

2. **Read changed files** to understand the full context around each change (not just the diff hunks).

3. **Analyze the changes** against these criteria:

| Area | What to check |
|------|---------------|
| Workflow syntax | Valid GitHub Actions YAML — correct `on` triggers, proper `uses` references, required `inputs`/`secrets` declarations, job dependency chains |
| Action version pinning | Actions should pin to a specific major version tag (e.g., `@v6`), not `@main` or a full SHA without comment |
| Secret exposure | No credentials, tokens, or keys in plain text; secrets passed only via `secrets:` blocks |
| Permissions | Jobs use least-privilege `permissions:` — no unnecessary `write` scopes |
| Breaking changes | Changes to workflow `inputs`, `secrets`, or `outputs` that would break downstream callers |
| Backward compatibility | Renamed/removed inputs must have a migration path for consuming repos |
| Docker best practices | Multi-stage builds, minimal base images, no unnecessary `RUN` layers, proper use of build cache |
| Trivy/security scanning | Correct SARIF output, proper severity thresholds, rate-limiting mitigations |
| Documentation sync | Workflow changes reflected in corresponding `docs/*.md` files |
| MkDocs config | Valid `mkdocs.yml` navigation, no broken internal links |
| Test coverage | New workflow features have corresponding test scenarios in `tests/` |
| Security | OWASP-relevant issues — command injection in `run:` steps, untrusted input in expressions |

4. **Deliver your review:**

### If CI mode: post to GitHub

#### Part A: Inline file comments

For each specific issue, post a comment on the exact file and line:

```bash
gh api -X POST -H "Accept: application/vnd.github+json" "repos/<owner/repo>/pulls/<number>/comments" -f body="Your comment<br><br>— Claude Code" -f path="path/to/file" -F line=<line_number> -f side="RIGHT" -f commit_id="<headRefOid>"
```

**Never use newlines in bash commands** — use `<br>` for line breaks in comment bodies. The command must stay on a single line.

Each inline comment must:
- Be short and direct — say what's wrong, why it's wrong, and how to fix it in 1-3 sentences
- No filler, no complex words, no long explanations
- When the fix is a concrete line change (not architectural), include a GitHub suggestion block so the author can apply it in one click:
  ````
  ```suggestion
  corrected-line-here
  ```
  ````
  Only suggest when you can show the exact replacement. For architectural or design issues, just describe the problem.
- Never put `<br>` inside code blocks or suggestion blocks — `<br>` renders as literal text in code. Use `<br>` only in regular comment text.
- End with: `— Claude Code`

Use the line number from the **new version** of the file (the line number you'd see after the PR is merged), which corresponds to the `line` parameter in the GitHub API.

#### Part B: Summary comment

```bash
gh pr comment <number> --repo <owner/repo> --body "LGTM<br><br>Review by Claude Code"
```

**Never use newlines in bash commands** — use `<br>` for line breaks in comment bodies. The command must stay on a single line.

Do not describe or summarize the PR. For each issue, state the problem on one line, then list one or more suggestions below it:

```
- <issue>
  - <suggestion>
  - <suggestion>
```

If no issues: just say "LGTM". End with: `Review by Claude Code`

### If local mode: output the review as text

Do NOT post anything to GitHub. Instead, output the review directly as text.

For each issue found, output:

```
**<file_path>:<line_number>** — <what's wrong and how to fix it>
```

When the fix is a concrete line change, include a fenced code block showing the suggested replacement.

At the end, output a summary section listing all issues. If no issues: just say "LGTM".

End with: `Review by Claude Code`

## What NOT to do

- Do not comment on markdown formatting preferences
- Do not suggest refactors unrelated to the PR's purpose
- Do not praise code — only flag problems or stay silent
- If no issues are found, post only a summary saying "LGTM"
- Do not flag style issues already covered by the project's linter (eslint, biome, pylint, golangci-lint)
