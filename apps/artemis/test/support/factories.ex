defmodule Artemis.Factories do
  use ExMachina.Ecto, repo: Artemis.Repo
  use Artemis.FactoryStrategy.CloudantInsert

  # Factories

  def auth_provider_factory do
    %Artemis.AuthProvider{
      data: %{},
      type: Faker.Internet.slug(),
      uid: sequence(:uid, &"#{Faker.Internet.slug()}-#{&1}"),
      user: insert(:user)
    }
  end

  def cloud_factory do
    %Artemis.Cloud{
      customer: build(:customer),
      name: sequence(:name, &"#{Faker.Company.name()}-#{&1}"),
      slug: sequence(:slug, &"#{Faker.Internet.slug()}-#{&1}"),
      machines: build_list(3, :machine)
    }
  end

  def comment_factory do
    body = Faker.Lorem.paragraph()

    %Artemis.Comment{
      body: body,
      body_html: body,
      topic: Faker.Name.name(),
      title: sequence(:title, &"#{Faker.Name.name()}-#{&1}"),
      user: insert(:user)
    }
  end

  def customer_factory do
    notes = Faker.Lorem.paragraph()

    %Artemis.Customer{
      name: sequence(:name, &"#{Faker.Company.name()}-#{&1}"),
      notes: notes,
      notes_html: notes
    }
  end

  def data_center_factory do
    country = Faker.Address.country()

    %Artemis.DataCenter{
      country: sequence(:name, &"#{country}#{&1}"),
      latitude: Faker.Address.latitude() |> Float.to_string(),
      longitude: Faker.Address.longitude() |> Float.to_string(),
      name: sequence(:name, &"#{country}#{&1}"),
      slug: sequence(:slug, &"#{Faker.Address.country_code()}#{&1}")
    }
  end

  def feature_factory do
    %Artemis.Feature{
      active: false,
      name: sequence(:name, &"#{Faker.Name.name()}-#{&1}"),
      slug: sequence(:slug, &"#{Faker.Internet.slug()}-#{&1}")
    }
  end

  def incident_factory do
    resolved_at = DateTime.truncate(DateTime.utc_now(), :second)
    acknowledged_at = DateTime.add(resolved_at, :rand.uniform(3600 * 24 * 14) * -1)
    triggered_at = DateTime.add(acknowledged_at, :rand.uniform(3600 * 24 * 14) * -1)

    %Artemis.Incident{
      acknowledged_at: acknowledged_at,
      acknowledged_by: Faker.Name.name(),
      description: Faker.Lorem.paragraph(),
      meta: %{},
      resolved_at: resolved_at,
      resolved_by: Faker.Name.name(),
      service_id: Faker.UUID.v4(),
      service_name: Faker.Name.name(),
      severity: "sev-#{:rand.uniform(3)}",
      source: "pagerduty",
      source_uid: String.slice(Faker.UUID.v4(), 0, 8),
      status: Enum.random(Artemis.Incident.allowed_statuses()),
      team_id: Faker.UUID.v4(),
      team_name: Faker.Name.name(),
      time_to_acknowledge: DateTime.diff(acknowledged_at, triggered_at),
      time_to_resolve: DateTime.diff(resolved_at, triggered_at),
      title: Faker.Lorem.sentence(),
      triggered_at: triggered_at,
      triggered_by: Faker.Name.name()
    }
  end

  def job_factory do
    %Artemis.Job{
      _id: Faker.UUID.v4(),
      _rev: sequence(:slug, &"#{&1}-#{Faker.UUID.v4()}"),
      completed_at: DateTime.utc_now() |> DateTime.to_unix(),
      inserted_at: DateTime.utc_now() |> DateTime.to_unix(),
      name: Faker.Name.name(),
      started_at: DateTime.utc_now() |> DateTime.to_unix(),
      status: Enum.random(["Queued", "Running", "Completed", "Error"]),
      type: Enum.random(["Provision Machine", "Remove Machine"]),
      updated_at: DateTime.utc_now() |> DateTime.to_unix(),
      uuid: Faker.UUID.v4()
    }
  end

  def machine_factory do
    domain_name = sequence(:name, &"#{&1}.#{Faker.Internet.domain_name()}")
    name = Enum.random(["Compute Server", "Management Server", "Backup Server", "Storage Server"])

    %Artemis.Machine{
      cpu_total: Enum.random([1, 2, 4, 8, 16]),
      cpu_used: Enum.random(Range.new(0, 16)),
      hostname: domain_name,
      name: sequence(:name, &"#{name}-#{&1}"),
      slug: domain_name,
      data_center: build(:data_center),
      ram_total: Enum.random([1, 2, 4, 8, 16, 32, 64, 128, 256]),
      ram_used: Enum.random(Range.new(0, 256))
    }
  end

  def permission_factory do
    %Artemis.Permission{
      name: sequence(:name, &"#{Faker.Name.name()}-#{&1}"),
      slug: sequence(:slug, &"#{Faker.Internet.slug()}-#{&1}")
    }
  end

  def role_factory do
    %Artemis.Role{
      name: sequence(:name, &"#{Faker.Name.name()}-#{&1}"),
      slug: sequence(:slug, &"#{Faker.Internet.slug()}-#{&1}")
    }
  end

  def system_task_factory do
    %Artemis.SystemTask{
      extra_params: %{
        "reason" => "Testing"
      },
      type: Enum.random(Artemis.SystemTask.allowed_system_tasks()).type
    }
  end

  def tag_factory do
    %Artemis.Tag{
      description: Faker.Lorem.paragraph(),
      name: sequence(:name, &"#{Faker.Name.name()}-#{&1}"),
      slug: sequence(:slug, &"#{Faker.Internet.slug()}-#{&1}"),
      type: sequence(:type, &"#{Faker.Internet.slug()}-#{&1}")
    }
  end

  def user_factory do
    %Artemis.User{
      email: sequence(:email, &"#{Faker.Internet.email()}-#{&1}"),
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      name: sequence(:name, &"#{Faker.Name.name()}-#{&1}"),
      username: sequence(:username, &"#{Faker.Name.last_name()}-#{&1}")
    }
  end

  def user_role_factory do
    %Artemis.UserRole{
      created_by: insert(:user),
      role: insert(:role),
      user: insert(:user)
    }
  end

  def wiki_page_factory do
    %Artemis.WikiPage{
      body: Faker.Lorem.paragraph(),
      section: Faker.Name.name(),
      slug: sequence(:slug, &"#{Faker.Internet.slug()}-#{&1}"),
      title: sequence(:title, &"#{Faker.Name.name()}-#{&1}"),
      user: insert(:user),
      weight: :rand.uniform(100)
    }
  end

  def wiki_revision_factory do
    %Artemis.WikiRevision{
      body: Faker.Lorem.paragraph(),
      section: Faker.Name.name(),
      slug: sequence(:slug, &"#{Faker.Internet.slug()}-#{&1}"),
      title: sequence(:title, &"#{Faker.Name.name()}-#{&1}"),
      user: insert(:user),
      weight: :rand.uniform(100),
      wiki_page: insert(:wiki_page)
    }
  end

  # Traits

  def with_auth_providers(%Artemis.User{} = user, number \\ 3) do
    insert_list(number, :auth_provider, user: user)
    user
  end

  def with_comments(%Artemis.User{} = user, number \\ 3) do
    insert_list(number, :comment, user: user)
    user
  end

  def with_permission(%Artemis.User{} = user, slug) do
    permission = Artemis.Repo.get_by(Artemis.Permission, slug: slug) || insert(:permission, slug: slug)
    role = insert(:role, permissions: [permission])
    insert(:user_role, role: role, user: user)
    user
  end

  def with_permissions(%Artemis.Role{} = role, number \\ 3) do
    insert_list(number, :permission, roles: [role])
    role
  end

  def with_roles(%Artemis.Permission{} = permission, number \\ 3) do
    insert_list(number, :role, permissions: [permission])
    permission
  end

  def with_user_roles(_record, number \\ 3)

  def with_user_roles(%Artemis.Role{} = role, number) do
    insert_list(number, :user_role, role: role)
    role
  end

  def with_user_roles(%Artemis.User{} = user, number) do
    insert_list(number, :user_role, user: user)
    user
  end

  def with_wiki_page(%Artemis.Comment{} = comment) do
    insert(:wiki_page, comments: [comment])
    comment
  end

  def with_wiki_page(%Artemis.Tag{} = tag) do
    insert(:wiki_page, tags: [tag])
    tag
  end

  def with_wiki_pages(%Artemis.User{} = user, number \\ 3) do
    insert_list(number, :wiki_page, user: user)
    user
  end

  def with_wiki_revisions(%Artemis.User{} = user, number \\ 3) do
    insert_list(number, :wiki_revision, user: user)
    user
  end
end
