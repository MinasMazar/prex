defmodule Prex.Site do
  alias Prex.Resource

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
    dest: "dest",
    title: "Site title",
    layout: Path.expand("../../../lib/prex/templates/new_site/templates/layout.html.eex", __ENV__.file),
    resources: [],
    compilers: @default_compilers
  ]

  def init(site_path) do
    site =
      %__MODULE__{}
      |> assign_root(site_path)
      |> detect_resources()
    {:ok, site}
  end

  def compile(site = %__MODULE__{resources: resources}) do
    resources = for r <- resources do
      with {:ok, resource} <- Resource.compile(site, r), do: resource
    end
    {:ok, %{site | resources: resources}}
  end

  def build(site = %__MODULE__{resources: resources}) do
    resources = for r <- resources do
      with {:ok, resource} <- Resource.build(site, r), do: resource
    end
    {:ok, %{site | resources: resources}}
  end

  def detect_resources(site = %__MODULE__{root: root, source: source}) do
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
  def eval_destination(%__MODULE__{root: root, dest: dest}, path)  do
    with {exts, final_dest} <- extensions(path),
         final_ext <- List.last(exts),
         final_dest <- final_dest <> "." <> final_ext do
      root
      |> Path.join(dest)
      |> Path.join(final_dest)
    end
  end

  defp assign_root(site = %__MODULE__{}, root) do
    %{site | root: Path.expand(root)}
  end
end
