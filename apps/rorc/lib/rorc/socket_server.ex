defmodule RORC.SocketServer do
  require Logger

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [
      :binary,
      packet: :raw,
      active: false,
      reuseaddr: true
    ])

    Logger.info("Listening on localhost:#{port}")
    receive_loop(socket)
  end

  defp receive_loop(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    Logger.info("INITIALIZING...")
    :gen_tcp.send(client, "<message name='Initialize'><fields><field name='Type'>ThirdParty</field><field name='Version'>1.0</field><field name='PingTimeout'>0</field></fields></message>")
    {:ok, data} = :gen_tcp.recv(client, 0)
    Logger.info("RECEIVED: #{data}")

    :gen_tcp.send(client, "<message name='SignOn'><fields><field name='Cashier'>7</field><field name='Password'>007</field></fields></message>")
    {:ok, data} = :gen_tcp.recv(client, 0)
    Logger.info("RECEIVED: #{data}")

    :gen_tcp.send(client, "<message name='Item'><fields><field name='Code'>4011</field><field name='Weight'>480</field></fields></message>")
    {:ok, data} = :gen_tcp.recv(client, 0)
    Logger.info("RECEIVED: #{data}")

    # The receive loop happens once per connection, so put all your initialization code above this line

    {:ok, pid} = Task.Supervisor.start_child(RORC.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    receive_loop(socket)
  end

  defp serve(socket) do
    socket |> read_data |> Logger.info
    serve(socket)
  end

  defp read_data(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    Logger.info("RECEIVED: #{data}")
    data
  end
end
