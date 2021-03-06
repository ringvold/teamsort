defmodule TeamsortWeb.PageLiveTest do
  use TeamsortWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Players"
    assert render(page_live) =~ "Make teams"
  end
end
