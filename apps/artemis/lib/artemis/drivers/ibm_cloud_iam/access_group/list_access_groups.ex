defmodule Artemis.Drivers.IBMCloudIAM.ListAccessGroups do
  import Artemis.Drivers.IBMCloudIAM.Request.Helpers

  def call(account_id) do
    query_params = [account_id: account_id]

    get_all_paginated_records([
      data_key: "groups",
      path: "/v2/groups",
      query_params: query_params
    ])
  end
end
