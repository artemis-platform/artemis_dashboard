defmodule Artemis.CreateSystemTask do
  use Artemis.Context

  alias Artemis.SystemTask

  def call!(params, user) do
    case call(params, user) do
      {:error, _} -> raise(Artemis.Context.Error, "Error creating system task")
      {:ok, result} -> result
    end
  end

  def call(params, user) do
    params
    |> Artemis.Helpers.keys_to_strings()
    |> create_system_task(user)
  end

  defp create_system_task(params, user) do
    extra_params = Map.get(params, "extra_params") || %{}
    type = Map.get(params, "type")
    record = %SystemTask{extra_params: extra_params, type: type}
    changeset = SystemTask.changeset(%SystemTask{}, params)
    system_task = find_system_task(type, user)

    with true <- changeset.valid?,
         true <- system_task != nil,
         async_task <- Task.async(fn -> system_task.action.(extra_params, user) end),
         {:ok, _} <- Event.broadcast({:ok, record}, "system-task:created", params, user) do
      {:ok, async_task}
    else
      _ -> Ecto.Changeset.apply_action(changeset, :insert)
    end
  end

  defp find_system_task(type, user) do
    Enum.find(Artemis.SystemTask.allowed_system_tasks(), fn system_task ->
      system_task.type == type && system_task.verify.(user)
    end)
  end
end
