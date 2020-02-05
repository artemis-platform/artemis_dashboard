defmodule ArtemisWeb.CommentView do
  use ArtemisWeb, :view

  def update_comments?(record, user) do
    comment_user_id = Artemis.Helpers.deep_get(record, [:user, :id])
    owner? = comment_user_id == user.id

    cond do
      has_all?(user, ["comments:update", "comments:access:all"]) -> true
      has_all?(user, ["comments:update", "comments:access:self"]) && owner? -> true
      true -> false
    end
  end

  def delete_comments?(record, user) do
    comment_user_id = Artemis.Helpers.deep_get(record, [:user, :id])
    owner? = comment_user_id == user.id

    cond do
      has_all?(user, ["comments:delete", "comments:access:all"]) -> true
      has_all?(user, ["comments:delete", "comments:access:self"]) && owner? -> true
      true -> false
    end
  end
end
