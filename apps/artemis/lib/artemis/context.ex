defmodule Artemis.Context do
  defmodule Error do
    defexception message: "Context Error"
  end

  defmacro __using__(_opts) do
    quote do
      import Artemis.Context
      import Artemis.Repo.Helpers
      import Artemis.Repo.Order
      import Artemis.UserAccess

      require Logger

      alias Artemis.CacheInstance
      alias Artemis.Event

      # Cache

      def cache(), do: call_with_cache([])
      def cache(arg1), do: call_with_cache([arg1])
      def cache(arg1, arg2), do: call_with_cache([arg1, arg2])
      def cache(arg1, arg2, arg3), do: call_with_cache([arg1, arg2, arg3])
      def cache(arg1, arg2, arg3, arg4), do: call_with_cache([arg1, arg2, arg3, arg4])

      defp call_with_cache(args) do
        {:ok, _} = create_cache()

        getter = fn ->
          apply(__MODULE__, :call, args)
        end

        # TODO: generate cache key
        key = "key"

        Artemis.CacheInstance.fetch(__MODULE__, key, getter)
      end

      defp create_cache() do
        case CacheInstance.exists?(__MODULE__) do
          true ->
            {:ok, "Cache already exists"}

          false ->
            options = [
              # TODO: define and get reset events from schema
              cache_reset_events: [],
              module: __MODULE__
            ]

            Artemis.CacheSupervisor.start_child(options)
        end
      end
    end
  end
end
