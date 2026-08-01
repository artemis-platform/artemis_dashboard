defmodule ArtemisWeb.ComponentsLive do
  use ArtemisWeb, :live_view

  # -------------------------------------------------------------------
  # Stub data
  # -------------------------------------------------------------------

  @stub_users [
    %{
      id: 1,
      name: "Sarah Chen",
      email: "sarah.chen@example.com",
      role: "Admin",
      status: "normal"
    },
    %{id: 2, name: "Mike Ross", email: "mike.ross@example.com", role: "Editor", status: "normal"},
    %{
      id: 3,
      name: "Ana García",
      email: "ana.garcia@example.com",
      role: "Viewer",
      status: "acknowledged"
    },
    %{
      id: 4,
      name: "James Wright",
      email: "james.wright@example.com",
      role: "Admin",
      status: "normal"
    },
    %{
      id: 5,
      name: "Priya Patel",
      email: "priya.patel@example.com",
      role: "Editor",
      status: "triggered"
    }
  ]

  # -------------------------------------------------------------------
  # LiveView callbacks
  # -------------------------------------------------------------------

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Components",
       users: @stub_users,
       deleted_ids: MapSet.new()
     )}
  end

  @impl true
  def handle_event("delete-user", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)

    socket =
      socket
      |> update(:deleted_ids, &MapSet.put(&1, id))
      |> update(:users, fn users -> Enum.reject(users, &(&1.id == id)) end)
      |> put_flash(:info, "User ##{id} deleted successfully.")

    {:noreply, socket}
  end

  # -------------------------------------------------------------------
  # Template
  # -------------------------------------------------------------------

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <Layouts.page_header title="Components">
        <:tabs>
          <Layouts.header_tab href="/components" label="Overview" active />
        </:tabs>
      </Layouts.page_header>

      <Layouts.page_nav>
        <ArtemisWeb.Breadcrumbs.breadcrumbs request_path="/components" />
      </Layouts.page_nav>

      <div id="content" class="p-4 lg:p-8 space-y-8">
        <%!-- Delete confirmation --%>
        <section>
          <.heading level={2} class="mb-4">Delete Confirmation</.heading>

          <Layouts.section>
            <p class="text-sm text-base-content/70 mb-4">
              Click any delete button below to see the confirmation modal. Confirming will remove the user from the list with a flash notification.
            </p>

            <div class="overflow-x-auto rounded-lg border border-base-300">
              <table class="table table-sm w-full">
                <thead>
                  <tr class="bg-base-200/50 border-b border-base-300">
                    <th class="text-xs font-semibold uppercase tracking-wider text-base-content/60 py-3 px-4">
                      User
                    </th>
                    <th class="text-xs font-semibold uppercase tracking-wider text-base-content/60 py-3 px-4">
                      Email
                    </th>
                    <th class="text-xs font-semibold uppercase tracking-wider text-base-content/60 py-3 px-4">
                      Role
                    </th>
                    <th class="text-xs font-semibold uppercase tracking-wider text-base-content/60 py-3 px-4">
                      Status
                    </th>
                    <th class="text-xs font-semibold uppercase tracking-wider text-base-content/60 py-3 px-4">
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <%= if @users == [] do %>
                    <tr>
                      <td colspan="5" class="text-center py-8 text-base-content/50 text-sm">
                        All users deleted. Refresh the page to reset.
                      </td>
                    </tr>
                  <% end %>
                  <tr
                    :for={user <- @users}
                    class="hover:bg-base-200/30 border-b border-base-300 last:border-b-0 transition-colors"
                  >
                    <td class="py-3 px-4">
                      <div class="flex items-center gap-3">
                        <.user_avatar name={user.name} size="sm" />
                        <span class="text-sm font-medium">{user.name}</span>
                      </div>
                    </td>
                    <td class="py-3 px-4 text-sm text-base-content/70">{user.email}</td>
                    <td class="py-3 px-4">
                      <.status_label value={user.role} color={role_color(user.role)} />
                    </td>
                    <td class="py-3 px-4">
                      <span class="inline-flex items-center gap-1.5 text-sm">
                        <.status_dot value={user.status} />
                        <span class="capitalize">{user.status}</span>
                      </span>
                    </td>
                    <td class="py-3 px-4 text-right">
                      <.delete_confirmation
                        id={"delete-user-#{user.id}"}
                        on_confirm={JS.push("delete-user", value: %{id: user.id})}
                        message={"Are you sure you want to delete #{user.name}? This action cannot be undone."}
                      />
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </Layouts.section>
        </section>

        <%!-- Notifications --%>
        <section>
          <.heading level={2} class="mb-4">Notifications</.heading>
          <div class="space-y-3">
            <.notification kind={:info} header="Information">
              This is an informational notification.
            </.notification>
            <.notification kind={:success} header="Success">
              Operation completed successfully.
            </.notification>
            <.notification kind={:warning}>
              Background jobs are experiencing delays.
            </.notification>
            <.notification kind={:error} header="Error">
              Something went wrong. Please try again.
            </.notification>
          </div>
        </section>

        <%!-- Status indicators --%>
        <section>
          <.heading level={2} class="mb-4">Status Indicators</.heading>
          <Layouts.section>
            <div class="flex flex-wrap gap-6">
              <div class="space-y-3">
                <.heading level={5}>Status Dots</.heading>
                <div class="flex items-center gap-4">
                  <span class="inline-flex items-center gap-1.5 text-sm">
                    <.status_dot value="normal" /> Normal
                  </span>
                  <span class="inline-flex items-center gap-1.5 text-sm">
                    <.status_dot value="acknowledged" /> Acknowledged
                  </span>
                  <span class="inline-flex items-center gap-1.5 text-sm">
                    <.status_dot value="triggered" /> Triggered
                  </span>
                  <span class="inline-flex items-center gap-1.5 text-sm">
                    <.status_dot value="gray" /> Unknown
                  </span>
                </div>
                <div class="flex items-center gap-4 mt-2">
                  <span class="inline-flex items-center gap-1.5 text-sm">
                    <.status_dot value="normal" size="xs" /> XS
                  </span>
                  <span class="inline-flex items-center gap-1.5 text-sm">
                    <.status_dot value="normal" size="sm" /> SM
                  </span>
                  <span class="inline-flex items-center gap-1.5 text-sm">
                    <.status_dot value="normal" size="md" /> MD
                  </span>
                  <span class="inline-flex items-center gap-1.5 text-sm">
                    <.status_dot value="normal" size="lg" /> LG
                  </span>
                </div>
              </div>
              <div class="space-y-3">
                <.heading level={5}>Status Labels</.heading>
                <div class="flex flex-wrap items-center gap-2">
                  <.status_label value="Normal" />
                  <.status_label value="Acknowledged" />
                  <.status_label value="Triggered" />
                  <.status_label value="Info" />
                  <.status_label value="Unknown" />
                </div>
              </div>
            </div>
          </Layouts.section>
        </section>

        <%!-- User avatars --%>
        <section>
          <.heading level={2} class="mb-4">User Avatars</.heading>
          <Layouts.section>
            <div class="flex items-end gap-4">
              <.user_avatar name="Sarah Chen" size="xs" />
              <.user_avatar name="Mike Ross" size="sm" />
              <.user_avatar name="Ana García" size="md" />
              <.user_avatar name="James Wright" size="lg" />
              <.user_avatar name="Priya Patel" size="xl" />
            </div>
          </Layouts.section>
        </section>

        <%!-- Key-value list --%>
        <section>
          <.heading level={2} class="mb-4">Key-Value List</.heading>
          <Layouts.section>
            <.key_value_list>
              <:item label="Name">Sarah Chen</:item>
              <:item label="Email">sarah.chen@example.com</:item>
              <:item label="Role"><.status_label value="Admin" color="info" /></:item>
              <:item label="Status">
                <span class="inline-flex items-center gap-1.5">
                  <.status_dot value="normal" /> Active
                </span>
              </:item>
              <:item label="Clouds">3</:item>
            </.key_value_list>
          </Layouts.section>
        </section>

        <%!-- Breadcrumbs --%>
        <section>
          <.heading level={2} class="mb-4">Breadcrumbs</.heading>
          <Layouts.section>
            <div class="space-y-4">
              <div>
                <p class="text-xs text-base-content/50 mb-1">Auto-generated from path</p>
                <ArtemisWeb.Breadcrumbs.breadcrumbs request_path="/clouds/123/machines" />
              </div>
              <div>
                <p class="text-xs text-base-content/50 mb-1">Explicit items</p>
                <ArtemisWeb.Breadcrumbs.breadcrumbs>
                  <:item href="/">Home</:item>
                  <:item href="/users">Users</:item>
                  <:item>Sarah Chen</:item>
                </ArtemisWeb.Breadcrumbs.breadcrumbs>
              </div>
            </div>
          </Layouts.section>
        </section>

        <%!-- Headings --%>
        <section>
          <.heading level={2} class="mb-4">Headings</.heading>
          <Layouts.section>
            <div class="space-y-3">
              <.heading level={2}>Heading Level 2</.heading>
              <.heading level={3}>Heading Level 3</.heading>
              <.heading level={4}>Heading Level 4</.heading>
              <.heading level={5}>Heading Level 5</.heading>
            </div>
          </Layouts.section>
        </section>

        <%!-- Number formatting --%>
        <section>
          <.heading level={2} class="mb-4">Number Formatting</.heading>
          <Layouts.section>
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr class="bg-base-200/50">
                    <th class="text-xs uppercase">Value</th>
                    <th class="text-xs uppercase">pretty_print_number</th>
                    <th class="text-xs uppercase">number_sign</th>
                    <th class="text-xs uppercase">number_sign_symbol</th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={val <- [1_234_567, -42, 0, 99.5]}>
                    <td class="font-mono text-sm">{val}</td>
                    <td class="font-mono text-sm">{pretty_print_number(val)}</td>
                    <td class="text-sm">{number_sign(val)}</td>
                    <td class="font-mono text-sm">{number_sign_symbol(val)}{abs(val)}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </Layouts.section>
        </section>
      </div>
    </Layouts.app>
    """
  end

  # -------------------------------------------------------------------
  # Private helpers
  # -------------------------------------------------------------------

  defp role_color("Admin"), do: "info"
  defp role_color("Editor"), do: "warning"
  defp role_color(_), do: "neutral"
end
