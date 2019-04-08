defmodule ArtemisLog.CreateHttpRequestLog do
  use ArtemisLog.Context

  alias ArtemisLog.Repo
  alias ArtemisLog.RequestLog

  def call(%{data: data, user: user}) do
    params = data
      |> Map.put(:user_id, user && Map.get(user, :id))
      |> Map.put(:user_name, user && Map.get(user, :name))

    %RequestLog{}
    |> RequestLog.changeset(params)
    |> Repo.insert
  end
end
