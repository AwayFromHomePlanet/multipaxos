# Justine Khoo (jnk20)

defmodule Scout do

  def start(config, leader, acceptors, ballot) do
    send config.monitor, { :SCOUT_SPAWNED, config.node_num }
    for a <- acceptors do send a, { :P1A, self(), ballot } end
    next(config, leader, ballot, div(length(acceptors), 2), Map.new)
  end
  
  defp next(config, leader, ballot, awaiting, pvalues) do
    receive do
      { :P1B, a_ballot, a_pvalues } ->
        if a_ballot == ballot do
          Debug.info(config, "received p1b for #{inspect(ballot)}, awaiting #{awaiting} more", 3)
          # add acceptor's pvalues to mine, choosing the largest ballot number for each slot
          pvalues = Map.merge(pvalues, a_pvalues, 
                              fn _s, {b1, c1}, {b2, c2} -> 
                                if b1 > b2 do {b1, c1} else {b2, c2} end 
                              end)
          if awaiting == 0 do
            send leader, { :ADOPTED, ballot, pvalues }
            finish(config)
          end
          next(config, leader, ballot, awaiting - 1, pvalues)
        else
          send leader, { :PREEMPTED, a_ballot }
          finish(config)
        end
    end
  end

  defp finish(config) do
    send config.monitor, { :SCOUT_FINISHED, config.node_num }
    Process.exit(self(), :normal)
  end
  
  end