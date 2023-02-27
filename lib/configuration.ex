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

  config = Map.merge(config, Configuration.params(config.param_setup))
  spawn(Helper, :node_exit_after, [config.timelimit])
  config
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

  print_after:   2_000,         # print summary every print_after msecs (monitor)

  window_size:   10,            # multi-paxos window size
  
  crash_servers: %{             # server_num => crash_after_time(ms)
  },

  init_timeout:  10,            # initial wait time (ms) after being preempted before trying again
  timeout_mult:  2,             # multiplier applied to timeout after each preempt
  timeout_decr:  2,             # amount timeout is decreased after each successful proposal
  max_timeout:   :infinity,     # maximum time a leader can sleep
  timeout_on:    true,          # toggles whether leaders sleep, switching to false could result in livelock

  optimise:      true           # true prevents leaders spawning commanders for decided slots

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

def params(:large) do         
  Map.merge (params :default),
  %{
    max_requests: 10000,
    timelimit: 100000,
    print_after: 2000
  }
end

def params(:crash3) do
  Map.merge (params :default),
  %{
  n_servers: 7,
  crash_servers: %{            # %{ server_num => crash_after_time, ...}
    3 => 1_500,
    5 => 2_500,
    6 => 500
    },
  }
end

def params(:crash_majority_quorum) do
  Map.merge (params :default),
  %{
  send_policy: :quorum,
  n_servers: 7,
  crash_servers: %{
    1 => 1_000,
    3 => 1_500,
    5 => 2_500,
    6 => 500
    },
  }
end


def params(:quorum) do 
  Map.merge(params(:default), %{ send_policy: :quorum })
end
def params(:quorum_crash) do
  Map.merge(params(:crash3), %{ send_policy: :quorum })
end
def params(:broadcast) do 
  Map.merge(params(:default), %{ send_policy: :broadcast })
end
def params(:broadcast_crash) do
  Map.merge(params(:crash3), %{ send_policy: :broadcast })
end


def params(:request_1000) do 
  Map.merge(params(:default), %{ max_requests: 1000, timelimit: 10000 })
end
def params(:request_1500) do 
  Map.merge(params(:default), %{ max_requests: 1500, timelimit: 15000 })
end
def params(:request_2000) do 
  Map.merge(params(:default), %{ max_requests: 2000, timelimit: 20000 })
end
def params(:request_2500) do 
  Map.merge(params(:default), %{ max_requests: 2500, timelimit: 30000 })
end
def params(:request_3000) do 
  Map.merge(params(:default), %{ max_requests: 3000, timelimit: 40000 })
end
def params(:request_3500) do 
  Map.merge(params(:default), %{ max_requests: 3500, timelimit: 50000 })
end
def params(:request_4000) do 
  Map.merge(params(:default), %{ max_requests: 4000, timelimit: 60000 })
end


def params(:mult15) do
  Map.merge(params(:default), %{ timeout_mult: 1.5 })
end
def params(:mult12) do
  Map.merge(params(:default), %{ timeout_mult: 1.2 })
end
def params(:mult11) do
  Map.merge(params(:default), %{ timeout_mult: 1.1 })
end
def params(:mult1) do
  Map.merge(params(:default), %{ timeout_mult: 1 })
end
def params(:no_timeout) do
  Map.merge(params(:default), %{ timeout_on: false })
end


def params(:no_opt) do
  Map.merge(params(:default), %{ optimise: false })
end

end # Configuration ----------------------------------------------------------------


