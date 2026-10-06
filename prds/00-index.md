# Product and architecture docs

Read only the documents relevant to the change. `README.md` covers setup and the product; `AGENTS.md` covers agent workflow; `TODO.md` tracks active work. Existing code and tests take precedence over old requirements; update docs when behavior changes.

- [Overview](01-overview.md), [authentication](02-authentication.md), [storage and sync](03-storage-and-sync.md), [Firestore model](04-firestore-data-model.md)
- [State management](05-state-management.md), [UI and assets](06-ui-and-assets.md)
- [Play production readiness](08-play-production-readiness.md) — outstanding release tasks; operational steps and smoke checklist live in `docs/`.
- [Alexa integration](09-alexa-integration-overview.md) and [account linking](10-alexa-account-linking-app.md) — integration context; confirm implementation against code.

Track active work in `TODO.md`; avoid adding new PRDs for completed features when a concise update to an existing document will do.
