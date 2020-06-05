defmodule Prex.CLI do
  alias Prex.{Server, Site}

  @new_site_template Path.expand("../templates/new_site", __ENV__.file)
  @generate_usage "Useage: prex generate <site name>"
  @usage "Useage: prex <g|s|clean|c|p> - generate,server,clean,compile,publish"

  def main([]), do: main(:compile)
  def main(["gen" <> _ , site_name]), do: main(:generate, site_name)
  def main(["s" <> _ | _]), do: main(:server)
  def main(["cle" <> _ | _]), do: main(:clean)
  def main(["c" <> _ | _]), do: main(:compile)
  def main(["pub" <> _ | _]), do: main(:publish)
  def main(["us" <> _]) do
    IO.puts @generate_usage
  end
  def main(args) when is_list(args) do
    IO.puts "Given: #{inspect args}"
    IO.puts @usage
  end

  def main(:compile) do
    {:ok, site} = Site.init(".")
    {:ok, compiled_site} = Site.compile(site)
    Site.destroy(site)
    Site.build(compiled_site)
  end

  def main(:generate, path) do
    File.mkdir!(path)
    File.cp_r!(@new_site_template, path)
    Site.init(path)
  end

  def main(:server) do
    {:ok, site} = main(:compile)
    Server.start(site)
    Process.sleep(:infinity)
    {:ok, site}
  end

  def main(:publish) do
    {:ok, site} = main(:compile)
    Site.publish(site)
  end
end

