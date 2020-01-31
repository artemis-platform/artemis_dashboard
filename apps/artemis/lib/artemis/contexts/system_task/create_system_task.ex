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
    with_transaction(fn ->
      params
      |> create_system_task(user)
      |> Event.broadcast("system-task:created", params, user)
    end)
  end

  defp create_system_task(params, user) do
    record = struct(SystemTask, params)
    changeset = SystemTask.changeset(%SystemTask{}, params)
    system_task = find_system_task(record.type, user)

    {_, changeset} = Ecto.Changeset.apply_action(changeset, :insert)

    with true <- changeset.valid?(),
         true <- system_task != nil,
         extra_params <- Map.get(params, "extra_params", %{}),
         async_task <- Task.async(fn -> system_task.(extra_params, user) end) do
      {:ok, async_task}
    else
      _ -> {:error, changeset}
    end
  end

  defp find_system_task(type, user) do
    Enum.map(Artemis.SystemTask.allowed_system_tasks(), fn system_task ->
      system_task.type == type && system_task.verify.(user)
    end)
  end
end
