# Justine Khoo (jnk20)

defmodule Leader do
  
  defp ballot(self, v) do Map.put(self, :ballot, v) end
  
  defp active(self, v) do Map.put(self, :active, v) end

  defp proposals(self, updated) do Map.put(self, :proposals, updated) end
  defp proposals(self, s, c) do Map.put(self, :proposals, Map.put(self.proposals, s, c)) end

  defp decided(self, s) do Map.put(self, :decided, MapSet.put(self.decided, s)) end

  defp timeout(self, mode) do 
    value = case mode do
      :increase -> min((self.timeout + 1) * self.config.timeout_mult, self.config.max_timeout)
      :decrease -> max(self.timeout - self.config.timeout_decr, 0)
    end
    Map.put(self, :timeout, value) 
  end

  # ----------------------------------------------------------

  def start(config) do
    receive do
      { :BIND, acceptors, replicas } ->
        self = %{
          config: config,  acceptors: acceptors,  replicas: replicas,   ballot: {0, config.node_num},
          active: false,   proposals: Map.new,    timeout: config.init_timeout,
          decided: MapSet.new    # The set of slots that our commanders have gotten a decision on
        }
        spawn(Scout, :start, [self.config, self(), acceptors, self.ballot])
        self |> next()
    end
  end
  
  defp next(self) do
    receive do
      { :DECIDED, slot } ->    # from Commander
        Debug.info(self.config, "proposal accepted", 3)
        self |> decided(slot)
             |> timeout(:decrease)
             |> next()

      { :PROPOSE, slot, cmd } ->    # from Replica
        Debug.info(self.config, "received proposal for slot #{slot}", 3)
        if Map.has_key?(self.proposals, slot) do    
          # Ignore as we have another proposal for the slot. The replica will try proposing this command again eventually
          self |> next()
        else
          if self.active do
            spawn(Commander, :start, [self.config, self(), self.acceptors, self.replicas, { self.ballot, slot, cmd }])
          end
          self |> proposals(slot, cmd) 
               |> next()
        end

      { :ADOPTED, new_ballot, pvalues } ->    # from Scout
        Debug.info(self.config, "ballot #{inspect(new_ballot)} adopted, previous ballot: #{inspect(self.ballot)}", 3)

        # PVALUES: %{slot => {highest ballot, cmd}}, PMAX: %{slot => cmd}
        pmax = for {s, {_, c}} <- pvalues, into: %{} do {s, c} end
        # Maximum accepted pvalues + entries in PROPOSALS not accepted yet
        updated_proposals = Map.merge(self.proposals, pmax)

        for { slot, cmd } <- updated_proposals do
          if not self.config.optimise or slot not in self.decided do
            # Optimisation that prevents spawning commanders for already decided slots
            spawn(Commander, :start, [self.config, self(), self.acceptors, self.replicas, { new_ballot, slot, cmd }])
          end
        end
        self |> active(true) 
             |> proposals(updated_proposals)
             |> next()

      { :PREEMPTED, {round, _} = curr_ballot } ->    # from Scout or Commander
        if curr_ballot > self.ballot do
          Debug.info(self.config, "preempted by #{inspect(curr_ballot)}, my ballot: #{inspect(self.ballot)}, timeout: #{self.timeout}", 2)
          # Sleep to avoid livelock and try again with higher ballot number and increased timeout
          if self.config.timeout_on do Process.sleep(ceil(self.timeout)) end
          new_ballot = { round + 1, self.config.node_num }
          spawn(Scout, :start, [self.config, self(), self.acceptors, new_ballot])
          self |> active(false)
               |> timeout(:increase)
               |> ballot(new_ballot)
               |> next()
        else    # Could happen if another commander for the old ballot preempted first and we've already increased our ballot, ignore
          self |> next()
        end
    end
  end
  
  end