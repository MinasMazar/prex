defmodule Prex.Site do
  alias Prex.Resource

  require Logger
  import Prex.Helpers

  @default_compilers %{
    "html" => Prex.Compilers.WrapLayout,
    "eex" => Prex.Compilers.EEx,
    "md" => Prex.Compilers.Markdown,
    "markdown" => Prex.Compilers.Markdown,
  }

  defstruct [
    :root,
    source: "source",
    source_path: nil,
    dest: "dest",
    dest_path: nil,
    title: "Site title",
    layout: "templates/layout.html.eex",
    resources: [],
    compilers: @default_compilers,
    errors: []
  ]

  def init(site_path) when is_binary(site_path) do
    init(%{root: site_path})
  end

  def init(site_path, opts) when is_binary(site_path) and is_list(opts) do
    with opts <- Enum.into(opts, %{}) do
      init(Map.put(opts, :root, site_path))
    end
  end

  def init(site_path, opts) when is_binary(site_path) and is_map(opts) do
    init(Map.put(opts, :root, site_path))
  end

  def init(site = %{root: root}) when is_map(site) do
    site =
      %__MODULE__{root: root}
      |> Map.merge(site)
      |> assign_dirs(root)
      |> load_conf()
      |> detect_resources()
      |> execute_callback()

    Logger.debug("Initialized site #{inspect site}")

    {:ok, site}
  end

  def compile(site = %__MODULE__{resources: resources}) do
    Logger.debug("Compiling site #{inspect site}")
    Logger.info("Compiling site..\n#{inspect site}")
    resources = for r <- resources do
      Logger.debug("Compiling #{r.source}")
      with {:ok, resource} <- Resource.compile(site, r) do
        Logger.debug("Compiled #{resource.dest}!")
        Logger.debug("--------")
        resource
      end
    end
    Logger.debug("Compiled site #{site.title}!")
    {:ok, %{site | resources: resources}}
  end

  def build(site = %__MODULE__{dest: dest, root: root, resources: resources}) do
    resources = for r <- resources do
      with {:ok, resource} <- Resource.build(site, r), do: resource
    end
    {:ok, %{site | resources: resources}}
  end

  def destroy(%__MODULE__{resources: resources}) do
    resources = for r <- resources do
      Resource.destroy(r)
    end
  end

  def publish(site), do: publish(site, simulate: false)
  def publish(site = %__MODULE__{dest_path: dest_path}, simulate: true), do: {:ok, site}
  def publish(site = %__MODULE__{dest_path: dest_path}, simulate: false) do
    with timestamp <- DateTime.utc_now() |> DateTime.to_string(),
         commit_message <- "[Prex] auto publish after compile #{timestamp}" do
      Logger.info("Publishing via git: #{commit_message}")
      File.mkdir(dest_path)
      repo = Git.new(dest_path)
      Git.add(repo, ".")
      Git.commit repo, ["-m", commit_message]
      case Git.push repo, ["origin", "master"] do
        {:ok, repo} -> {:ok, site}
        {:error, %{message: message}} ->
          error = "Cannot publish site: #{message}"
          {:error, append_error(site, error)}
      end
    end
  end

  def detect_resources(site = %{root: root, source: source}) do
    resources =
      root
      |> Path.join(source)
      |> Path.join("**/*")
      |> Path.expand(root)
      |> Path.wildcard()
      |> Enum.reject(fn p -> File.dir?(p) end)

    resources = for r <- resources do
      site
      |> Resource.init(r)
      |> Resource.read()
    end

    %{site | resources: resources}
  end

  def find(site, pattern) do
    Prex.Helpers.find(site, pattern)
  end

  @doc """
  Eval destination path, given a Site with root, source, dest.
  """
  def eval_destination(%{root: root, dest: dest}, path)  do
    with {exts, final_dest} <- extensions(path),
         final_ext <- List.last(exts),
         final_dest <- final_dest <> "." <> final_ext do
      root
      |> Path.join(dest)
      |> Path.join(final_dest)
    end
  end

  def load_conf(site) do
    site
    |> load_site_yaml()
    |> load_site_exs()
  end

  def load_site_yaml(site = %{root: root}) do
    conf_file = Path.join(root, "site.yml")

    case YamlElixir.read_from_file(conf_file, atoms: true) do
      {:ok, data} ->
        Logger.debug("Merging site data: #{inspect site} <- #{inspect data}")
        Map.merge(site, data)
      {:error, error} -> append_error(site, error)
    end
  end

  def load_site_exs(site = %{root: root}) do
    conf_file = Path.join(root, "site.exs")

    try do
      with {data, _} <- Code.eval_file(conf_file) do
        if is_map(data), do: Map.merge(site, data), else: site
      end
    rescue
      CompileError -> Map.put(site, :errors, ["Compile error in #{conf_file}"])
      Code.LoadError -> Map.put(site, :errors, ["Cannot load conf file at #{conf_file}"])
    end
  end

  defp assign_dirs(site, root) do
    Map.merge(
      site,
      %{
        root: Path.expand(root),
        dest_path: Path.expand(site.dest, root),
        source_path: Path.expand(site.
          source, root)
      }
    )
  end

  defp execute_callback(site = %{after: callback}) when is_function(callback) do
    callback.(site)
    site
  end

  defp execute_callback(site) do
    site
  end

  defp append_error(site, error) do
    Logger.debug(error)
    %{site | errors: [error | site.errors]}
  end
end
