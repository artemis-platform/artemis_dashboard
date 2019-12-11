defmodule Artemis.ContextReport do
  @moduledoc """
  Adds a common interface for returning summary report data
  """

  @callback get_allowed_reports(any()) :: list()
  @callback get_report(Atom.t(), Map.t(), Artemis.User.t()) :: any()

  defmacro __using__(_options) do
    quote do
      import Artemis.ContextReport

      @behaviour Artemis.ContextReport

      defp get_reports(reports \\ [], params \\ %{}, user) do
        reports
        |> filter_requested_reports(user)
        |> get_filtered_reports(params, user)
      end

      defp filter_requested_reports(report, user) when is_atom(report) do
        filter_requested_reports([report], user)
      end

      defp filter_requested_reports(reports, user) when is_list(reports) and length(reports) > 0 do
        allowed_reports_mapset =
          user
          |> get_allowed_reports()
          |> MapSet.new()

        reports
        |> MapSet.new()
        |> MapSet.intersection(allowed_reports_mapset)
        |> MapSet.to_list()
      end

      defp filter_requested_reports(_reports, user) do
        get_allowed_reports(user)
      end

      defp get_filtered_reports(requested, _, _) when requested == [], do: %{}

      defp get_filtered_reports(requested, params, user) do
        requested
        |> gather_reports(params, user)
        |> execute_reports()
      end

      defp gather_reports(requested, params, user) do
        Enum.reduce(requested, %{}, fn key, acc ->
          value = fn ->
            get_report(key, params, user)
          end

          Map.put(acc, key, value)
        end)
      end

      defp execute_reports(reports) do
        Artemis.Helpers.async_await_many(reports)
      end

      # Allow defined `@callback`s to be overwritten

      defoverridable Artemis.ContextReport
    end
  end
end
