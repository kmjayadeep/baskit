## Goal
Extract the existing reviewer-verdict parser/validator from `automation/autonomous-agent/src/workflow.ts` into a focused named module, preserve behavior exactly, and add direct unit coverage without changing workflow safety or review independence.

## Non-goals
- No changes to Flutter/app code, generated files, unrelated dependencies, budgets, state transitions, publication behavior, or reviewer independence.
- No redesign of verdict semantics, error wording, schemas, or workflow gates.
- No documentation update unless the refactor exposes a genuinely necessary public/internal usage clarification.

## Traceability
- Existing implementation and all three review gates: `automation/autonomous-agent/src/workflow.ts`.
- Verdict-related types: `automation/autonomous-agent/src/types.ts`; reuse existing types where applicable rather than introducing incompatible representations.
- New focused tests: add a dedicated module under `automation/autonomous-agent/test/` (for example `reviewer-verdict.test.ts`), following the existing Vitest conventions in `test/validation.test.ts`.
- Validation commands/scripts: `automation/autonomous-agent/package.json`, with compiler/lint settings from `tsconfig.json` and `eslint.config.js`.

## Implementation steps
1. Inspect the current local `verdict(value: unknown): Verdict` implementation in `workflow.ts` only as needed while editing, recording its exact checks and deterministic error messages. Treat the current behavior as the compatibility contract.
2. Create a clearly named module, preferably `automation/autonomous-agent/src/reviewer-verdict.ts`, exporting the validator (and only the necessary verdict type/helper surface). Move the implementation unchanged: require a non-null object, enforce `schemaVersion === 1`, accepted verdict values, string summary, findings array, each finding’s `severity` and `message`, and reject `approved` results containing any `blocking` finding. Preserve check order and error strings.
3. Remove the local duplicate from `workflow.ts`, import the new module, and update all three plan, code, and governance review call sites to use it. Confirm no review path bypasses validation and no state/safety/publication logic is altered.
4. Add direct unit tests for the extracted module covering: valid `approved` with no blocking findings; valid `request_changes` with blocking and/or non-blocking findings; null and non-object inputs; invalid/missing `schemaVersion`, verdict, summary, or findings; null/malformed findings; invalid/missing severity and message; and `approved` with a blocking finding. Assert both acceptance/result shape and deterministic rejection diagnostics where the existing implementation exposes errors.
5. Keep tests narrowly focused on parsing/validation. Avoid weakening or duplicating workflow integration behavior; retain existing workflow tests unchanged unless a compile/import adjustment is required.
6. Run formatting as appropriate for the project, then run the required checks from `automation/autonomous-agent/package.json`: TypeScript type-check, unit tests, lint, and build. Also run the repository-required validation applicable to this package and inspect the diff to ensure production changes are confined to `automation/autonomous-agent`.
7. Update `automation/autonomous-agent/README.md` only if it documents the old file location or the validator as an externally relevant API; otherwise explicitly leave documentation unchanged because this is an internal extraction.

## Validation
- Type-check passes.
- All Vitest tests, including the new focused suite and existing validation tests, pass.
- ESLint passes with no new suppressions.
- Build passes.
- Review the final diff for unchanged error text/check ordering, all three imports/call sites, no changed workflow transitions/safety checks/budgets/publication behavior, and no Flutter or unrelated dependency edits.

## Risks and safeguards
- Predicate or message drift could change accepted/rejected behavior: copy the implementation verbatim before refactoring and test every branch.
- A missed gate could bypass validation: search `workflow.ts` for all three review usages and verify each invokes the imported validator.
- Type/export drift could affect callers: preserve the existing `Verdict` shape and use the project’s current TypeScript configuration.
- Contradictory approved/blocking output must remain rejected; include an explicit regression test.

## Documentation impact
No documentation change is expected for this internal module extraction. Revisit `automation/autonomous-agent/README.md` only if its implementation-location guidance becomes inaccurate.

## Rollback
Revert the focused module, its import/call-site changes, and the new tests as one change set. If compatibility failures appear, restore the original local validator in `workflow.ts` unchanged before investigating further; do not roll back by weakening validation or altering workflow safety behavior.