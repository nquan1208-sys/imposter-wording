# Phase 7 HTTP simulation

Created 2026-10-27 from the app's existing content query/fixture contract and
Supabase Storage signing contract; handlers live in `../mocks/phase-7-supabase`.

## Purpose

Run the real Dart Supabase client and image downloader over local HTTP through
pagination, a failed middle page, JSON/HTML failures, malformed payloads, timeout,
expired signed downloads and image server errors. No mock replaces the app itself.

## Execution

From the repository root:

```sh
postman simulation run postman/simulations/phase-7.sim.yaml --port 4937 --output ndjson --no-history
```

From `app/`, copy `env/.env.test.example` to the ignored `env/.env.test`, set
`SUPABASE_SIMULATION_URL` to the simulation member's address, then run:

```sh
flutter test test/data/backend_http_test.dart
```

A process `SUPABASE_SIMULATION_URL` overrides the env file. Inspect `request`
events in the simulation's NDJSON output; stop its terminal with Ctrl-C.

## Assumptions

- Owner mock search was unavailable because this CLI is signed out. This local
  fixture was built from repository queries/fixtures and documented signing
  responses; it does not reproduce RLS, auth, CDN or real Storage policy behavior.
  (observed/reasoned 2026-10-27)
- `interceptRequests: true` supplies the signing JSON as `req.body`; the raw stream
  has already been consumed. Reading it again breaks signing. (observed 2026-10-27)
- Timeout verification shortens the repository deadline to 50ms against a 300ms
  response, then waits for the late response and checks no snapshot/cache change.
  The production deadline remains 15 seconds. (observed 2026-10-27)

## Observations

<!-- begin:observations -->
2026-10-27: All eight HTTP cases passed. The only member, `supabase`, served every
mode; none stayed silent. Logs confirmed REST offsets, five-minute signing POSTs,
expired-token GETs followed by successful renewed GETs, and isolated Storage 500s.
<!-- end:observations -->
