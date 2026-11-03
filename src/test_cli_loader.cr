require "./cli/cli"
require "process/shell"

# Interactive task console with all classes compiled in; accepts CLI commands,
# not arbitrary source expressions.
puts RvmCliTools.logo
puts RvmCliColor.primary("RVM Windows test CLI — enter tasks, or exit to quit.")
loop do
  print RvmCliColor.style("rvm-test> ", :magenta)
  line = STDIN.gets
  break if line.nil? || line.strip.in?("exit", "quit")
  next if line.strip.empty?
  RvmCli.run(Process.parse_arguments(line))
end
