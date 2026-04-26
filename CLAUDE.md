# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project intent

PhoenixProdmin is an Elixir package that codemods a freshly-generated Phoenix project so it can boot in `MIX_ENV=prod` with zero manual edits. Target use cases: internal apps without SSL, Phoenix-as-SSG, quick-deploy prototypes.

The package is currently a skeleton (`lib/phoenix_prodmin.ex` is the default `mix new` stub). The actual implementation has not been written yet — the intended design lives in `_spec/designs/260425_Intro.md` and should be consulted before adding code.

The core machinery is meant to be an **Igniter installer**, invoked via:

```
mix igniter.new myapp --with phx.new --with-args="--no-ecto --no-email" --install phoenix_prodmin
```

…which will replace `config/runtime.exs` in the host project with a templated version (disable SSL, bind `0.0.0.0`, hard-code secret key, etc.). When implementing, prefer Igniter codemods over hand-rolled file manipulation, and keep open the question of templated-replacement vs. sourceror-style in-place editing (see "Questions" in the design doc).

## Common commands

- `mix deps.get` — fetch deps. Note `:commit_hook` is a **local path dep** at `~/src/Tool/commit_hook`; that directory must exist on the developer's machine or `deps.get` fails.
- `mix test` — run the test suite. Single test: `mix test test/phoenix_prodmin_test.exs:5` (line number).
- `mix format` — formatter is configured via `.formatter.exs`.
- `bin/release` — cuts a release: `mix git_ops.release --yes && git push --follow-tags`.

## Release flow

Releases are driven by [`git_ops`](https://hex.pm/packages/git_ops), configured in `config/config.exs`:

- `manage_mix_version?: true` and `manage_readme_version: true` — `mix git_ops.release` bumps `@version` in `mix.exs` **and** rewrites the version reference in `README.md`. Don't hand-edit either; let the task do it.
- `version_tag_prefix: "v"` — tags look like `v0.0.1`.
- Custom commit types: `tidbit` (hidden from changelog), `important` (rendered under "Important Changes").

Because git_ops derives the next version and changelog entries from commit subjects, **commits must follow Conventional Commits** (`feat:`, `fix:`, `chore:`, `tidbit:`, `important:`, etc.). A non-conforming subject will either be skipped from the changelog or break the version bump.

## Repo layout notes

- `_spec/{designs,features,plans}/` — design docs and planning artifacts. `_spec/designs/260425_Intro.md` is the source of truth for what this package is supposed to do.
- `.expert/` — local cache for an external "expert" tool; not part of the package.
- `bin/release` — the only release entry point; don't invoke `mix git_ops.release` directly without also pushing tags.
