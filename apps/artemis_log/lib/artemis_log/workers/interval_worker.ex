defmodule ArtemisLog.IntervalWorker do
  @moduledoc """
  A `use` able module for creating GenServer instances that perform tasks on a
  set interval.

  ## Callbacks

  Define a `call/1` function to be executed at the interval. Receives the
  current `state.data`.

  Must return a tuple `{:ok, _}` or `{:error, _}`.

  ## Options

  Takes the following options:

    :name - Required. Name of the server.
    :enabled - Optional. If set to false, starts in paused state.
    :interval - Optional. Integer or Atom. Interval between calls.
    :log_limit - Optional. Number of log entries to keep.
    :delayed_start - Optional. Integer or Atom. Time to wait for initial call.
    :max_retries - Optional. Atom. Maximum number of times to retry on failure
    :retry_intervals - Optional. List. Number of milliseconds to wait before each
      retry. For a constant value, send a list with one entry: [5]
    :rescue - Optional. Boolean. Whether to rescue from exceptions

  For example:

    use ArtemisLog.IntervalWorker,
      interval: 15_000,
      log_limit: 20,
      name: :repo_reset_on_interval

  """

  @callback call(map(), any()) :: {:ok, any()} | {:error, any()}
  @callback handle_info_callback(any(), any()) :: {:ok, any()} | {:error, any()}
  @callback init_callback(any()) :: {:ok, any()} | {:error, any()}

  @optional_callbacks handle_info_callback: 2, init_callback: 1

  defmacro __using__(options) do
    quote do
      require Logger

      use GenServer

      defmodule State do
        defstruct [
          :config,
          :data,
          :timer,
          log: []
        ]
      end

      defmodule Log do
        defstruct [
          :details,
          :duration,
          :ended_at,
          :module,
          :started_at,
          :success
        ]
      end

      @behaviour ArtemisLog.IntervalWorker
      @default_interval 60_000
      @default_log_limit_fallback 10
      @default_timeout :timer.seconds(60)
      @default_max_retries 6
      @default_rescue true

      @default_retry_intervals [
        :timer.seconds(1),
        :timer.seconds(2),
        :timer.seconds(4),
        :timer.seconds(8),
        :timer.seconds(15)
      ]

      def start_link(config \\ []) do
        initial_state = %State{
          config: config
        }

        dynamic_name = Keyword.get(config, :name)
        configured_name = get_name()

        options = [
          name: dynamic_name || configured_name
        ]

        GenServer.start_link(__MODULE__, initial_state, options)
      end

      def get_name(name \\ nil), do: name || get_option(:name)

      def get_config(name \\ nil), do: GenServer.call(get_name(name), :config, @default_timeout)

      def get_data(name \\ nil), do: GenServer.call(get_name(name), :data, @default_timeout)

      def get_log(name \\ nil), do: GenServer.call(get_name(name), :log, @default_timeout)

      def get_options(), do: unquote(options)

      def get_option(key, default \\ nil)

      def get_option(:delayed_start, default) do
        interval = Keyword.get(get_options(), :delayed_start, default)

        cond do
          interval == :next_full_minute -> Artemis.Helpers.Time.get_milliseconds_to_next_minute() + :timer.minutes(1)
          interval == :next_minute -> Artemis.Helpers.Time.get_milliseconds_to_next_minute()
          interval == :next_hour -> Artemis.Helpers.Time.get_milliseconds_to_next_hour()
          interval == :next_day -> Artemis.Helpers.Time.get_milliseconds_to_next_day()
          true -> interval
        end
      end

      def get_option(:interval, default) do
        fallback = default || @default_interval
        interval = Keyword.get(get_options(), :interval, fallback)

        cond do
          interval == :next_minute -> Artemis.Helpers.Time.get_milliseconds_to_next_minute()
          interval == :next_hour -> Artemis.Helpers.Time.get_milliseconds_to_next_hour()
          interval == :next_day -> Artemis.Helpers.Time.get_milliseconds_to_next_day()
          true -> interval
        end
      end

      def get_option(key, default), do: Keyword.get(get_options(), key, default)

      def get_result(name \\ nil), do: GenServer.call(get_name(name), :result, @default_timeout)

      def get_state(name \\ nil), do: GenServer.call(get_name(name), :state, @default_timeout)

      def fetch_data(options \\ [], name \\ nil) do
        log = get_log(name)

        case length(log) > 0 do
          true -> get_data(name)
          false -> update(options, name).data
        end
      end

      def pause(name \\ nil), do: GenServer.call(get_name(name), :pause, @default_timeout)

      def resume(name \\ nil), do: GenServer.call(get_name(name), :resume, @default_timeout)

      def update(options \\ [], name \\ nil) do
        case Keyword.get(options, :async) do
          true -> Process.send(get_name(name), :update, [])
          _ -> GenServer.call(get_name(name), :update, @default_timeout)
        end
      end

      # Callbacks

      @impl true
      def init(state) do
        state = initial_actions(state)

        {:ok, state} = init_callback(state)

        {:ok, state}
      end

      @impl true
      def handle_call(:config, _from, state) do
        {:reply, state.config, state}
      end

      @impl true
      def handle_call(:data, _from, state) do
        {:reply, state.data, state}
      end

      @impl true
      def handle_call(:log, _from, state) do
        {:reply, state.log, state}
      end

      @impl true
      def handle_call(:pause, _from, state) do
        if state.timer && state.timer != :paused do
          Process.cancel_timer(state.timer)
        end

        {:reply, true, %State{state | timer: :paused}}
      end

      @impl true
      def handle_call(:result, _from, state) do
        result = Artemis.Helpers.deep_get(state, [:data, :result])

        {:reply, result, state}
      end

      @impl true
      def handle_call(:resume, _from, state) do
        if state.timer && state.timer != :paused do
          Process.cancel_timer(state.timer)
        end

        {:reply, true, %State{state | timer: schedule_update()}}
      end

      @impl true
      def handle_call(:state, _from, state) do
        {:reply, state, state}
      end

      @impl true
      @doc "Synchronous"
      def handle_call(:update, _from, state) do
        state = update_state(state)

        {:reply, state, state}
      end

      @impl true
      @doc "Asynchronous"
      def handle_info(:update, state) do
        state = update_state(state)

        {:noreply, state}
      end

      def handle_info(data, state) do
        handle_info_callback(data, state)
      end

      # Overridable Callbacks

      def init_callback(state) do
        {:ok, state}
      end

      def handle_info_callback(_, state) do
        {:noreply, state}
      end

      # Callback Helpers

      defp initial_actions(state) do
        case get_option(:enabled, true) do
          true -> schedule_or_execute_initial_call(state)
          false -> Map.put(state, :timer, :paused)
        end
      end

      defp schedule_or_execute_initial_call(state) do
        # Call immediately use an asynchronous call instead of synchronous
        # one to prevent loading delays on application start
        default_interval = 10
        interval = get_option(:delayed_start, default_interval)

        Map.put(state, :timer, schedule_update(interval))
      end

      defp update_state(state) do
        started_at = Timex.now()
        rescue? = get_option(:rescue, @default_rescue)
        result = call_and_maybe_rescue(rescue?, state, 0)
        ended_at = Timex.now()

        state
        |> Map.put(:data, parse_data(state, result))
        |> Map.put(:log, update_log(state, result, started_at, ended_at))
        |> Map.put(:timer, schedule_update_unless_paused(state))
      end

      defp call_and_maybe_rescue(true, state, retry_count) do
        retry_function = fn -> call_and_maybe_rescue(true, state, retry_count + 1) end

        call_with_retry(state, retry_count, retry_function)
      rescue
        error ->
          Artemis.Helpers.rescue_log(__STACKTRACE__, __MODULE__, error)

          if below_retry_max?(retry_count) do
            retry_function = fn -> call_and_maybe_rescue(true, state, retry_count + 1) end

            call_with_retry(state, retry_count, retry_function)
          else
            {:error, "Error calling interval worker. Exception raised and over retry count maximum."}
          end
      end

      defp call_and_maybe_rescue(false, state, retry_count) do
        retry_function = fn -> call_and_maybe_rescue(false, state, retry_count + 1) end

        call_with_retry(state, retry_count, retry_function)
      end

      defp call_with_retry(state, retry_count, retry_function) do
        if below_retry_max?(retry_count) do
          maybe_sleep_before_call(retry_count)

          case call(state.data, state.config) do
            {:error, _} -> retry_function.()
            result -> result
          end
        else
          {:error, "Error calling interval worker. Error returned and over retry count maximum."}
        end
      end

      defp below_retry_max?(retry_count), do: retry_count <= get_option(:max_retries, @default_max_retries)

      defp maybe_sleep_before_call(0), do: :ok

      defp maybe_sleep_before_call(retry_count) do
        retry_count
        |> get_retry_interval()
        |> :timer.sleep()
      end

      defp get_retry_interval(retry_count) do
        retry_intervals = get_option(:retry_intervals, @default_retry_intervals)
        found_in_retry_intervals? = retry_count < length(retry_intervals)

        case found_in_retry_intervals? do
          true -> Enum.at(retry_intervals, retry_count - 1)
          false -> List.last(retry_intervals)
        end
      end

      defp schedule_update(custom_interval \\ nil) do
        interval = custom_interval || get_option(:interval, @default_interval)

        Process.send_after(self(), :update, interval)
      end

      defp schedule_update_unless_paused(%{timer: timer}) when timer == :paused, do: :paused
      defp schedule_update_unless_paused(%{timer: timer}) when is_nil(timer), do: schedule_update()

      defp schedule_update_unless_paused(%{timer: timer}) do
        Process.cancel_timer(timer)

        schedule_update()
      end

      def parse_data(_state, {:ok, data}), do: data
      def parse_data(%{data: current_data}, _), do: current_data

      defp update_log(%{log: log}, result, started_at, ended_at) do
        entry = %Log{
          details: elem(result, 1),
          duration: Timex.diff(ended_at, started_at),
          ended_at: ended_at,
          module: __MODULE__,
          started_at: started_at,
          success: success?(result)
        }

        log_limit = get_log_limit()
        truncated = Enum.slice(log, 0, log_limit)

        print_log(entry)

        [entry | truncated]
      end

      defp print_log(entry) do
        module = Artemis.Helpers.module_name(__MODULE__)
        start = Timex.format!(entry.started_at, "{h24}:{m}:{s}{ss}")
        duration = entry.duration / 1000

        Artemis.Helpers.log(
          type: "IntervalWorker",
          key: module,
          start: start,
          duration: "#{duration}ms"
        )
      end

      defp get_log_limit() do
        case get_option(:log_limit) do
          nil -> get_default_log_limit()
          limit -> limit
        end
      end

      defp get_default_log_limit() do
        :artemis
        |> Application.fetch_env!(:interval_worker)
        |> Keyword.fetch!(:default_log_limit)
        |> Artemis.Helpers.to_integer()
      rescue
        _ -> @default_log_limit_fallback
      end

      defp success?({:ok, _}), do: true
      defp success?(_), do: false

      # Allow defined `@callback`s to be overwritten

      defoverridable ArtemisLog.IntervalWorker
    end
  end
end
