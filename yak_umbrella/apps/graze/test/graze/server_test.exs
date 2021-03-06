defmodule Graze.ServerTest do
  use ExUnit.Case 

  alias Graze.Server

  @valid_command("/mirror hello")
  @invalid_command("/test hello")
  @mirror_result("olleh")

  setup do

    Application.stop(:graze)

    opts = [
      size: 2,
      max_overflow: 1
    ]

    {:ok, server} = Graze.Supervisor.start_link(opts)
    {:ok, %{sever: server}}
  end

  test "init spawns workers", _state do
    workers = Supervisor.which_children(Graze.WorkerSupervisor)
    count = Enum.count(workers)
    assert 2 = count
  end

  test "sends valid command for processing", _state do
    assert :ok = Server.read(make_ref(), @valid_command)
  end

  test "requesting more reads than workers is accepted", _state do
    results = 
      Enum.map(1..10, fn _ -> Task.async(fn -> Server.read(make_ref(), @valid_command) end) end)
      |> Enum.map(&Task.await/1)
    
    assert Enum.all?(results, &(&1 == :ok))
  end

  test "executes :mirror correctly with valid req", _state do
    :ok = Server.read(make_ref(), @valid_command)
    assert_receive {_ref, {:processed, _, @mirror_result}}
  end

  test "executes :mirror correctly with invalid req", _state do
    :ok = Server.read(make_ref(), @invalid_command)
    assert_receive {_ref, {:processed, _, :nocmd}}
  end

  test "queued request get processed", _state do
    :ok = Server.read(r1 = make_ref(), @valid_command)
    :ok = Server.read(r2 = make_ref(), @valid_command)
    :ok = Server.read(r3 = make_ref(), @valid_command)
    :ok = Server.read(r4 = make_ref(), @valid_command)


    assert_receive({_ref, {:processed, ^r1, @mirror_result}})
    assert_receive({_ref, {:processed, ^r2, @mirror_result}})
    assert_receive({_ref, {:processed, ^r3, @mirror_result}})
    assert_receive({_ref, {:processed, ^r4, @mirror_result}})
  end

end