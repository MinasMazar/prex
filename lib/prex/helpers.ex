defmodule Prex.Helpers do
  @doc """

  Find a resource among others in the Site giving a regex pattern.
  """

  def find(%{resources: resources}, pattern: pattern) do
    Enum.find(resources, fn %{path: path} ->
      {:ok, regex} = Regex.compile(pattern)
      Regex.match?(regex, path)
    end)
  end

  def find(%{resources: resources}, path_to_find) do
    Enum.find(resources, fn %{path: path} ->
      path == path_to_find
    end)
  end

  @doc """
  Detect compilable extensions for a resource path

  iex> Prex.Helpers.extensions("path/to/resource")
  {[],"path/to/resource"}

  iex> Prex.Helpers.extensions("path/to/resource.eex")
  {["eex"], "path/to/resource"}

  iex> Prex.Helpers.extensions("path/to/resource.html.md.eex")
  {["html", "md", "eex"], "path/to/resource"}
  """

  def extensions(path), do: extensions(path, [])

  def extensions(path, exts) do
    with ext <- Path.extname(path), new_path <- Path.rootname(path) do
      case ext do
        "" -> {exts, new_path}
        "." <> ext -> extensions(new_path, [ext | exts])
      end
    end
  end
end
