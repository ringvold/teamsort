defmodule TeamsortWeb.App do
  use Surface.LiveView

  alias TeamsortWeb.Teamsort

  def render(assigns) do
    ~F"""
    <div class="section">
      <Teamsort id="teamsort"></Teamsort>
    </div>
    """
  end
end
