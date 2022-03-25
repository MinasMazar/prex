defmodule Prex.Server do
  require Logger
  require EEx

  use Plug.Router

  plug :match
  plug :dispatch

  @not_found_body """
  <h1>Not found</h1>
  The resource <%= path %> was not found.
  <ul>
    <%= for i <- site.resources do %>
      <li><%= i.path %></li
    <% end %>
  </ul>
  """

  match _ do
    site = prepare_site()
    path = precompile_resource_pattern(conn.request_path)
    case Prex.Site.find(site, path) do
      nil -> send_resp(conn, 400, EEx.eval_string(@not_found_body, site: site, path: path))

      resource ->
        with {:ok, resource} <- Prex.Resource.compile(site, resource),
             body <- resource.content do
          send_resp(conn, 200, body)
        end
    end
  end

  def prepare_site do
    {:ok, site} = prex_site().init(".")
    # {:ok, csite} = prex_site().compile(site)
    site
  end

  def start(site) do
    Logger.info("Starting server..")
    Plug.Cowboy.http(__MODULE__, [site], port: port())
  end

  def prex_site do
    Prex.Site
  end

  def precompile_resource_pattern(request_path) do
    String.replace(request_path, ~r[^/], "")
  end

  def port do
    String.to_integer(System.get_env("PREX_SERVER_PORT", "4000"))
  end
end
