# PhoenixLite

PhoenixLite is an Igniter installer that codemods a freshly-generated Phoenix
project so it can boot under `MIX_ENV=prod` with **zero** manual edits to
`runtime.exs`. Targeted use cases: internal apps without SSL, Phoenix-as-SSG,
and quick-deploy prototypes.

## Installation

Run the installer against a fresh Phoenix project in a single command:

```
mix igniter.new myapp --with phx.new --with-args="--no-ecto --no-email" --install phoenix_lite
```

Or, against an existing Phoenix project:

```
mix igniter.install phoenix_lite
```

Current version: `0.0.1`.

## What the installer does

It replaces `config/runtime.exs` with a templated version that:

- Disables SSL (no `https:` block).
- Binds the HTTP endpoint to `0.0.0.0` on the port from `PORT` (default `4000`).
- Bakes in an auto-generated `secret_key_base` so no environment variable is needed.
- Sets `server: true` so `mix phx.server` boots the endpoint under `MIX_ENV=prod`.

The original `config/runtime.exs` is preserved at `config/.runtime.exs.bak`.

## Switches

- `--force` — overwrite an already-installed `config/runtime.exs`.
- `--no-backup` — skip writing `config/.runtime.exs.bak`.

## Idempotency

The templated `runtime.exs` carries a sentinel comment. Re-running the installer
detects the sentinel and refuses to overwrite without `--force`, so an existing
backup of the user's real original is never clobbered.

## Trade-offs

The generated `secret_key_base` is committed to source as a literal string in
`runtime.exs`. That's acceptable for the targeted use cases (internal apps,
SSGs, prototypes) but **not** for production deployments handling sensitive
data — for those, set `secret_key_base` from an environment variable instead.
