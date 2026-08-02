defmodule ArtemisWeb.Layouts do
  @moduledoc """
  Application layouts and structural components for Artemis Dashboard.

  Provides the main app chrome (navigation, footer) and page-level
  structural components (page headers, breadcrumbs, content sections).

  All colors use DaisyUI semantic tokens so the entire UI adapts
  automatically when switching between light / dark / custom themes.
  """
  use ArtemisWeb, :html

  embed_templates "layouts/*"

  @dropdown_ids ~w(clouds-menu on-call-menu admin-menu)

  # -------------------------------------------------------------------
  # App layout
  # -------------------------------------------------------------------

  @doc """
  Renders the main application layout.

  Provides the top navigation bar with mega-dropdown menus, sub-bar
  with status info, gradient accent stripe, content area, and footer.
  """
  attr :flash, :map, required: true

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col bg-base-200">
      <header id="primary-header" class="bg-base-100 sticky top-0 z-40">
        <%!-- Main navigation row --%>
        <div class="relative z-30">
          <div class="flex items-center h-16 px-4 lg:px-8">
            <a href="/" id="logo" class="flex items-center gap-2 mr-6 shrink-0">
              <.icon name="hero-fire-solid" class="size-7 text-secondary" />
              <span class="text-base font-semibold text-base-content tracking-tight hidden sm:inline">
                Artemis Dashboard
              </span>
            </a>

            <nav id="primary-navigation" class="hidden lg:flex items-center flex-1">
              <.nav_link href="/" label="Dashboard" />
              <.nav_link href="/customers" label="Customers" />
              <.clouds_dropdown />
              <.on_call_dropdown />
              <.admin_dropdown />
              <.nav_link href="/docs" label="Docs" />
            </nav>

            <div class="flex-1 lg:flex-none" />

            <div id="icon-navigation" class="flex items-center gap-1 mr-2">
              <.link
                href="/search"
                id="quick-search"
                class="p-2 text-base-content/50 hover:text-base-content/80 rounded-md hover:bg-base-200 transition-colors"
              >
                <.icon name="hero-magnifying-glass" class="size-5" />
              </.link>
              <.theme_switcher />
              <button class="p-2 text-base-content/50 hover:text-base-content/80 rounded-md hover:bg-base-200 transition-colors">
                <.icon name="hero-bell" class="size-5" />
              </button>
              <button class="p-2 text-base-content/50 hover:text-base-content/80 rounded-md hover:bg-base-200 transition-colors">
                <.icon name="hero-question-mark-circle" class="size-5" />
              </button>
            </div>

            <div id="user-navigation" class="flex items-center">
              <button class="flex items-center gap-2 px-3 py-1.5 text-sm text-base-content/80 hover:bg-base-200 rounded-md transition-colors">
                <div class="size-7 rounded-full bg-primary flex items-center justify-center text-primary-content text-xs font-semibold">
                  AH
                </div>
                <span class="hidden sm:inline font-medium">Artemis Hall</span>
              </button>
            </div>

            <button
              id="mobile-menu-toggle"
              class="lg:hidden p-2 ml-1 text-base-content/50 hover:text-base-content/80 rounded-md hover:bg-base-200 transition-colors"
              phx-click={
                JS.toggle(
                  to: "#mobile-nav",
                  in:
                    {"ease-out duration-200", "opacity-0 -translate-y-1", "opacity-100 translate-y-0"},
                  out:
                    {"ease-in duration-150", "opacity-100 translate-y-0", "opacity-0 -translate-y-1"}
                )
              }
            >
              <.icon name="hero-bars-3" class="size-6" />
            </button>
          </div>
        </div>

        <%!-- Mobile navigation --%>
        <nav id="mobile-nav" class="hidden lg:hidden border-t border-base-300 bg-base-100 px-4 py-3">
          <.mobile_nav_section label="Dashboard" icon="hero-home" href="/" />
          <.mobile_nav_section label="Customers" icon="hero-building-office" href="/customers" />
          <.mobile_nav_group label="Clouds" icon="hero-cloud" id="mobile-clouds">
            <.mobile_nav_link href="/clouds" label="List Clouds" />
            <.mobile_nav_link href="/data-centers" label="Data Centers" />
            <.mobile_nav_link href="/machines" label="Machines" />
            <.mobile_nav_link href="/jobs" label="Jobs" />
          </.mobile_nav_group>
          <.mobile_nav_group label="On Call" icon="hero-phone-arrow-up-right" id="mobile-on-call">
            <.mobile_nav_link href="/on-call" label="Overview" />
            <.mobile_nav_link href="/incidents" label="Incidents" />
          </.mobile_nav_group>
          <.mobile_nav_group label="Admin" icon="hero-cog-6-tooth" id="mobile-admin">
            <.mobile_nav_link href="/users" label="Users" />
            <.mobile_nav_link href="/roles" label="Roles" />
            <.mobile_nav_link href="/permissions" label="Permissions" />
            <.mobile_nav_link href="/features" label="Features" />
            <.mobile_nav_link href="/event-logs" label="Event Logs" />
            <.mobile_nav_link href="/sessions" label="Sessions" />
          </.mobile_nav_group>
          <.mobile_nav_section label="Docs" icon="hero-book-open" href="/docs" />
        </nav>

        <%!-- Sub-bar --%>
        <div class="flex items-center justify-between h-11 px-4 lg:px-8 border-t border-base-300 text-sm">
          <div class="flex items-center gap-4">
            <div class="flex items-center gap-2">
              <span class="size-2 rounded-full bg-success"></span>
              <span class="text-base-content/70">Current Status</span>
            </div>
            <span class="text-base-content/20 hidden sm:inline">|</span>
            <span class="text-base-content/60 hidden sm:inline">
              On Call: <span class="text-base-content/80">Sarah Chen, Mike Ross</span>
            </span>
          </div>
          <div class="hidden sm:flex items-center gap-4 text-base-content/60">
            <a href="#" class="hover:text-primary transition-colors">GitHub</a>
            <a href="#" class="hover:text-primary transition-colors">ServiceNow</a>
            <a href="#" class="hover:text-primary transition-colors">PagerDuty</a>
          </div>
        </div>

        <%!-- Gradient accent stripe --%>
        <div class="gradient-stripe h-[3px]"></div>
      </header>

      <main class="flex-1">
        {render_slot(@inner_block)}
      </main>

      <footer id="primary-footer" class="bg-neutral text-neutral-content/60">
        <div class="px-4 lg:px-8 py-12">
          <div
            id="primary-footer-navigation"
            class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-8 mb-12"
          >
            <div>
              <h4 class="text-neutral-content text-sm font-semibold mb-4">Customers</h4>
              <ul class="space-y-2 text-sm">
                <li>
                  <a href="/customers" class="hover:text-neutral-content transition-colors">
                    List Customers
                  </a>
                </li>
                <li>
                  <a href="#" class="hover:text-neutral-content transition-colors">Create New</a>
                </li>
              </ul>
            </div>
            <div>
              <h4 class="text-neutral-content text-sm font-semibold mb-4">Clouds</h4>
              <ul class="space-y-2 text-sm">
                <li>
                  <a href="/clouds" class="hover:text-neutral-content transition-colors">
                    List Clouds
                  </a>
                </li>
                <li>
                  <a href="/data-centers" class="hover:text-neutral-content transition-colors">
                    Data Centers
                  </a>
                </li>
                <li>
                  <a href="/machines" class="hover:text-neutral-content transition-colors">
                    Machines
                  </a>
                </li>
                <li><a href="/jobs" class="hover:text-neutral-content transition-colors">Jobs</a></li>
              </ul>
            </div>
            <div>
              <h4 class="text-neutral-content text-sm font-semibold mb-4">On Call</h4>
              <ul class="space-y-2 text-sm">
                <li>
                  <a href="/on-call" class="hover:text-neutral-content transition-colors">Overview</a>
                </li>
                <li>
                  <a href="/incidents" class="hover:text-neutral-content transition-colors">
                    Incidents
                  </a>
                </li>
              </ul>
            </div>
            <div>
              <h4 class="text-neutral-content text-sm font-semibold mb-4">Admin</h4>
              <ul class="space-y-2 text-sm">
                <li>
                  <a href="/users" class="hover:text-neutral-content transition-colors">Users</a>
                </li>
                <li>
                  <a href="/roles" class="hover:text-neutral-content transition-colors">Roles</a>
                </li>
                <li>
                  <a href="/permissions" class="hover:text-neutral-content transition-colors">
                    Permissions
                  </a>
                </li>
                <li>
                  <a href="/features" class="hover:text-neutral-content transition-colors">
                    Features
                  </a>
                </li>
              </ul>
            </div>
            <div>
              <h4 class="text-neutral-content text-sm font-semibold mb-4">Events</h4>
              <ul class="space-y-2 text-sm">
                <li>
                  <a href="/event-logs" class="hover:text-neutral-content transition-colors">
                    Event Logs
                  </a>
                </li>
                <li>
                  <a href="/sessions" class="hover:text-neutral-content transition-colors">
                    Sessions
                  </a>
                </li>
              </ul>
            </div>
            <div>
              <h4 class="text-neutral-content text-sm font-semibold mb-4">Documentation</h4>
              <ul class="space-y-2 text-sm">
                <li>
                  <a href="/docs" class="hover:text-neutral-content transition-colors">View Docs</a>
                </li>
              </ul>
            </div>
          </div>
          <div class="gradient-stripe h-[3px] mb-8"></div>
          <div class="flex items-center justify-between text-sm">
            <div class="flex items-center gap-2">
              <.icon name="hero-fire-solid" class="size-5 text-secondary" />
              <span class="text-neutral-content/50">Artemis Dashboard</span>
            </div>
            <span class="text-neutral-content/40">&copy; {DateTime.utc_now().year}</span>
          </div>
        </div>
      </footer>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  # -------------------------------------------------------------------
  # Mega-dropdown content
  # -------------------------------------------------------------------

  defp clouds_dropdown(assigns) do
    ~H"""
    <.dropdown_panel
      id="clouds-menu"
      label="Clouds"
      title="Clouds"
      description="Details of every deployed cloud and supporting instances."
    >
      <div class="grid grid-cols-2 md:grid-cols-4 gap-8">
        <.dropdown_section title="Clouds">
          <.dropdown_link href="/clouds" label="List Clouds" />
          <.dropdown_link href="#" label="Create New Cloud" />
        </.dropdown_section>
        <.dropdown_section title="Data Centers">
          <.dropdown_link href="/data-centers" label="List Data Centers" />
          <.dropdown_link href="#" label="Create New Data Center" />
        </.dropdown_section>
        <.dropdown_section title="Machines">
          <.dropdown_link href="/machines" label="List Machines" />
          <.dropdown_link href="#" label="Create New Machine" />
        </.dropdown_section>
        <.dropdown_section title="Jobs">
          <.dropdown_link href="/jobs" label="List Jobs" />
          <.dropdown_link href="#" label="Create New Job" />
        </.dropdown_section>
      </div>
    </.dropdown_panel>
    """
  end

  defp on_call_dropdown(assigns) do
    ~H"""
    <.dropdown_panel
      id="on-call-menu"
      label="On Call"
      title="On Call"
      description="Tools to better understand and respond to the current status."
    >
      <div class="grid grid-cols-2 md:grid-cols-4 gap-8">
        <.dropdown_section title="On Call">
          <.dropdown_link href="/on-call" label="Overview" />
        </.dropdown_section>
        <.dropdown_section title="Incidents">
          <.dropdown_link href="/incidents" label="List Incidents" />
        </.dropdown_section>
      </div>
    </.dropdown_panel>
    """
  end

  defp admin_dropdown(assigns) do
    ~H"""
    <.dropdown_panel
      id="admin-menu"
      label="Admin"
      title="Admin"
      description="Administrative tools to manage the site."
    >
      <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-8">
        <.dropdown_section title="Users">
          <.dropdown_link href="/users" label="List Users" />
          <.dropdown_link href="#" label="Create New User" />
        </.dropdown_section>
        <.dropdown_section title="Roles">
          <.dropdown_link href="/roles" label="List Roles" />
          <.dropdown_link href="#" label="Create New Role" />
        </.dropdown_section>
        <.dropdown_section title="Permissions">
          <.dropdown_link href="/permissions" label="List Permissions" />
          <.dropdown_link href="#" label="Create New Permission" />
        </.dropdown_section>
        <.dropdown_section title="Features">
          <.dropdown_link href="/features" label="List Features" />
          <.dropdown_link href="#" label="Create New Feature" />
        </.dropdown_section>
        <.dropdown_section title="Event Log">
          <.dropdown_link href="/event-logs" label="View Event Logs" />
        </.dropdown_section>
        <.dropdown_section title="Sessions">
          <.dropdown_link href="/sessions" label="View Sessions" />
        </.dropdown_section>
        <.dropdown_section title="Tags">
          <.dropdown_link href="/tags" label="List Tags" />
          <.dropdown_link href="#" label="Create New Tag" />
        </.dropdown_section>
        <.dropdown_section title="Teams">
          <.dropdown_link href="/teams" label="List Teams" />
          <.dropdown_link href="#" label="Create New Team" />
        </.dropdown_section>
      </div>
    </.dropdown_panel>
    """
  end

  # -------------------------------------------------------------------
  # Page-level structural components
  # -------------------------------------------------------------------

  @doc """
  Renders a dark page header band with title, optional action buttons,
  and optional tabbed secondary navigation.
  """
  attr :title, :string, required: true
  slot :actions
  slot :tabs

  def page_header(assigns) do
    ~H"""
    <div id="content-header">
      <div class="bg-neutral px-4 lg:px-8 py-6">
        <div class="flex items-center justify-between">
          <h1 class="text-neutral-content text-3xl lg:text-[2.5rem] font-light">{@title}</h1>
          <div :if={@actions != []} class="flex items-center gap-3">
            {render_slot(@actions)}
          </div>
        </div>
      </div>
      <nav
        :if={@tabs != []}
        class="bg-neutral-dark flex items-center h-[3.75rem] px-4 lg:px-8 gap-1 overflow-x-auto"
      >
        {render_slot(@tabs)}
      </nav>
    </div>
    """
  end

  @doc """
  Renders a tab link for use inside a `page_header` `:tabs` slot.
  """
  attr :href, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false
  attr :badge, :string, default: nil

  def header_tab(assigns) do
    ~H"""
    <.link
      href={@href}
      class={[
        "flex items-center gap-2 px-4 h-full text-sm font-medium border-b-2 transition-colors whitespace-nowrap",
        if(@active,
          do: "text-neutral-content border-primary",
          else:
            "text-neutral-content/50 border-transparent hover:text-neutral-content hover:border-neutral-content/40"
        )
      ]}
    >
      {@label}
      <span
        :if={@badge}
        class="px-1.5 py-0.5 text-xs bg-primary text-primary-content rounded-full leading-none"
      >
        {@badge}
      </span>
    </.link>
    """
  end

  @doc """
  Renders a breadcrumb / content-navigation bar below the page header.
  """
  slot :inner_block, required: true

  def page_nav(assigns) do
    ~H"""
    <div
      id="content-navigation"
      class="flex items-center justify-between h-14 px-4 lg:px-8 bg-base-200"
    >
      <nav class="flex items-center text-[13px] text-base-content/50 gap-2">
        {render_slot(@inner_block)}
      </nav>
    </div>
    """
  end

  @doc """
  Renders a white card section, matching the Artemis content section style.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def section(assigns) do
    ~H"""
    <div class={["bg-base-100 border border-base-300 rounded p-6 lg:p-8", @class]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Renders a section heading with the signature purple/secondary bottom border.
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def section_title(assigns) do
    ~H"""
    <h2 class={["text-xl font-medium text-base-content pb-4 mb-6 border-b-2 border-secondary", @class]}>
      {render_slot(@inner_block)}
    </h2>
    """
  end

  # -------------------------------------------------------------------
  # Flash messages
  # -------------------------------------------------------------------

  @doc """
  Shows the flash group with standard titles and content.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  defp theme_switcher(assigns) do
    ~H"""
    <div class="relative" id="theme-switcher" phx-hook=".ThemeSwitcher" phx-update="ignore">
      <button
        id="theme-switcher-btn"
        class="p-2 text-base-content/50 hover:text-base-content/80 rounded-md hover:bg-base-200 transition-colors cursor-pointer"
        phx-click={
          JS.toggle(
            to: "#theme-switcher-menu",
            in: {"ease-out duration-150", "opacity-0 scale-95", "opacity-100 scale-100"},
            out: {"ease-in duration-100", "opacity-100 scale-100", "opacity-0 scale-95"}
          )
        }
      >
        <span data-theme-icon="light" class="hidden">
          <.icon name="hero-sun" class="size-5" />
        </span>
        <span data-theme-icon="dark" class="hidden">
          <.icon name="hero-moon" class="size-5" />
        </span>
        <span data-theme-icon="system" class="hidden">
          <.icon name="hero-computer-desktop" class="size-5" />
        </span>
      </button>
      <div
        id="theme-switcher-menu"
        class="hidden absolute right-0 top-full mt-1 w-40 bg-base-100 border border-base-300 rounded-lg shadow-xl z-50 py-1"
      >
        <div class="fixed inset-0 -z-10" phx-click={JS.hide(to: "#theme-switcher-menu")}></div>
        <button
          class="theme-option w-full flex items-center gap-3 px-3 py-2 text-sm text-base-content/70 hover:bg-base-200 hover:text-base-content transition-colors cursor-pointer rounded"
          phx-click={JS.dispatch("phx:set-theme") |> JS.hide(to: "#theme-switcher-menu")}
          data-phx-theme="light"
        >
          <.icon name="hero-sun" class="size-4" /> Light
        </button>
        <button
          class="theme-option w-full flex items-center gap-3 px-3 py-2 text-sm text-base-content/70 hover:bg-base-200 hover:text-base-content transition-colors cursor-pointer rounded"
          phx-click={JS.dispatch("phx:set-theme") |> JS.hide(to: "#theme-switcher-menu")}
          data-phx-theme="dark"
        >
          <.icon name="hero-moon" class="size-4" /> Dark
        </button>
        <button
          class="theme-option w-full flex items-center gap-3 px-3 py-2 text-sm text-base-content/70 hover:bg-base-200 hover:text-base-content transition-colors cursor-pointer rounded"
          phx-click={JS.dispatch("phx:set-theme") |> JS.hide(to: "#theme-switcher-menu")}
          data-phx-theme="system"
        >
          <.icon name="hero-computer-desktop" class="size-4" /> System
        </button>
      </div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".ThemeSwitcher">
      export default {
        mounted() {
          this.updateIcon()
          this.updateActive()
          document.addEventListener("artemis:theme-changed", () => {
            this.updateIcon()
            this.updateActive()
          })
        },
        updateIcon() {
          const saved = localStorage.getItem("phx:theme") || "system"
          this.el.querySelectorAll("[data-theme-icon]").forEach(el => {
            el.classList.toggle("hidden", el.dataset.themeIcon !== saved)
          })
        },
        updateActive() {
          const saved = localStorage.getItem("phx:theme") || "system"
          this.el.querySelectorAll(".theme-option").forEach(el => {
            const isActive = el.dataset.phxTheme === saved
            el.classList.toggle("text-primary", isActive)
            el.classList.toggle("font-medium", isActive)
            el.classList.toggle("text-base-content/70", !isActive)
          })
        }
      }
    </script>
    """
  end

  # -------------------------------------------------------------------
  # Private nav components
  # -------------------------------------------------------------------

  attr :href, :string, required: true
  attr :label, :string, required: true

  defp nav_link(assigns) do
    ~H"""
    <.link
      href={@href}
      class="relative px-5 h-16 flex items-center text-sm font-medium text-base-content/70 hover:text-base-content transition-colors group"
    >
      {@label}
      <span class="nav-link-underline"></span>
    </.link>
    """
  end

  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :title, :string, required: true
  attr :description, :string, required: true
  slot :inner_block, required: true

  defp dropdown_panel(assigns) do
    ~H"""
    <div class="nav-dropdown-group relative flex items-center h-16">
      <button
        phx-click={toggle_dropdown(@id)}
        class="relative px-5 h-16 flex items-center gap-1.5 text-sm font-medium text-base-content/70 hover:text-base-content transition-colors group cursor-pointer"
      >
        {@label}
        <.icon
          name="hero-chevron-down"
          class="size-3 text-base-content/40 group-hover:text-base-content/60 transition-colors"
        />
        <span class="nav-link-underline"></span>
      </button>
      <div
        id={@id}
        class="nav-dropdown-panel fixed left-0 right-0 top-16 bg-base-100 shadow-2xl border-t border-base-300 z-50"
      >
        <div class="nav-dropdown-backdrop fixed inset-0 -z-10" phx-click={hide_dropdowns()}></div>
        <div class="flex px-4 lg:px-8 py-8 gap-8">
          <div class="w-60 shrink-0 border-r border-base-300 pr-8">
            <h3 class="text-lg font-semibold text-base-content mb-2">{@title}</h3>
            <p class="text-[13px] text-base-content/60 leading-relaxed">{@description}</p>
          </div>
          <div class="flex-1">
            {render_slot(@inner_block)}
          </div>
        </div>
        <div class="gradient-stripe h-[3px]"></div>
      </div>
    </div>
    """
  end

  attr :title, :string, required: true
  slot :inner_block, required: true

  defp dropdown_section(assigns) do
    ~H"""
    <div>
      <h5 class="text-sm font-semibold text-base-content mb-2">{@title}</h5>
      <ul class="space-y-1.5">
        {render_slot(@inner_block)}
      </ul>
    </div>
    """
  end

  attr :href, :string, required: true
  attr :label, :string, required: true

  defp dropdown_link(assigns) do
    ~H"""
    <li>
      <.link
        href={@href}
        class="text-sm text-base-content/70 hover:text-primary transition-colors"
      >
        {@label}
      </.link>
    </li>
    """
  end

  # -- Mobile nav helpers --

  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :href, :string, required: true

  defp mobile_nav_section(assigns) do
    ~H"""
    <.link
      href={@href}
      class="flex items-center gap-3 px-3 py-2.5 text-sm font-medium text-base-content/80 rounded-md hover:bg-base-200"
    >
      <.icon name={@icon} class="size-4 text-base-content/40" /> {@label}
    </.link>
    """
  end

  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :id, :string, required: true
  slot :inner_block, required: true

  defp mobile_nav_group(assigns) do
    ~H"""
    <div>
      <button
        class="w-full flex items-center justify-between gap-3 px-3 py-2.5 text-sm font-medium text-base-content/80 rounded-md hover:bg-base-200 cursor-pointer"
        phx-click={JS.toggle(to: "##{@id}")}
      >
        <span class="flex items-center gap-3">
          <.icon name={@icon} class="size-4 text-base-content/40" /> {@label}
        </span>
        <.icon name="hero-chevron-down" class="size-3 text-base-content/40" />
      </button>
      <div id={@id} class="hidden pl-10 pb-1 space-y-0.5">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :href, :string, required: true
  attr :label, :string, required: true

  defp mobile_nav_link(assigns) do
    ~H"""
    <.link
      href={@href}
      class="block px-3 py-2 text-sm text-base-content/60 rounded-md hover:text-base-content hover:bg-base-200"
    >
      {@label}
    </.link>
    """
  end

  # -- JS helpers --

  defp toggle_dropdown(target_id) do
    @dropdown_ids
    |> Enum.reject(&(&1 == target_id))
    |> Enum.reduce(%JS{}, fn id, js -> JS.hide(js, to: "##{id}") end)
    |> JS.toggle(
      to: "##{target_id}",
      in: {"ease-out duration-200", "opacity-0 -translate-y-2", "opacity-100 translate-y-0"},
      out: {"ease-in duration-150", "opacity-100 translate-y-0", "opacity-0 -translate-y-2"}
    )
  end

  defp hide_dropdowns do
    JS.hide(
      to: ".nav-dropdown-panel",
      transition:
        {"ease-in duration-150", "opacity-100 translate-y-0", "opacity-0 -translate-y-2"}
    )
  end
end
