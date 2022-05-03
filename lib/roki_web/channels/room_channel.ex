defmodule RokiWeb.RoomChannel do
  use RokiWeb, :channel
  alias RokiWeb.Presence
  alias Roki.Accounts

  @impl true
  def join("room:lobby", payload, socket) do
    if authorized?(payload) do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    user = Accounts.get_user!(socket.assigns.current_user_id)

    {:ok, _} =
      Presence.track(socket, user.id, %{
        email: user.email,
        online_at: inspect(System.system_time(:second))
      })

    push(socket, "presence_state", Presence.list(socket))

    socket =
      socket
      |> assign(:current_user_email, user.email)

    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (room:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  def handle_in("new_msg", %{"body" => body}, socket) do
    payload = %{body: body, email: socket.assigns.current_user_email}
    broadcast!(socket, "new_msg", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end