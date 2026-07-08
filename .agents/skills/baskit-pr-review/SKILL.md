---
name: baskit-pr-review
description: Use when reviewing an open GitHub pull request for the Baskit Flutter app: fetch the PR, assess problem/value, solution fit, regressions, tests, and report concise actionable findings.
---

# Baskit PR Review

Use this skill when reviewing a Baskit PR. Be skeptical, practical, and concise.

## Ground Rules

- Do not modify PR code unless the user explicitly asks.
- Protect local work: if `git status` shows unrelated changes, do not overwrite them.
- Prefer concrete findings with file/line references.
- Distinguish blockers from non-blocking suggestions.
- Validate with focused commands when practical; state clearly what was not run.

## Review Flow

1. Inspect repo state:

```bash
git status --short --branch
git remote -v
git branch --show-current
```

2. Fetch and check out PR `<N>`:

```bash
git fetch origin main --force
git fetch origin pull/<N>/head:pr-<N> --force
git checkout pr-<N>
```

3. Get PR metadata when useful:

```bash
gh pr view <N> --json title,body,headRefName,baseRefName,files,commits,url --repo kmjayadeep/baskit
```

4. Inspect the change:

```bash
git log --oneline --decorate --max-count=8 origin/main..HEAD
git diff --stat origin/main...HEAD
git diff --find-renames --unified=80 origin/main...HEAD
```

Read affected files with `read`; use `rg` for related code.

## Checklist

### Problem, Value, Solution Fit

- What actual problem does the PR solve? Is it real, documented, reproducible, or user/developer valuable?
- Is the change useful enough to merge, or is it churn/speculative abstraction/cosmetic rewriting?
- Does it fix the root cause rather than masking symptoms?
- Is this the simplest/most idiomatic/proportional solution? Call out better alternatives when likely.

### Correctness and Regressions

- Are guest/local and authenticated/cloud paths both handled?
- Are migration and sync flows preserved?
- Are async operations, streams, and subscriptions lifecycle-safe?
- Are errors handled as typed state/results or user-friendly messages?

### Baskit-Specific Areas

- Riverpod: prefer `Notifier`/`NotifierProvider`; use `ref.watch` for dependencies and `ref.listen` only for side effects.
- Firebase/Firestore: ensure current-user checks happen at the right time; avoid unnecessary expensive calls in hot paths.
- Storage/repositories: preserve guest-first local storage and cloud routing boundaries.
- UI: handle loading, empty, and error states without flicker or repeated SnackBars.
- Tests: require focused coverage for changed behavior; suggest guest/auth, permissions, streams, migration, and error-path tests where relevant.
- Generated files: do not hand-edit `app/lib/**.g.dart`.

## Validation

Run focused tests plus analyzer when practical:

```bash
cd app
flutter test <relevant-test-file>
flutter analyze
```

For broad/risky changes, prefer:

```bash
cd app
flutter test
flutter analyze
```

If validation is skipped or incomplete, say exactly why.

## Optional Subagent

For non-trivial PRs, ask a read-only `reviewer` subagent for prioritized findings, then verify and synthesize the final review yourself.

## Report Format

```text
Reviewed PR #<N>: <title>

Problem/value assessment:
- Actual problem/usefulness: <real problem and merge value>
- Solution fit: <root cause, proportionality, better alternatives if any>

Findings:
- [Blocker/Major/Minor] <file>:<line> — <issue and impact>
  Suggested fix: <specific recommendation>

Validation:
- `<command>` ✅/❌

Verdict:
- Approve / Request changes / Comment only
- Residual risks: <not covered or remaining concerns>
```

If there are no findings, say so clearly.

## If Asked to Update the PR

Make minimal targeted changes on the PR branch, format changed Dart files, run focused validation plus analyzer, commit with a conventional signed message, and push to the PR head branch. Never force push.

## Safety

- Never force push.
- Never skip tests or hooks without saying so.
- Never commit secrets, `.env`, credentials, build outputs, or unintended generated files.
- Do not merge a PR unless the user explicitly asks.
