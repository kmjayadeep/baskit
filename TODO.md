# Active work

This is the only active task list. Keep durable behavior in `prds/`, setup in `README.md`, and release procedures in `docs/`. Verify status against code before starting; remove completed tasks instead of keeping a second history.

## Have at Home

**Foundation done:** `ShoppingItem.listItemType` and `ItemType` (`needsPurchase`, `haveAtHome`, `runOut`) exist in `app/lib/models/shopping_item_model.dart`. Hive field 6 and Firestore mapping/persistence are already implemented. Missing types default to `needsPurchase`. Do not add a second migration or change field indices without checking the existing adapters and compatibility tests.

1. Add view-model actions to add, finish, and restore Have at Home items. Enforce write permissions; guard normal completion and clear-completed actions so they affect only `needsPurchase`. Test local and cloud repository paths.
2. Separate shopping and Have at Home in `ListDetailScreen`. Provide an add input, a Finished action, and a collapsible Run Out section with restore/delete actions. Reuse widgets where practical; cover empty, loading, and permission-limited states with tests.
3. Polish feedback and accessibility; verify guest, signed-in, and shared-list behavior. Update `prds/06-ui-and-assets.md` when implemented.

Acceptance: existing shopping and migration behavior remains intact; write-enabled users can add/finish/restore/delete, read-only users cannot; clear-completed never deletes Run Out items; `flutter analyze` and `flutter test` pass. Report device/Firebase verification separately.

## Follow-ups

- Manually verify leave-list and remove-member flows with multiple accounts and permissions.
- Align `README.md` and relevant `prds/` with current behavior (profile status, member dialog roles, storage errors).
- Expand service and permission-flow tests; standardize error handling where needed.
- Improve loading/empty/error states, accessibility, and responsive layout.
- Verify Play readiness against [the readiness checklist](prds/08-play-production-readiness.md) and [release smoke test](docs/play-release-smoke-test-checklist.md) when preparing a release.
