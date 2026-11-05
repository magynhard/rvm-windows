if ARGV == ["get"]
  session = ENV["RVM_SESSION"]? || abort "Missing RVM_SESSION"
  root = File.dirname(File.dirname(Process.executable_path.not_nil!))
  status = File.join(root, ".rvm-update-#{session}.status")
  File.write(status, "pending")
  escaped = status.gsub("'", "''")
  result = ENV["RVM_TEST_UPDATE_RESULT"]? || "0"
  Process.new("powershell.exe", ["-NoProfile", "-Command",
                                 "Start-Sleep -Seconds 2; [IO.File]::WriteAllText('#{escaped}', '#{result}')"],
    input: Process::Redirect::Close, output: Process::Redirect::Close, error: Process::Redirect::Close)
  puts "Fixture get returned before setup completed"
else
  puts "fixture"
end
