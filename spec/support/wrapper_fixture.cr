# Compiled protocol fixture, analogous to the original spec's five fake scripts.
case ARGV[1]?
when "path"
  puts "VER > NUL"
when "rubypath"
  puts "SET \"RUBYPATH=temporary-rubypath\""
when "proxy"
  puts ""
when "runner"
  puts "cmd.exe /d /c exit #{ENV["RVM_TEST_EXIT_CODE"]}"
when "after"
  puts "AFTER_COMMAND_RAN|RUBYPATH=#{ENV["RUBYPATH"]?}"
  exit ENV["RVM_TEST_AFTER_EXIT_CODE"].to_i
end
