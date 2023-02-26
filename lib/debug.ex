
# distributed algorithms, n.dulay, 31 jan 2023
# coursework, paxos made moderately complex
#
# some functions for debugging

defmodule Debug do

def info(config, message, verbose \\ 2) do
  if config.debug_level >= verbose do
    colour = case config.node_num do
      1 -> IO.ANSI.red()
      2 -> IO.ANSI.green()
      3 -> IO.ANSI.blue()
      4 -> IO.ANSI.cyan()
      5 -> IO.ANSI.magenta()
      6 -> IO.ANSI.yellow()
      _ -> IO.ANSI.black()
    end
    IO.puts "#{colour}--> Debug #{config.node_name}: #{message}"
  end
end # log

def map(config, themap, verbose \\ 1) do
  if config.debug_level >= verbose do
    for {key, value} <- themap do IO.puts "  #{key} #{inspect value}" end
  end
end # map

def starting(config, verbose \\ 0) do
  if config.debug_level >= verbose do
    IO.puts "--> Starting #{config.node_name} at #{config.node_location}"
  end
end # starting

def letter(config, letter, verbose \\ 3) do
  if config.debug_level >= verbose do IO.write letter end
end # letter

def mapstring(map) do
  for {key, value} <- map, into: "" do "\n  #{key}\t #{inspect value}" end
end # mapstring

end # Log
