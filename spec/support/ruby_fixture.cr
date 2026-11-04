# A read-only Ruby --version stand-in; no real Ruby installation is executed.
if ARGV == ["--version"]
  puts "ruby 3.2.6 (2024-10-30 revision 63aeb018eb) [x64-mingw-ucrt]"
else
  STDERR.puts "Unexpected Ruby fixture arguments: #{ARGV.inspect}"
  exit 1
end
