defmodule SiteTest do
  use ExUnit.Case

  import PrexTest.Helpers

  doctest Prex.Site

  setup [:site_fixture]

  test "init site", %{test_site_path: path} do
    {:ok, site} = Prex.Site.init(path)
    assert length(site.resources) == 3
    assert site.layout =~ ~r[my_layout.html.eex]

    index = Prex.Site.find(site, "index.html")

    assert index.procs == [Prex.Compilers.EEx, Prex.Compilers.Markdown, Prex.Compilers.WrapLayout]
    assert index.original_content =~ ~r[## This is Prex!]
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
    assert length(site.resources) == 3
  end

  test "compile site", %{site: site} do
    index = Prex.Site.find(site, "index.html")

    assert index.original_content =~ ~r[## This is Prex!]

    {:ok, site} = Prex.Site.compile(site)

    index = Prex.Site.find(site, "index.html")

    assert index.procs == [Prex.Compilers.EEx, Prex.Compilers.Markdown, Prex.Compilers.WrapLayout]
    assert index.content =~ ~r[<h2>This is Prex!</h2>]
    assert index.content =~ ~r[<html>]
    assert index.content =~ ~r[<body>]
    refute File.exists?(index.dest)

    dockerfile = Prex.Site.find(site, "resources/Dockerfile")

    assert dockerfile.procs == []
    assert dockerfile.original_content =~ ~r[# This is a Dockerfile]
    refute File.exists?(dockerfile.dest)
  end

  test "generate resource", %{site: site} do
    index = Prex.Site.find(site, "index.html")
    dockerfile = Prex.Site.find(site, "resources/Dockerfile")

    refute File.exists?(index.dest)
    refute File.exists?(dockerfile.dest)

    Prex.Site.build(site)

    assert File.exists?(index.dest)
    assert File.exists?(dockerfile.dest)
  end
end
