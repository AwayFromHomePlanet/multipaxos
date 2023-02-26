# Justine Khoo (jnk20)

defmodule Acceptor do

def start(config) do
  next(config, {-1, 0}, Map.new)
end

# accepted stores the latest {ballot, command} pair for each slot
defp next(config, my_ballot, accepted) do
  receive do
    { :P1A, scout, ballot } ->
      my_ballot = max(ballot, my_ballot)
      send scout, { :P1B, my_ballot, accepted }
      next(config, my_ballot, accepted)

    { :P2A, commander, { ballot, slot, cmd } } ->
      send commander, { :P2B, my_ballot }
      if ballot == my_ballot do
        next(config, my_ballot, Map.put(accepted, slot, { ballot, cmd }))
      else
        next(config, my_ballot, accepted)
      end
  end
end

end