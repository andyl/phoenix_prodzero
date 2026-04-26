defmodule Mix.Tasks.PhoenixProdmin.Install.Docs do
  @moduledoc false

  def short_doc do
    "Installs phoenix_prodmin into a Phoenix project."
  end

  def example do
    "mix igniter.install phoenix_prodmin"
  end

  def long_doc do
    """
    #{short_doc()}

    Replaces `config/runtime.exs` in the host Phoenix project with a
    pre-configured templated version that lets the project boot under
    `MIX_ENV=prod` with no further manual edits — SSL disabled, host
    bound to `0.0.0.0`, an auto-generated `secret_key_base` baked in,
    and `server: true` so `mix phx.server` boots the endpoint.

    The original `config/runtime.exs` is preserved at
    `config/.runtime.exs.bak` unless `--no-backup` is passed.

    ## Example

    ```bash
    #{example()}
    ```

    ## Switches

    - `--force` — overwrite an already-installed `config/runtime.exs`.
    - `--no-backup` — skip writing `config/.runtime.exs.bak`.
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.PhoenixProdmin.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    @runtime_path "config/runtime.exs"
    @backup_path "config/.runtime.exs.bak"
    @template_path "priv/templates/runtime.exs.eex"

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :phoenix_prodmin,
        adds_deps: [],
        installs: [],
        example: __MODULE__.Docs.example(),
        only: [:dev],
        positional: [],
        composes: [],
        schema: [force: :boolean, backup: :boolean],
        defaults: [force: false, backup: true],
        aliases: [],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      opts = igniter.args.options
      force? = opts[:force]
      backup? = opts[:backup]

      with {:ok, info} <- PhoenixProdmin.HostProject.inspect(igniter),
           {:ok, igniter, original} <- read_runtime(igniter) do
        cond do
          already_installed?(original) and not force? ->
            Igniter.add_notice(igniter, """
            phoenix_prodmin is already installed (sentinel detected in #{@runtime_path}).
            Pass --force to overwrite.
            """)

          true ->
            install(igniter, original, info, backup?)
        end
      else
        {:error, reason} -> Igniter.add_issue(igniter, reason)
      end
    end

    defp install(igniter, original, info, backup?) do
      already_installed? = already_installed?(original)

      igniter =
        if backup? and not already_installed? do
          maybe_write_backup(igniter, original)
        else
          igniter
        end

      content = render_template(info)

      igniter
      |> Igniter.create_or_update_file(@runtime_path, content, fn source ->
        Rewrite.Source.update(source, :content, content)
      end)
      |> Igniter.add_notice(summary_notice(backup?, already_installed?))
    end

    defp read_runtime(igniter) do
      if Igniter.exists?(igniter, @runtime_path) do
        igniter = Igniter.include_existing_file(igniter, @runtime_path)

        content =
          igniter.rewrite |> Rewrite.source!(@runtime_path) |> Rewrite.Source.get(:content)

        {:ok, igniter, content}
      else
        {:error,
         "phoenix_prodmin expected #{@runtime_path} to exist. Modern `mix phx.new` always generates it; aborting."}
      end
    end

    defp already_installed?(content) when is_binary(content) do
      String.contains?(content, PhoenixProdmin.HostProject.sentinel())
    end

    defp maybe_write_backup(igniter, original) do
      if Igniter.exists?(igniter, @backup_path) do
        igniter
      else
        Igniter.create_new_file(igniter, @backup_path, original, on_exists: :skip)
      end
    end

    defp render_template(%{otp_app: otp_app, endpoint_module: endpoint_module}) do
      secret_key_base = :crypto.strong_rand_bytes(48) |> Base.encode64()
      path = Application.app_dir(:phoenix_prodmin, @template_path)

      EEx.eval_file(path,
        assigns: [
          otp_app: otp_app,
          endpoint_module: endpoint_module,
          secret_key_base: secret_key_base
        ]
      )
    end

    defp summary_notice(backup?, already_installed?) do
      backup_line =
        cond do
          already_installed? ->
            "  - skipped backup (already-installed file is not a real original)"

          backup? ->
            "  - backed up original to #{@backup_path}"

          true ->
            "  - skipped backup (--no-backup)"
        end

      """
      phoenix_prodmin installed:
        - wrote #{@runtime_path}
      #{backup_line}
      """
    end
  end
else
  defmodule Mix.Tasks.PhoenixProdmin.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'phoenix_prodmin.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
