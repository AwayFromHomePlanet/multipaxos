# distributed algorithms, n.dulay, 31 jan 2023
# coursework, paxos made moderately complex

defmodule Configuration do

def node_init do
  # get node arguments and spawn a process to exit node after max_time
  config = %{
    node_suffix:    Enum.at(System.argv, 0),
    timelimit:      String.to_integer(Enum.at(System.argv, 1)),
    debug_level:    String.to_integer(Enum.at(System.argv, 2)),
    n_servers:      String.to_integer(Enum.at(System.argv, 3)),
    n_clients:      String.to_integer(Enum.at(System.argv, 4)),
    param_setup:    :'#{Enum.at(System.argv, 5)}',
    start_function: :'#{Enum.at(System.argv, 6)}',
  }

  spawn(Helper, :node_exit_after, [config.timelimit])
  config |> Map.merge(Configuration.params(config.param_setup))
end # node_init

def node_info(config, node_type, node_num \\ "") do
  Map.merge config,
  %{
    node_type:      node_type,
    node_num:       node_num,
    node_name:      "#{node_type}#{node_num}",
    node_location:  Helper.node_string(),
    line_num:       0,  # for ordering output lines
  }
end # node_info

# -----------------------------------------------------------------------------

def params(:default) do
  %{
  max_requests:  500,           # max requests each client will make
  client_sleep:  2,             # time (ms) to sleep before sending new request
  client_stop:   15_000,        # time (ms) to stop sending further requests
  send_policy:	 :round_robin,  # :round_robin, :quorum or :broadcast

  n_accounts:    10,            # number of active bank accounts (init balance=0)
  max_amount:    1_000,         # max amount moved between accounts

  print_after:   1_000,         # print summary every print_after msecs (monitor)

  window_size:   10,            # multi-paxos window size
  
  crash_servers: %{             # server_num => crash_after_time(ms)
  },

  init_timeout:  10,            # initial wait time (ms) after being preempted before trying again
  timeout_mult:  2,           # multiplier applied to timeout after each preempt
  timeout_decr:  2              # amount timeout is decreased after each successful proposal

  # redact: performance/liveness/distribution parameters
  }
end # params :default

# -----------------------------------------------------------------------------

def params(:small) do
  Map.merge (params :default),
  %{
  max_requests: 5
  }
end

def params(:quorum) do
  Map.merge (params :default),
  %{
  send_policy: :quorum
  }
end

def params(:broadcast) do
  Map.merge (params :default),
  %{
  send_policy: :broadcast
  }
end

def params(:qs) do
  Map.merge (params :small),
  %{
  send_policy: :quorum
  }
end

def params(:crash3) do
  Map.merge (params :default),
  %{
  # max_requests: 100,
  crash_servers: %{            # %{ server_num => crash_after_time, ...}
    3 => 1_500,
    5 => 2_500,
    6 => 5_000
    },
  }
end

def params(:qc) do
  Map.merge (params :crash3),
  %{
  send_policy: :quorum
  }
end

def params(:lqc) do
  Map.merge (params :qc),
  %{
    max_requests: 3000,
    timelimit: 60000,
    client_stop: 60000
  }
end

def params(:large) do         
  Map.merge (params :default),
  %{
    max_requests: 2000,
    timelimit: 60000,
    client_stop: 60000
  }
end

# redact params functions...

end # Configuration ----------------------------------------------------------------


