# Justine Khoo (jnk20)

defmodule Commander do

  def start(config, leader, acceptors, replicas, pvalue) do
    send config.monitor, { :COMMANDER_SPAWNED, config.node_num }
    for a <- acceptors do send a, { :P2A, self(), pvalue } end
    next(config, leader, replicas, pvalue, div(length(acceptors), 2))
  end
  
  defp next(config, leader, replicas, { ballot, slot, cmd } = pvalue, awaiting) do
    receive do
      { :P2B, a_ballot } ->
        cond do
          a_ballot == ballot ->
            if awaiting == 0 do    # Received responses from a majority of acceptors
              Debug.info(config, "decided #{inspect(cmd)} for slot #{slot}", 3)
              send leader, { :DECIDED, slot }    # To decrease leader's timeout and prevent spawning unnecessary commanders in the future
              for r <- replicas do send r, { :DECISION, slot, cmd } end
              finish(config)
            end
            next(config, leader, replicas, pvalue, awaiting - 1)
          a_ballot > ballot ->    # A higher ballot number is currently active, no more progress can be made
            send leader, { :PREEMPTED, a_ballot }
            finish(config)
          a_ballot < ballot ->    # Could happen if p2a delivered before p1a, ignore. Guaranteed to be at most a minority of acceptors
            next(config, leader, replicas, pvalue, awaiting)
        end
    end
  end

  defp finish(config) do
    send config.monitor, { :COMMANDER_FINISHED, config.node_num }
    Process.exit(self(), :normal)
  end

  end