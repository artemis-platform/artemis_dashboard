defmodule ArtemisWeb.WikiPageCommentView do
  use ArtemisWeb, :view

  def list_comments?(conn) do
    has?(current_user(conn), "wiki-pages:list:comments") 
  end

  def create_comments?(conn) do
    has?(current_user(conn), "wiki-pages:create:comments") 
  end

  def update_comments?(record, user) do
    comment_user_id = Artemis.Helpers.deep_get(record, [:user, :id])
    owner? = comment_user_id == user.id

    cond do
       has_all?(user, ["wiki-pages:update:comments", "comments:access:all"]) -> true
       has_all?(user, ["wiki-pages:update:comments", "comments:access:self"]) && owner? -> true
       true -> false
    end
  end

  def delete_comments?(record, user) do
    comment_user_id = Artemis.Helpers.deep_get(record, [:user, :id])
    owner? = comment_user_id == user.id

    cond do
       has_all?(user, ["wiki-pages:delete:comments", "comments:access:all"]) -> true
       has_all?(user, ["wiki-pages:delete:comments", "comments:access:self"]) && owner? -> true
       true -> false
    end
  end
end
