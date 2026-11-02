require "./cli/cli"
require "process/shell"

# Crystal has no JavaScript-style runtime eval. Keep an interactive task console
# with all classes compiled in, without pretending arbitrary Crystal can be eval'd.
puts RvmCliTools.logo
puts "RVM Windows test CLI — enter tasks, or exit to quit."
loop do
  print "rvm-test> "
  line = STDIN.gets
  break if line.nil? || line.strip.in?("exit", "quit")
  next if line.strip.empty?
  RvmCli.run(Process.parse_arguments(line))
end
