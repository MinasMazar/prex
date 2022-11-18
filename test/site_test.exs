defmodule SiteTest do
  use ExUnit.Case
  import PrexTest.Helpers
  doctest Prex.Site
  setup [:site_fixture]

  test "init site ~ site data", %{test_site_path: path} do
    {:ok, site} = Prex.Site.init(path)
    assert length(site.resources) == 4
    assert site.layout =~ ~r[templates/layout.html.eex] # default value
    assert site.title == "Site title"
    assert site.exs_config == "exs"
    assert site.yml_config == "yml"
    assert site.merged_config == "exs"
  end

  test "init site ~ site data with custom params", %{test_site_path: path} do
    {:ok, site} = Prex.Site.init(path, custom_param: "custom")
    assert site.custom_param == "custom"
  end

  test "init site ~ site data with after callback", %{test_site_path: path} do
    {:ok, _site} = Prex.Site.init(path)
    assert_receive :executed_after_callback
  end

  test "init site ~ resources data", %{site: site} do
    index = Prex.Site.find(site, "index.html")

    assert index.procs == [Prex.Compilers.EEx, Prex.Compilers.Markdown, Prex.Compilers.WrapLayout]
    assert index.original_content =~ ~r[## This is Prex!]
    assert index.content == nil
    assert index.data == %{title: "This is Prex!"}
    assert index.path == "index.html"
    refute File.exists?(index.dest)

    dockerfile = Prex.Site.find(site, "resources/Dockerfile")

    assert dockerfile.procs == []
    assert dockerfile.original_content =~ ~r[# This is a Dockerfile]
    refute File.exists?(dockerfile.dest)
  end

  test "init site with no site.yml", %{test_site_path: path} do
    site = %{root: path, conf: "no-conf.yml"}

    {:ok, site} = Prex.Site.init(site)
    assert site.layout =~ ~r[layout.html.eex]
    assert length(site.resources) == 4
  end

  test "compile site", %{site: site} do
    index = Prex.Site.find(site, "index.html")

    assert index.original_content =~ ~r[## This is Prex!]

    {:ok, site} = Prex.Site.compile(site)

    refute File.exists?(index.dest)
  end

  test "build site", %{site: site} do
    index = Prex.Site.find(site, "index.html")

    assert index.original_content =~ ~r[## This is Prex!]

    {:ok, site} = Prex.Site.build(site)

    assert File.exists?(index.dest)
  end

  test "dont't generate drafts", %{site: site} do
    draft = Prex.Site.find(site, "draft.html")

    refute File.exists?(draft.dest)

    Prex.Site.build(site)

    refute File.exists?(draft.dest)
  end

  test "destroy resource", %{site: site} do
    index = Prex.Site.find(site, "index.html")

    Prex.Resource.destroy(index)

    refute File.exists?(index.dest)
  end

  test "publish site via Git", %{site: site} do
    result = Prex.Site.publish(site, simulate: true)

    assert result
  end
end
