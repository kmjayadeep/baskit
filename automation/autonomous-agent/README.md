# Baskit autonomous development agent

A local, bounded Pi SDK runner that plans, implements, validates, independently reviews, and prepares changes for the Baskit repository. It pauses before commit, push, or pull-request creation. It never merges or pushes directly to `main`.

## Prerequisites

- Node.js 22.19 or newer
- Flutter 3.41.6 (the version pinned by `.tool-versions` and CI)
- `git`, `gh`, and existing Pi `openai-codex` authentication

```bash
cd automation/autonomous-agent
npm ci
npm run check
npm run build
node dist/cli.js smoke
```

Pi SDK `0.84.4` is pinned. `smoke` checks configured model availability without opening sessions or modifying the repository. Configure roles and limits in `config.yaml`; the implementer and code reviewer must use different model IDs. Credentials belong in Pi's normal user authentication store and must never be added to this repository.

## Use

Start from a clean local `main` checkout. Run from the repository root, and prefer a requirements file or editor so requirements do not enter shell history:

```bash
node automation/autonomous-agent/dist/cli.js start --requirements-file /private/path/requirement.md
node automation/autonomous-agent/dist/cli.js start --editor
node automation/autonomous-agent/dist/cli.js status <run-id>
node automation/autonomous-agent/dist/cli.js inspect <run-id>
node automation/autonomous-agent/dist/cli.js inspect <run-id> --artifact final-summary.md
node automation/autonomous-agent/dist/cli.js resume <run-id> --decision pending
node automation/autonomous-agent/dist/cli.js resume <run-id> --decision revise --feedback-file /private/path/feedback.md
node automation/autonomous-agent/dist/cli.js resume <run-id> --decision reject
node automation/autonomous-agent/dist/cli.js resume <run-id> --decision approve
```

`inspect --requirements` is the only normal command that prints requirements. Approval displays paths, commit title, and PR target and requires typing `yes`; `--yes` is available only with an explicit `--decision approve` invocation.

### Live interaction

Attached runs show timestamped stage, model, turn, bounded tool, token usage, heartbeat, validation, and completion events. Raw model responses, reasoning, tool output, and requirements are not streamed.

During exploration, planning, implementation, and documentation stages, enter a line to add operator feedback. Feedback is safety-scanned, recorded under the run's `human-input/` audit directory, and remains subject to validation and independent review. Reviewer sessions cannot be steered.

- `:status` — show elapsed time and completed turns.
- `:cancel` — stop the active model stage without remote mutation.
- `:help` — show available commands.

Use `--non-interactive` for scripts. Non-TTY execution disables input automatically while retaining progress output.

## Workflow and validation

Each run explores the repository, produces an independently reviewed plan, implements it in an isolated Git worktree, and enters iterative code and Baskit architecture review. Deterministic validation runs:

- `git diff --check`
- the autonomous agent's TypeScript type checks, tests, and lint
- `flutter pub get`, `flutter analyze`, and `flutter test` from `app/`

The safety scanner rejects credential-like content, private keys, environment dumps, Firebase configuration files, and signing material. Generated Hive adapters (`app/lib/**.g.dart`) must not be edited manually. The agent is instructed to preserve guest-first behavior, Riverpod conventions, Firebase/storage boundaries, and documentation alignment.

## State and safety

Model sessions are in memory. Read-only roles have confined read/list/search tools; writable roles additionally have confined edit/write tools in a generated worktree. Models have no shell, network, Git, Firebase, or credential-store tools. The orchestrator runs only fixed argument arrays—never shell interpolation—and treats missing checks as failure.

Local state is stored in `.agent-state/`; generated worktrees are siblings under `.agent-worktrees/`. Neither is removed automatically. After confirming a run is no longer needed, clean it up manually with standard `git worktree` and branch commands.

Failed records retain their last durable state. Human-gate and publication steps are idempotent where GitHub permits. A checksum mismatch, safety finding, unavailable model/tool, dirty checkout, repeated review rejection, malformed result, timeout, or limit exhaustion blocks progress.

## Maintenance checklist

1. Run `npm ci`, `npm run check`, `npm audit`, and `npm run build` in this directory.
2. Run `node dist/cli.js smoke`.
3. Confirm `flutter analyze` and `flutter test` pass from `app/`.
4. Exercise a documentation-only test run before relying on publication automation.
5. Confirm no raw sessions, credentials, Firebase configuration, signing material, or unbounded output entered Git.
