defmodule Artemis.Drivers.IBMCloudIAM.ListAccessGroupMembers do
  import Artemis.Drivers.IBMCloudIAM.Request.Helpers

  def call(access_group_id) do
    query_params = [verbose: true]

    get_all_paginated_records([
      data_key: "members",
      path: "/v2/groups/#{access_group_id}/members",
      query_params: query_params
    ])
  end
end
