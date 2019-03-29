defmodule ArtemisWeb.WikiRevisionView do
  use ArtemisWeb, :view

  def render_wiki_revision_notice(conn, wiki_page, wiki_revision) do
    content = content_tag(:span) do
      [
        "Viewing a revision from ",
        render_date_time(wiki_revision.inserted_at),
        ". For the latest content visit the ",
        link("current documentation", to: Routes.wiki_page_path(conn, :show, wiki_page)),
        "."
      ]
    end

    render_notification :info, body: content
  end
end
