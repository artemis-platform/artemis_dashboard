defmodule Artemis.Factories do
  use ExMachina.Ecto, repo: Artemis.Repo

  # Factories

  def auth_provider_factory do
    %Artemis.AuthProvider{
      data: %{},
      type: Faker.Internet.slug(),
      uid: sequence(:uid, &"#{Faker.Internet.slug()}-#{&1}"),
      user: insert(:user)
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

  def feature_factory do
    %Artemis.Feature{
      active: false,
      name: sequence(:name, &"#{Faker.Name.name()}-#{&1}"),
      slug: sequence(:slug, &"#{Faker.Internet.slug()}-#{&1}")
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
      email: sequence(:slug, &"#{Faker.Internet.email()}-#{&1}"),
      first_name: Faker.Name.first_name(),
      last_name: Faker.Name.last_name(),
      name: sequence(:name, &"#{Faker.Name.name()}-#{&1}")
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
