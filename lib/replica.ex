#  Justine Khoo (jnk20)

defmodule Replica do

  defp inc_slot_in(self) do Map.put(self, :slot_in, self.slot_in + 1) end
  defp inc_slot_out(self) do Map.put(self, :slot_out, self.slot_out + 1) end

  defp add_request(self, c) do Map.put(self, :requests, self.requests ++ [c]) end
  defp requests(self, l) do Map.put(self, :requests, l) end

  defp add_proposal(self, c) do Map.put(self, :proposals, Map.put(self.proposals, self.slot_in, c)) end
  defp del_proposal(self) do Map.put(self, :proposals, Map.delete(self.proposals, self.slot_out)) end

  defp decisions(self, s, c) do Map.put(self, :decisions, Map.put(self.decisions, s, c)) end

  # ----------------------------------------------------------

  def start(config, database) do
    receive do
      { :BIND, leaders } ->
        self = %{
          config: config,  database: database,  slot_in: 1,          slot_out: 1, 
          requests: [],    proposals: Map.new,  decisions: Map.new,  leaders: leaders
        }
        self |> next()
    end
  end
  
  defp next(self) do
    receive do
      { :CLIENT_REQUEST, cmd } ->
        send self.config.monitor, { :CLIENT_REQUEST, self.config.node_num }
        Debug.info(self.config, "received #{inspect(cmd)}", 3)
        self |> add_request(cmd)
             |> propose()
             |> next()

      { :DECISION, slot, cmd } ->
        self |> decisions(slot, cmd)
             |> handle_decisions()
             |> propose()
             |> next()
    end
  end

  defp propose(self) do
    # Take all commands in REQUESTS and add them to PROPOSALS
    case self.requests do
      [] -> self

      [ cmd | tail ] ->
        # Advance SLOT_IN until we get to an undecided slot
        if Map.has_key?(self.decisions, self.slot_in) do
          self |> inc_slot_in()
               |> propose()
        else
          for l <- self.leaders do send l, { :PROPOSE, self.slot_in, cmd } end
          self |> add_proposal(cmd)
               |> inc_slot_in()
               |> requests(tail)
               |> propose()
        end
    end
  end

  defp handle_decisions(self) do
    # While SLOT_OUT is decided, consider decision and increment SLOT_OUT
    case Map.get(self.decisions, self.slot_out) do
      nil -> self

      { client, cid, op } = decided_cmd ->
        # Only execute if this is the first occurrence of this command in DECISIONS
        if Enum.count_until(self.decisions, 
                            fn {s,c} -> c == decided_cmd && s < self.slot_out end, 
                            1) == 0 do
          send self.database, { :EXECUTE, op }
          send client, { :CLIENT_REPLY, cid, :ok }
        end
        case Map.get(self.proposals, self.slot_out) do
          nil ->
            self |> inc_slot_out()
                 |> handle_decisions()
          ^decided_cmd ->    # Our proposal and the decision agree, delete proposal
            self |> del_proposal()
                 |> inc_slot_out()
                 |> handle_decisions()
          proposed_cmd ->    # We proposed a different command for this slot, request command again
            self |> del_proposal()
                 |> add_request(proposed_cmd)
                 |> inc_slot_out()
                 |> handle_decisions()
        end
    end
  end
  
  end