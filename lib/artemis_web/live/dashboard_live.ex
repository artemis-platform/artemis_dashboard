defmodule ArtemisWeb.DashboardLive do
  use ArtemisWeb, :live_view

  @summary_counts [
    %{label: "Customers", count: 24, href: "/customers", icon: "hero-building-office"},
    %{label: "Clouds", count: 8, href: "/clouds", icon: "hero-cloud"},
    %{label: "Data Centers", count: 12, href: "/data-centers", icon: "hero-server-stack"},
    %{label: "Machines", count: 156, href: "/machines", icon: "hero-cpu-chip"},
    %{label: "Users", count: 42, href: "/users", icon: "hero-users"}
  ]

  @recent_events [
    %{action: "User login", user: "Sarah Chen", timestamp: "2 minutes ago", type: :info},
    %{action: "Cloud updated", user: "Mike Ross", timestamp: "15 minutes ago", type: :info},
    %{action: "Incident resolved", user: "Sarah Chen", timestamp: "1 hour ago", type: :success},
    %{action: "New machine provisioned", user: "System", timestamp: "2 hours ago", type: :info},
    %{action: "Permission updated", user: "Admin", timestamp: "3 hours ago", type: :warning},
    %{action: "Data center synced", user: "System", timestamp: "4 hours ago", type: :info},
    %{action: "Role created", user: "Admin", timestamp: "5 hours ago", type: :info}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Dashboard",
       summary_counts: @summary_counts,
       recent_events: @recent_events
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.page_header title="Dashboard">
      <:tabs>
        <Layouts.header_tab href="/" label="Overview" active />
        <Layouts.header_tab href="#" label="Event Logs" />
      </:tabs>
    </Layouts.page_header>

    <Layouts.page_nav>
      <.link href="/" class="text-base-content/40 hover:text-base-content/70 transition-colors">
        <.icon name="hero-home-solid" class="size-4" />
      </.link>
      <span class="text-base-content/30">/</span>
      <span class="text-base-content/70 font-medium">Dashboard</span>
    </Layouts.page_nav>

    <div id="content" class="p-4 lg:p-8">
      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4 lg:gap-6 mb-8">
        <.link
          :for={item <- @summary_counts}
          href={item.href}
          class="bg-base-100 border border-base-300 rounded p-6 hover:border-primary hover:shadow-sm transition-all group"
        >
          <div class="flex items-center gap-3 mb-3">
            <.icon
              name={item.icon}
              class="size-5 text-base-content/40 group-hover:text-primary transition-colors"
            />
          </div>
          <div class="text-3xl font-light text-base-content">{item.count}</div>
          <div class="text-sm text-base-content/60 mt-1">{item.label}</div>
        </.link>
      </div>

      <div class="flex flex-col lg:flex-row gap-6">
        <div class="flex-1 space-y-6">
          <Layouts.section>
            <Layouts.section_title>Recent Activity</Layouts.section_title>
            <ul class="space-y-0">
              <li
                :for={event <- @recent_events}
                class="flex items-center gap-4 py-3 border-b border-base-200 last:border-0"
              >
                <div class={[
                  "size-2 rounded-full shrink-0",
                  event.type == :success && "bg-success",
                  event.type == :warning && "bg-warning",
                  event.type == :info && "bg-info"
                ]}>
                </div>
                <div class="flex-1 min-w-0">
                  <span class="text-sm text-base-content">{event.action}</span>
                  <span class="text-sm text-base-content/60"> by     {event.user}</span>
                </div>
                <span class="text-xs text-base-content/40 shrink-0">{event.timestamp}</span>
              </li>
            </ul>
          </Layouts.section>
        </div>

        <aside class="w-full lg:w-80 xl:w-96 space-y-6 shrink-0">
          <Layouts.section>
            <Layouts.section_title>System Status</Layouts.section_title>
            <ul class="space-y-4">
              <.status_row label="API Services" status="Operational" level={:ok} />
              <.status_row label="Database" status="Operational" level={:ok} />
              <.status_row label="Background Jobs" status="Degraded" level={:warning} />
              <.status_row label="CDN" status="Operational" level={:ok} />
            </ul>
          </Layouts.section>

          <Layouts.section>
            <Layouts.section_title>Quick Links</Layouts.section_title>
            <ul class="space-y-2">
              <li>
                <a
                  href="#"
                  class="flex items-center gap-2 text-sm text-primary hover:text-accent transition-colors py-1"
                >
                  <.icon name="hero-plus" class="size-4" /> Create New Customer
                </a>
              </li>
              <li>
                <a
                  href="#"
                  class="flex items-center gap-2 text-sm text-primary hover:text-accent transition-colors py-1"
                >
                  <.icon name="hero-plus" class="size-4" /> Add Cloud
                </a>
              </li>
              <li>
                <a
                  href="#"
                  class="flex items-center gap-2 text-sm text-primary hover:text-accent transition-colors py-1"
                >
                  <.icon name="hero-document-text" class="size-4" /> View Event Logs
                </a>
              </li>
              <li>
                <a
                  href="#"
                  class="flex items-center gap-2 text-sm text-primary hover:text-accent transition-colors py-1"
                >
                  <.icon name="hero-user-group" class="size-4" /> Manage Users
                </a>
              </li>
            </ul>
          </Layouts.section>
        </aside>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :status, :string, required: true
  attr :level, :atom, values: [:ok, :warning, :error]

  defp status_row(assigns) do
    ~H"""
    <li class="flex items-center justify-between">
      <span class="text-sm text-base-content/80">{@label}</span>
      <span class={[
        "inline-flex items-center gap-1.5 text-xs font-medium px-2.5 py-1 rounded-full",
        @level == :ok && "text-success bg-success/10",
        @level == :warning && "text-warning bg-warning/10",
        @level == :error && "text-error bg-error/10"
      ]}>
        <span class={[
          "size-1.5 rounded-full",
          @level == :ok && "bg-success",
          @level == :warning && "bg-warning",
          @level == :error && "bg-error"
        ]}>
        </span>
        {@status}
      </span>
    </li>
    """
  end
end
