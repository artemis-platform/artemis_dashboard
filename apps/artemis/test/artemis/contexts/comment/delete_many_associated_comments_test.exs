defmodule Artemis.DeleteManyAssociatedCommentsTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.Comment
  alias Artemis.DeleteManyAssociatedComments

  describe "call!" do
    test "raises an exception record on failure" do
      assert_raise Ecto.Query.CastError, fn ->
        DeleteManyAssociatedComments.call!(:invalid_value, Mock.system_user())
      end
    end

    test "succeeds if record has no comments" do
      record = insert(:customer)

      result = DeleteManyAssociatedComments.call!("Customer", record.id, Mock.system_user())

      assert result.total == 0
    end

    test "deletes associated comments when passed valid resource type and resource id" do
      record = insert(:customer)
      comments = insert_list(3, :comment, resource_id: Integer.to_string(record.id), resource_type: "Customer")

      result = DeleteManyAssociatedComments.call!("Customer", record.id, Mock.system_user())

      assert result.total == 3
      assert Repo.get(Comment, hd(comments).id) == nil
    end
  end

  describe "call" do
    test "succeeds if record has no comments" do
      record = insert(:customer)

      {:ok, result} = DeleteManyAssociatedComments.call("Customer", record.id, Mock.system_user())

      assert result.total == 0
    end

    test "deletes associated comments when passed valid resource type and resource id" do
      record = insert(:customer)
      comments = insert_list(3, :comment, resource_id: Integer.to_string(record.id), resource_type: "Customer")

      {:ok, result} = DeleteManyAssociatedComments.call("Customer", record.id, Mock.system_user())

      assert result.total == 3
      assert Repo.get(Comment, hd(comments).id) == nil
    end

    test "succeeds associated comments when passed valid resource type" do
      comments = insert_list(3, :comment, resource_type: "Customer")

      {:ok, result} = DeleteManyAssociatedComments.call("Customer", Mock.system_user())

      assert result.total == 3
      assert Repo.get(Comment, hd(comments).id) == nil
    end
  end
end
