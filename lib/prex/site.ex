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
    conf: "site.yml",
    data: nil,
    dest: "dest",
    title: "Site title",
    layout: "templates/layout.html.eex",
    resources: [],
    compilers: @default_compilers
  ]

  def init(site_path) when is_binary(site_path) do
    init(%{root: site_path})
  end

  def init(site = %{root: root}) when is_map(site) do
    site =
      %__MODULE__{root: root}
      |> Map.merge(site)
      |> assign_root(root)
      |> load_site_conf()
      |> detect_resources()

    Logger.debug("Initialized site #{inspect site}")

    {:ok, site}
  end

  def compile(site = %__MODULE__{resources: resources}) do
    Logger.debug("Compiling site #{inspect site}")
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

  def build(site = %__MODULE__{resources: resources}) do
    resources = for r <- resources do
      with {:ok, resource} <- Resource.build(site, r), do: resource
    end
    {:ok, %{site | resources: resources}}
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

  def load_site_conf(site = %{root: root, conf: conf}) do
    conf_file = Path.join(root, conf)

    case YamlElixir.read_from_file(conf_file) do
      {:ok, data} ->
        Logger.debug("Merging site data: #{inspect site} <- #{inspect data}")
        Map.merge(site, data)
      {:error, _} -> site
    end
  end

  defp assign_root(site, root) do
    %{site | root: Path.expand(root)}
  end
end
