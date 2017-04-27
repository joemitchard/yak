defmodule Graze.WorkerTest do
  use ExUnit.Case 

  test "worker accepts a valid request" do

    Graze.WorkerSupervisor.start_link()

    Graze.Server.start_link([])

    {:ok, worker} = Supervisor.start_child(Graze.WorkerSupervisor, [])

    assert :ok = Graze.Worker.process(worker, "/mirror hello")
  end
end