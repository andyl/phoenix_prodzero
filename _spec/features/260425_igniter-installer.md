# Feature Specification: Igniter Installer

## Overview

Provide an Igniter installer for the `phoenix_prodzero` package that, when run
against a freshly generated Phoenix project, applies all the codemods needed
for the project to boot in `MIX_ENV=prod` without any further manual editing.

The installer is the core deliverable of the package. After running it, a
developer should be able to clone or generate a Phoenix app, fetch deps, and
start it directly in production mode — with no hand-edits to `runtime.exs`,
`prod.exs`, or any other config file.

## Goals

- Eliminate 100% of the manual editing that is normally required to make a new Phoenix app boot in prod.
- Make it possible to go from `mix phx.new` to `MIX_ENV=prod mix phx.server` with **zero** intermediate file edits by the developer.
- Compose cleanly with the standard Igniter workflow so the installer can be invoked as part of `mix igniter.new ... --install phoenix_prodzero`.
- Preserve a recoverable copy of any file the installer overwrites, so the developer can audit or revert changes.

### Success criteria

- A developer can run the documented one-liner and end up with a runnable prod-mode Phoenix app on the first try.
- Re-running the installer on an already-installed project is a no-op (idempotent) or produces a clear, recoverable result.
- The set of pre-configured options matches the target use cases: internal apps without SSL, Phoenix-as-SSG, and quick-deploy prototypes.

## Functional Requirements

- The package exposes an Igniter installer task discoverable as the `--install phoenix_prodzero` target.
- The installer rewrites (or otherwise transforms) `config/runtime.exs` in the host project so that, at minimum:
  - SSL is disabled.
  - The HTTP endpoint binds to host `0.0.0.0`.
  - An auto-generated secret key base is provided without requiring the developer to set an environment variable.
  - Any other manual edits normally required for prod boot are also handled.
- Before overwriting `config/runtime.exs`, the installer preserves a backup copy of the original file in a predictable location within the host project.
- The installer is invocable via the documented end-to-end flow:
  ```
  mix igniter.new myapp --with phx.new --with-args="--no-ecto --no-email" --install phoenix_prodzero
  ```
- The installer surfaces a clear summary of every change it made (files touched, files backed up).

## Non-Functional Requirements

- **Idempotency:** running the installer twice must not corrupt the project; the second run either does nothing or produces a deterministic, recoverable result.
- **Safety:** no destructive change is made without producing a backup of the prior state.
- **Discoverability:** all pre-configured prod options applied by the installer are documented so a developer can understand what changed and why.
- **Compatibility:** targets the Phoenix project shape produced by current `mix phx.new`, with and without `--no-ecto` / `--no-email`.

## Design / UX Notes

The installer is a developer-facing CLI tool, not a runtime feature. The "UX"
is the developer's experience of running one command and getting a working prod
app.

- Output should clearly enumerate what was changed and where the backup was placed.
- The pre-configured `runtime.exs` should read like a hand-written file a developer would be comfortable shipping — not a generated stub.
- The audience is developers running internal apps, static-site generators built on Phoenix, and quick prototypes; they value speed and zero-config over fine-grained tunability.

## Technical Approach

- **Architecture:** the package's core is an Igniter installer module that registers itself as the entry point for `--install phoenix_prodzero`.
- **Codemod strategy:** the design currently leaves open whether the installer should (a) replace `config/runtime.exs` wholesale with a templated file, or (b) edit the existing file in place via Igniter / Sourceror. The implementation should pick one strategy and document the trade-off; the spec does not prescribe which.
- **Backup mechanism:** when `runtime.exs` is fully replaced, the original is preserved in a backup location in the host project so the change is auditable and reversible.
- **Components affected:** primarily `config/runtime.exs` of the host project. The need to also modify `config/prod.exs` or other files is an open question (see below).
- **Dependencies:** Igniter (already in the project's `:dev`/`:test` deps) is the codemod engine.

## Possible Edge Cases

- The host project's `runtime.exs` has already been hand-edited by the developer and contains changes the installer would clobber.
- The installer is run a second time on a project that already has the templated `runtime.exs`.
- The host project was generated with flag combinations the installer hasn't accounted for (e.g. with `--no-ecto` vs. with Ecto, with or without `--no-email`).
- The host project is not actually a Phoenix project (installer should fail clearly rather than corrupt files).
- A backup file already exists from a prior installer run.
- The Phoenix version produced by `mix phx.new` differs from what the installer's templated `runtime.exs` was written against.

## Acceptance Criteria

- Running `mix igniter.new myapp --with phx.new --with-args="--no-ecto --no-email" --install phoenix_prodzero` produces a project where `MIX_ENV=prod mix phx.server` succeeds with no further file edits.
- The installer leaves a backup of any file it replaces in a predictable location.
- Running the installer twice on the same project does not corrupt it.
- The installer prints a summary of files modified and files backed up.
- The pre-configured prod options (SSL disabled, host `0.0.0.0`, hard-coded secret key, etc.) are visible and documented in the resulting `runtime.exs`.

## Open Questions

These come directly from the design doc and need to be resolved during planning, not in the spec itself:

- Should the installer use a templated replacement of `runtime.exs`, or perform in-place edits via Igniter / Sourceror?
- What additional simplifications are needed to fully eliminate the need for any `:prod` config (e.g. `server: true`)?
- Does `config/prod.exs` (or any other config file beyond `runtime.exs`) also need to be modified?
- Should the package provide a Mix task that performs the asset preparation (digests, etc.) normally required for prod — e.g. `mix phx.lite.serve`?
- Are Elixir releases in scope for this package, or strictly out of scope?
- What additional manual edits, beyond the ones enumerated above, exist today that the installer should also handle?

## Out of Scope

- SSL / HTTPS configuration. The package is explicitly aimed at use cases that don't need SSL.
- Anything required for Phoenix apps that need a database — the targeted flow uses `--no-ecto`.
- Email / mailer configuration — the targeted flow uses `--no-email`.
- Hardening for public-internet, multi-tenant, or production-grade deployments. The audience is internal apps, SSGs, and prototypes.
- Elixir releases (pending resolution of the open question above).

## Testing Guidelines

Create meaningful tests for the following use cases, without going too heavy:

- The installer, when run against a fresh `phx.new --no-ecto --no-email` fixture, leaves the project in a state where `MIX_ENV=prod mix phx.server` would boot (assert on the resulting config rather than actually booting a server in test).
- The installer creates a backup of `config/runtime.exs` before overwriting it.
- Running the installer a second time on a project it has already modified does not corrupt the project.
- The installer fails clearly when run against a directory that is not a Phoenix project.
