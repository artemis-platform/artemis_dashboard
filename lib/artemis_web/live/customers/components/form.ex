defmodule ArtemisWeb.CustomersLive.Components.Form do
  @moduledoc """
  Form component
  """
  use ArtemisWeb, :html

  def form(assigns \\ %{}) do
    ~H"""
    <DynamicForm.form id="customers-form" data={assigns[:data] || %{}}>
      <:field type="text" name="name" label="Name" required />
    </DynamicForm.form>
    """
  end
end
