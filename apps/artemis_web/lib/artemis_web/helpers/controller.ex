defmodule ArtemisWeb.Helpers.Controller do
  @doc """
  Return tags for a specific resource
  """
  def get_tags(type, user) do
    Artemis.ListTags.call(%{filters: %{type: type}}, user)
  end

  @doc """
  Returns a list of tag params. Will return the ID for existing tags or valid
  params for creating a new tag.
  """
  def tag_params(%{"tags" => names}, type, user), do: tag_params(names, type, user)

  def tag_params(names, type, user) when is_list(names) do
    existing = existing_tags(type, user)

    Enum.map(names, fn name ->
      case Map.get(existing, name) do
        nil -> Artemis.GenerateTagParams.call(%{name: name, type: type})
        id -> %{id: id}
      end
    end)
  end

  def tag_params(_, _, _), do: []

  defp existing_tags(type, user) do
    filters = %{type: type}
    params = %{filters: filters}
    tags = Artemis.ListTags.call(params, user)

    Enum.reduce(tags, %{}, fn tag, acc ->
      Map.put(acc, tag.name, tag.id)
    end)
  end

  @doc """
  Convert checkbox form data to params

  ## Implementation

  A common pattern with checkboxes is to include additional information in
  hidden fields.

  The function filters only checked fields, returning a simplified list of
  params for each entry.

  Given:

    %{
      "id" => "5",
      "user_roles" => %{
        "3" => %{"checked" => "true", "role_id" => "3", "user_id" => "1", "id" => "5"},
        "4" => %{"checked" => "true", "role_id" => "4", "user_id" => "1", "id" => "6"},
        "8" => %{"checked" => "true", "role_id" => "8", "user_id" => "1"}
      }
    }

  Returns:

    %{
      "id" => "5",
      "user_roles" => [
        %{"id" => "5", "role_id" => "3", "user_id" => "1"},
        %{"id" => "6", "role_id" => "4", "user_id" => "1"},
        %{"role_id" => "8", "user_id" => "1"}
      ]
    }
      
  """
  def checkbox_to_params(%{"user_roles" => user_roles} = params, key) do
    filtered =
      Enum.reduce(user_roles, [], fn {_, values}, acc ->
        case Map.get(values, "checked") do
          nil -> acc
          _ -> [Map.delete(values, "checked") | acc]
        end
      end)

    Map.put(params, key, filtered)
  end

  def checkbox_to_params(params, _key), do: params
end
