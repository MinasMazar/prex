defmodule Prex.Resource do
  defstruct [:source, :path, :original_content, :content, :dest, procs: [], data: %{}]

  require Logger
  import Prex.Helpers

  def init(%{root: root, source: source, dest: dest, compilers: compilers}, res_source) do
    filename = Path.relative_to(res_source, Path.join(root, source))
    dest_root = Path.expand(dest, root)

    {exts, filename} = extensions(filename)

    %__MODULE__{source: res_source}
    |> eval_path(filename, exts)
    |> eval_dest(filename, dest_root, exts)
    |> eval_procs(exts, compilers)
  end

  def compile(site, resource = %__MODULE__{original_content: nil}) do
    resource
    |> read()
    |> compile(site)
  end

  def compile(site, resource = %__MODULE__{original_content: content, content: nil}) when is_binary(content) do
    compile(site, %{resource | content: content})
  end

  def compile(site, resource = %__MODULE__{content: content}) when is_binary(content) do
    context = %{site: site, page: resource, resource: resource}

    resource = for c <- resource.procs, reduce: resource do
      acc ->
        Logger.debug("[#{c}] Compiling #{resource.source} -> #{resource.dest}")
        c.compile(site, acc, context)
    end

    {:ok, resource}
  end

  def build(_site, r = %__MODULE__{data: %{draft: true}}) do
    {:ok, r}
  end

  def build(_site, r = %__MODULE__{content: out, dest: dest}) when is_binary(out) do
    with outdir <- Path.dirname(dest) do
      Logger.debug("Generating file #{dest}")
      File.mkdir_p!(outdir)
      File.write!(dest, out)
      {:ok, r}
    end
  end

  def build(site, r = %__MODULE__{content: nil}) do
    with {:ok, resource} <- compile(site, r) do
      build(site, resource)
    end
  end

  def destroy(r = %__MODULE__{dest: dest}) do
    Logger.debug("Destroying file #{dest}")
    with :ok <- File.rm(dest), do: r
  end

  def eval_dest(resource, filename, dest_root, []) do
    dest = Path.join(dest_root, filename)
    %{resource | dest: dest}
  end

  def eval_dest(resource, filename, dest_root, [last_ext | _]) do
    dest = Path.join(dest_root, filename <> "." <> last_ext)
    %{resource | dest: dest}
  end

  def eval_path(resource, filename, []) do
    %{resource | path: filename}
  end

  def eval_path(resource, filename, [last_ext | _]) do
    %{resource | path: filename <> "." <> last_ext}
  end

  def eval_procs(resource, exts, compilers) do
    procs =
      exts
      |> Enum.map(fn e -> compilers[e] end)
      |> Enum.reject(fn e -> e == nil end)
      |> Enum.reverse()

    %{resource | procs: procs}
  end

  def read(resource = %__MODULE__{source: source}) do
    case read_file_with_frontmatter(source) do
      {:ok, frontmatter, content} -> %{resource | data: frontmatter, original_content: content}
      {:error, reason} -> Map.put(resource, :errors, [reason])
    end
  end
end
