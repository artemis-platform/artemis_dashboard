defmodule ArtemisWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as tables, forms, and
  inputs. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The foundation for styling is Tailwind CSS, a utility-first CSS framework,
  augmented with daisyUI, a Tailwind CSS plugin that provides UI components
  and themes. Here are useful references:

    * [daisyUI](https://daisyui.com/docs/intro/) - a good place to get
      started and see the available components.

    * [Tailwind CSS](https://tailwindcss.com) - the foundational framework
      we build on. You will use it for layout, sizing, flexbox, grid, and
      spacing.

    * [Heroicons](https://heroicons.com) - see `icon/1` for usage.

    * [Phoenix.Component](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html) -
      the component system used by Phoenix. Some components, such as `<.link>`
      and `<.form>`, are defined there.

  """
  use Phoenix.Component
  use Gettext, backend: ArtemisWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class="toast toast-top toast-end z-50"
      {@rest}
    >
      <div class={[
        "alert w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap",
        @kind == :info && "alert-info",
        @kind == :error && "alert-error"
      ]}>
        <.icon :if={@kind == :info} name="hero-information-circle" class="size-5 shrink-0" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle" class="size-5 shrink-0" />
        <div>
          <p :if={@title} class="font-semibold">{@title}</p>
          <p>{msg}</p>
        </div>
        <div class="flex-1" />
        <button type="button" class="group self-start cursor-pointer" aria-label={gettext("close")}>
          <.icon name="hero-x-mark" class="size-5 opacity-40 group-hover:opacity-70" />
        </button>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button with navigation support.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" variant="primary">Send!</.button>
      <.button navigate={~p"/"}>Home</.button>
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :any
  attr :variant, :string, values: ~w(primary)
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    variants = %{"primary" => "btn-primary", nil => "btn-primary btn-soft"}

    assigns =
      assign_new(assigns, :class, fn ->
        ["btn", Map.fetch!(variants, assigns[:variant])]
      end)

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as radio, are best
  written directly in your templates.

  ## Examples

  ```heex
  <.input field={@form[:email]} type="email" />
  <.input name="my-input" errors={["oh no!"]} />
  ```

  ## Select type

  When using `type="select"`, you must pass the `options` and optionally
  a `value` to mark which option should be preselected.

  ```heex
  <.input field={@form[:user_type]} type="select" options={["Admin": "admin", "User": "user"]} />
  ```

  For more information on what kind of data can be passed to `options` see
  [`options_for_select`](https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#options_for_select/2).
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil, doc: "the input class to use over defaults"
  attr :error_class, :any, default: nil, doc: "the input error class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <input
          type="hidden"
          name={@name}
          value="false"
          disabled={@rest[:disabled]}
          form={@rest[:form]}
        />
        <span class="label">
          <input
            type="checkbox"
            id={@id}
            name={@name}
            value="true"
            checked={@checked}
            class={@class || "checkbox checkbox-sm"}
            {@rest}
          />{@label}
        </span>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <select
          id={@id}
          name={@name}
          class={[@class || "w-full select", @errors != [] && (@error_class || "select-error")]}
          multiple={@multiple}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <textarea
          id={@id}
          name={@name}
          class={[
            @class || "w-full textarea",
            @errors != [] && (@error_class || "textarea-error")
          ]}
          {@rest}
        >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class="fieldset mb-2">
      <label for={@id}>
        <span :if={@label} class="label mb-1">{@label}</span>
        <input
          type={@type}
          name={@name}
          id={@id}
          value={Phoenix.HTML.Form.normalize_value(@type, @value)}
          class={[
            @class || "w-full input",
            @errors != [] && (@error_class || "input-error")
          ]}
          {@rest}
        />
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # Helper used by inputs to generate form errors
  defp error(assigns) do
    ~H"""
    <p class="mt-1.5 flex gap-2 items-center text-sm text-error">
      <.icon name="hero-exclamation-circle" class="size-5" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", "pb-4"]}>
      <div>
        <h1 class="text-lg font-semibold leading-8">
          {render_slot(@inner_block)}
        </h1>
        <p :if={@subtitle != []} class="text-sm text-base-content/70">
          {render_slot(@subtitle)}
        </p>
      </div>
      <div class="flex-none">{render_slot(@actions)}</div>
    </header>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <table class="table table-zebra">
      <thead>
        <tr>
          <th :for={col <- @col}>{col[:label]}</th>
          <th :if={@action != []}>
            <span class="sr-only">{gettext("Actions")}</span>
          </th>
        </tr>
      </thead>
      <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)}>
          <td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={@row_click && "hover:cursor-pointer"}
          >
            {render_slot(col, @row_item.(row))}
          </td>
          <td :if={@action != []} class="w-0 font-semibold">
            <div class="flex gap-4">
              <%= for action <- @action do %>
                {render_slot(action, @row_item.(row))}
              <% end %>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <ul class="list">
      <li :for={item <- @item} class="list-row">
        <div class="list-col-grow">
          <div class="font-bold">{item.title}</div>
          <div>{render_slot(item)}</div>
        </div>
      </li>
    </ul>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in `assets/vendor/heroicons.js`.

  ## Examples

      <.icon name="hero-x-mark" />
      <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-4"

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(ArtemisWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(ArtemisWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  # -------------------------------------------------------------------
  # Status indicators
  # -------------------------------------------------------------------

  @status_color_map %{
    "red" => "error",
    "triggered" => "error",
    "warning" => "warning",
    "yellow" => "warning",
    "acknowledged" => "warning",
    "notice" => "warning",
    "green" => "success",
    "normal" => "success",
    "blue" => "info",
    "info" => "info",
    "gray" => "neutral",
    "grey" => "neutral"
  }

  @doc """
  Returns a DaisyUI color token for the given status value.

  ## Examples

      iex> status_color("normal")
      "success"
      iex> status_color("triggered")
      "error"
  """
  def status_color(value, default \\ "neutral") do
    key =
      value
      |> to_string()
      |> String.downcase()
      |> String.trim()

    Map.get(@status_color_map, key, default)
  end

  @doc """
  Renders a small colored status dot.

  Matches the old `render_status_dot/2`.

  ## Examples

      <.status_dot value="normal" />
      <.status_dot value="triggered" size="md" />
  """
  attr :value, :string, required: true
  attr :size, :string, default: "sm", values: ~w(xs sm md lg)
  attr :class, :any, default: nil

  def status_dot(assigns) do
    size_classes = %{
      "xs" => "size-1.5",
      "sm" => "size-2.5",
      "md" => "size-3.5",
      "lg" => "size-5"
    }

    color = status_color(assigns.value)

    assigns =
      assigns
      |> assign(:color, color)
      |> assign(:size_class, Map.get(size_classes, assigns.size, "size-2.5"))

    ~H"""
    <span
      class={[
        "inline-block rounded-full shrink-0",
        @size_class,
        "bg-#{@color}",
        @class
      ]}
      title={@value}
    >
    </span>
    """
  end

  @doc """
  Renders a colored status badge/label.

  Matches the old `render_status_label/2`.

  ## Examples

      <.status_label value="Normal" />
      <.status_label value="Triggered" color="error" />
  """
  attr :value, :string, required: true
  attr :color, :string, default: nil
  attr :class, :any, default: nil

  def status_label(assigns) do
    color = assigns.color || status_color(assigns.value)
    assigns = assign(assigns, :color, color)

    ~H"""
    <span class={[
      "badge badge-sm font-medium",
      "badge-#{@color}",
      @class
    ]}>
      {@value}
    </span>
    """
  end

  # -------------------------------------------------------------------
  # Notification / alert boxes
  # -------------------------------------------------------------------

  @doc """
  Renders an inline notification/alert box.

  Matches the old `render_notification/2`.

  ## Examples

      <.notification kind={:info} header="Heads up">Check your settings.</.notification>
      <.notification kind={:error}>Something went wrong.</.notification>
  """
  attr :kind, :atom, default: :info, values: [:info, :success, :warning, :error]
  attr :header, :string, default: nil
  attr :class, :any, default: nil
  attr :dismissible, :boolean, default: false
  attr :rest, :global

  slot :inner_block

  def notification(assigns) do
    icon_name = %{
      info: "hero-information-circle",
      success: "hero-check-circle",
      warning: "hero-exclamation-triangle",
      error: "hero-exclamation-circle"
    }

    assigns = assign(assigns, :icon_name, Map.fetch!(icon_name, assigns.kind))

    ~H"""
    <div
      role="alert"
      class={[
        "alert shadow-sm",
        @kind == :info && "alert-info",
        @kind == :success && "alert-success",
        @kind == :warning && "alert-warning",
        @kind == :error && "alert-error",
        @class
      ]}
      {@rest}
    >
      <.icon name={@icon_name} class="size-5 shrink-0" />
      <div>
        <h3 :if={@header} class="font-semibold">{@header}</h3>
        <div class="text-sm">{render_slot(@inner_block)}</div>
      </div>
    </div>
    """
  end

  # -------------------------------------------------------------------
  # Confirmation modal
  # -------------------------------------------------------------------

  @doc """
  Renders a button that opens a generic confirmation modal.

  Supports two confirmation modes:

  * **LiveView event** — pass `on_confirm` with a `JS` command
  * **Static link** — pass `href` (and optionally `method`)

  ## Examples

      <.confirm_action
        id="archive-item"
        header="Archive Item"
        message="This item will be moved to the archive."
        on_confirm={JS.push("archive", value: %{id: 1})}
        confirm_label="Archive"
        confirm_class="btn btn-warning"
      />

      <.confirm_action
        header="Approve Request"
        message="This will approve the pending request."
        href="/requests/1/approve"
        method="put"
        confirm_label="Approve"
        confirm_class="btn btn-success"
      >
        Approve
      </.confirm_action>
  """
  attr :id, :string, default: nil
  attr :header, :string, required: true
  attr :message, :string, required: true
  attr :href, :string, default: nil
  attr :method, :string, default: "delete"
  attr :on_confirm, :any, default: nil, doc: "JS command to execute on confirm (LiveView mode)"
  attr :confirm_label, :string, default: nil
  attr :confirm_class, :string, default: "btn btn-primary"
  attr :class, :any, default: nil

  slot :inner_block

  def confirm_action(assigns) do
    assigns =
      assigns
      |> assign_new(:modal_id, fn ->
        if assigns.id, do: assigns.id, else: "confirm-modal-#{System.unique_integer([:positive])}"
      end)
      |> assign_new(:resolved_confirm_label, fn ->
        assigns.confirm_label || gettext("Confirm")
      end)

    ~H"""
    <button
      type="button"
      class={@class || "btn btn-sm btn-soft btn-primary"}
      onclick={"document.getElementById('#{@modal_id}').showModal()"}
    >
      <%= if @inner_block != [] do %>
        {render_slot(@inner_block)}
      <% else %>
        {@resolved_confirm_label}
      <% end %>
    </button>
    <dialog id={@modal_id} class="modal">
      <div class="modal-box">
        <h3 class="text-lg font-bold text-left">{@header}</h3>
        <p class="py-4 text-left text-base-content/70">{@message}</p>
        <div class="modal-action">
          <form method="dialog">
            <button class="btn btn-ghost">{gettext("Cancel")}</button>
          </form>
          <%= if @on_confirm do %>
            <button
              type="button"
              class={@confirm_class}
              phx-click={@on_confirm}
              onclick={"document.getElementById('#{@modal_id}').close()"}
            >
              {@resolved_confirm_label}
            </button>
          <% else %>
            <.link href={@href} method={@method} class={@confirm_class}>
              {@resolved_confirm_label}
            </.link>
          <% end %>
        </div>
      </div>
      <form method="dialog" class="modal-backdrop">
        <button>close</button>
      </form>
    </dialog>
    """
  end

  @doc """
  Renders a delete confirmation button + modal.

  A convenience wrapper around `confirm_action/1` with delete-specific
  defaults for header, message, and styling.

  ## Examples

      <.delete_confirmation href="/users/1" />

      <.delete_confirmation
        id="delete-user-1"
        on_confirm={JS.push("delete-user", value: %{id: 1})}
        message="Are you sure you want to delete this user?"
      />
  """
  attr :id, :string, default: nil
  attr :label, :string, default: nil
  attr :href, :string, default: nil
  attr :on_confirm, :any, default: nil
  attr :message, :string, default: nil
  attr :confirm_label, :string, default: nil
  attr :class, :any, default: nil

  def delete_confirmation(assigns) do
    assigns =
      assigns
      |> assign_new(:resolved_label, fn -> assigns.label || gettext("Delete") end)
      |> assign_new(:resolved_message, fn ->
        assigns.message || gettext("This action cannot be undone. Are you sure?")
      end)
      |> assign_new(:resolved_confirm_label, fn ->
        assigns.confirm_label || gettext("Delete")
      end)

    ~H"""
    <.confirm_action
      id={@id}
      header={gettext("Confirm Delete")}
      message={@resolved_message}
      href={@href}
      on_confirm={@on_confirm}
      confirm_label={@resolved_confirm_label}
      confirm_class="btn btn-error"
      class={@class || "btn btn-error btn-sm btn-soft"}
    >
      {@resolved_label}
    </.confirm_action>
    """
  end

  # -------------------------------------------------------------------
  # Key-value list
  # -------------------------------------------------------------------

  @doc """
  Renders a key-value definition list.

  Matches the old `render_key_value_list/1`.

  ## Examples

      <.key_value_list>
        <:item label="Name">John Smith</:item>
        <:item label="Email">john@example.com</:item>
      </.key_value_list>
  """
  attr :class, :any, default: nil

  slot :item, required: true do
    attr :label, :string, required: true
  end

  def key_value_list(assigns) do
    ~H"""
    <dl class={["divide-y divide-base-300", @class]}>
      <div :for={item <- @item} class="flex gap-4 py-3 text-sm">
        <dt class="w-40 shrink-0 font-medium text-base-content/70">{item.label}</dt>
        <dd class="flex-1 text-base-content">{render_slot(item)}</dd>
      </div>
    </dl>
    """
  end

  # -------------------------------------------------------------------
  # User avatar
  # -------------------------------------------------------------------

  @doc """
  Renders a user avatar with initials.

  Matches the old `render_user_initials/1`.

  ## Examples

      <.user_avatar name="John Smith" />
      <.user_avatar name="Jane Doe" size="lg" />
  """
  attr :name, :string, required: true
  attr :size, :string, default: "md", values: ~w(xs sm md lg xl)
  attr :class, :any, default: nil

  def user_avatar(assigns) do
    size_classes = %{
      "xs" => "size-6 text-[10px]",
      "sm" => "size-7 text-xs",
      "md" => "size-8 text-sm",
      "lg" => "size-10 text-base",
      "xl" => "size-14 text-lg"
    }

    assigns =
      assigns
      |> assign(:initials, user_initials(assigns.name))
      |> assign(:size_class, Map.get(size_classes, assigns.size, "size-8 text-sm"))

    ~H"""
    <div
      class={[
        "rounded-full bg-primary flex items-center justify-center text-primary-content font-semibold shrink-0",
        @size_class,
        @class
      ]}
      title={@name}
    >
      {@initials}
    </div>
    """
  end

  @doc """
  Returns uppercase initials from a user name string.

  ## Examples

      iex> user_initials("John Smith")
      "JS"
      iex> user_initials("John von Smith-Doe")
      "JVSD"
  """
  def user_initials(name) when is_binary(name) do
    name
    |> String.replace(~r/[-_]/, " ")
    |> String.split(" ", trim: true)
    |> Enum.map_join(&String.first/1)
    |> String.upcase()
  end

  def user_initials(_), do: nil

  # -------------------------------------------------------------------
  # Section headings
  # -------------------------------------------------------------------

  @doc """
  Renders a section heading with optional anchor.

  Matches the old `h2/2` through `h5/2` helpers.

  ## Examples

      <.heading level={2}>Users</.heading>
      <.heading level={3} class="mb-4">Details</.heading>
  """
  attr :level, :integer, default: 2, values: [2, 3, 4, 5]
  attr :class, :any, default: nil

  slot :inner_block, required: true

  def heading(assigns) do
    level_classes = %{
      2 => "text-xl font-bold text-base-content",
      3 => "text-lg font-semibold text-base-content",
      4 => "text-base font-semibold text-base-content",
      5 => "text-sm font-semibold text-base-content/80 uppercase tracking-wide"
    }

    assigns = assign(assigns, :level_class, Map.get(level_classes, assigns.level))

    ~H"""
    <div class="heading-container">
      <h2 :if={@level == 2} class={[@level_class, @class]}>{render_slot(@inner_block)}</h2>
      <h3 :if={@level == 3} class={[@level_class, @class]}>{render_slot(@inner_block)}</h3>
      <h4 :if={@level == 4} class={[@level_class, @class]}>{render_slot(@inner_block)}</h4>
      <h5 :if={@level == 5} class={[@level_class, @class]}>{render_slot(@inner_block)}</h5>
    </div>
    """
  end

  # -------------------------------------------------------------------
  # Number formatting
  # -------------------------------------------------------------------

  @doc """
  Returns the sign atom for a number: `:positive`, `:negative`, or `:zero`.
  """
  def number_sign(value) when is_number(value) do
    cond do
      value > 0 -> :positive
      value < 0 -> :negative
      true -> :zero
    end
  end

  def number_sign(value) when is_binary(value) do
    case Float.parse(value) do
      {num, _} -> number_sign(num)
      :error -> :zero
    end
  end

  @doc """
  Returns the sign symbol string for a number.

  ## Examples

      iex> number_sign_symbol(5)
      "+"
      iex> number_sign_symbol(-3)
      "-"
  """
  def number_sign_symbol(value, opts \\ []) do
    case number_sign(value) do
      :positive -> "+"
      :negative -> "-"
      :zero -> Keyword.get(opts, :zero, "")
    end
  end

  @doc """
  Formats a number with comma delimiters.

  ## Examples

      iex> pretty_print_number(1234567)
      "1,234,567"
      iex> pretty_print_number(1234.5, precision: 2)
      "1,234.50"
  """
  def pretty_print_number(number, opts \\ []) do
    precision = Keyword.get(opts, :precision, 0)
    absolute = if Keyword.get(opts, :absolute_value, false), do: abs(number), else: number

    float_val = absolute / 1

    float_val
    |> :erlang.float_to_binary(decimals: precision)
    |> format_with_commas()

  end

  defp format_with_commas(str) do
    case String.split(str, ".") do
      [int_part] -> insert_commas(int_part)
      [int_part, dec_part] -> insert_commas(int_part) <> "." <> dec_part
    end
  end

  defp insert_commas(int_str) do
    {sign, digits} =
      case int_str do
        "-" <> rest -> {"-", rest}
        other -> {"", other}
      end

    formatted =
      digits
      |> String.reverse()
      |> String.to_charlist()
      |> Enum.chunk_every(3)
      |> Enum.join(",")
      |> String.reverse()

    sign <> formatted
  end
end
