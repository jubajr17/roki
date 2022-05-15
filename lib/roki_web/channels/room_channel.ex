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
    user = Accounts.get_user!(socket.assigns.user_id)

    {:ok, _} =
      Presence.track(socket, user.id, %{
        email: user.email,
        online_at: inspect(System.system_time(:second))
      })

    push(socket, "presence_state", Presence.list(socket))

    socket =
      socket
      |> assign(:user_email, user.email)
      |> assign(:user_color, random_user_color(user.email))

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
    if String.trim(body) != "" do
      payload = %{
        body: body,
        email: socket.assigns.user_email,
        color: socket.assigns.user_color
      }

      broadcast!(socket, "new_msg", payload)
    end

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  @available_hex_color_values ~w(6 7 8 9 A B C D E F)
  defp random_user_color(s) do
    c =
      :crypto.hash(:md5, s)
      |> Base.encode16()
      |> String.graphemes()
      |> Enum.filter(&(&1 in @available_hex_color_values))
      |> Enum.take(3)
      |> Enum.join()

    "##{c}"
  end
end
