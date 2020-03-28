defmodule PrexTest.Helpers do
  @root_path Path.expand("test/fixtures/site/")
  def root_path, do: @root_path

  def site_fixture(_) do
    with {:ok, site} <- Prex.Site.init(@root_path) do
      File.rm_rf!(Path.expand(site.dest, site.root))

      [test_site_path: @root_path, site: site]
    end
  end

  def dockerfile_fixture(%{site: site}) do
    dockerfile = Prex.Helpers.find(site, "resources/Dockerfile")
    %{dockerfile: dockerfile}
  end

  def resource_fixture(%{site: %{resources: [res | _]}}) do
     %{resource: res}
  end
end

ExUnit.start()
