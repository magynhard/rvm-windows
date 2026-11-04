require "file_utils"

root = File.expand_path("..", __DIR__)
Dir.cd(root) do
  Dir.mkdir_p("bin")
  # Link the Crystal runtime and dependencies statically. The resulting EXE
  # imports only Windows system DLLs; no separate runtime installation is required.
  status = Process.run("crystal", ["build", "src/rvm-windows.cr", "--release", "--static", "-o", "bin/rvm.exe"],
    output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
  exit status.exit_code unless status.success?
  FileUtils.cp("src/templates/rvm.cmd", "rvm.cmd")
  FileUtils.cp("src/templates/rvm.ps1", "rvm.ps1")
  puts "Built #{File.join(root, "bin/rvm.exe")}"
end
