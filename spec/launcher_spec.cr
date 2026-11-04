require "./spec_helper"

describe "session launchers" do
  it "retargets existing wrappers during setup without suppressing fresh-install discovery" do
    Fixtures.with_home do
      Fixtures.add_command("ruby-3.2.6", "ruby.exe")
      RvmCli.run(["--internal-install"], false, IO::Memory.new).should eq(0)
      File.file?(File.join(RvmCliTools.get_rvm_data_dir, "wrapper/ruby.bat")).should be_true
      File.delete(RvmCliTools.rvm_config_path)
      RvmCli.run(["--internal-install"], false, IO::Memory.new).should eq(0)
      File.exists?(RvmCliTools.rvm_config_path).should be_false
    end
  end

  it "establishes a parent PowerShell session shared by consecutive executable calls" do
    Fixtures.with_home do |home|
      root = File.join(home, "Author Software")
      Dir.mkdir_p(File.join(root, "bin"))
      Dir.mkdir_p(File.join(root, "src"))
      FileUtils.cp(Fixtures.executable, File.join(root, "bin/rvm.exe"))
      FileUtils.cp_r(File.join(RvmCliTools.rvm_root_path, "src/tools"), File.join(root, "src/tools"))
      FileUtils.cp_r(File.join(RvmCliTools.rvm_root_path, "src/templates"), File.join(root, "src/templates"))
      FileUtils.cp(File.join(root, "src/templates/rvm.ps1"), File.join(root, "rvm.ps1"))
      Fixtures.add_command("ruby-3.1.5", "ruby.exe")
      launcher = File.join(root, "rvm.ps1").gsub("'", "''")
      command = "& '#{launcher}' use 3.1.5; & '#{launcher}' current; Write-Output \"SESSION=$env:RVM_SESSION\""
      output = IO::Memory.new
      error = IO::Memory.new
      status = Process.run("powershell.exe", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", command],
        env: {"RVM_SESSION" => nil, "RVM_ROOT" => root}, output: output, error: error)
      status.exit_code.should eq(0), error.to_s
      output.to_s.should contain("Using ruby-3.1.5")
      output.to_s.should contain("ruby-3.1.5\nSESSION=")
      output.to_s.should_not contain("No rvm session found!")
    end
  end

  it "establishes a parent CMD session shared by consecutive executable calls" do
    Fixtures.with_home do |home|
      root = File.join(home, "Author Software")
      Dir.mkdir_p(File.join(root, "bin"))
      FileUtils.cp(Fixtures.executable, File.join(root, "bin/rvm.exe"))
      FileUtils.cp_r(File.join(RvmCliTools.rvm_root_path, "src/tools"), File.join(root, "tools"))
      # Copy only package assets into the same relative layout as distribution.
      Dir.mkdir_p(File.join(root, "src"))
      FileUtils.mv(File.join(root, "tools"), File.join(root, "src/tools"))
      FileUtils.cp_r(File.join(RvmCliTools.rvm_root_path, "src/templates"), File.join(root, "src/templates"))
      FileUtils.cp(File.join(root, "src/templates/rvm.cmd"), File.join(root, "rvm.cmd"))
      Fixtures.add_command("ruby-3.1.5", "ruby.exe")
      script = File.join(home, "session-test.cmd")
      File.write(script, "@echo off\r\ncall \"#{root}\\rvm.cmd\" use 3.1.5\r\ncall \"#{root}\\rvm.cmd\" current\r\necho SESSION=%RVM_SESSION%\r\n")
      output = IO::Memory.new
      error = IO::Memory.new
      status = Process.run(%Q("#{script}"), shell: true, env: {"RVM_SESSION" => nil, "RVM_ROOT" => root}, output: output, error: error)
      status.exit_code.should eq(0), error.to_s
      output.to_s.should contain("Using ruby-3.1.5")
      output.to_s.should contain("ruby-3.1.5\nSESSION=")
      output.to_s.should_not contain("No rvm session found!")
    end
  end

  it "removes only wrappers owned by the current executable, preserving shared data" do
    Fixtures.with_home do
      Fixtures.add_command("ruby-3.2.6", "ruby.exe")
      RvmCliFix.fix_wrapper_files
      directory = File.join(RvmCliTools.get_rvm_data_dir, "wrapper")
      other = File.join(directory, "other.bat")
      File.write(other, "@echo off\r\necho not ours\r\n")
      RvmCliFix.remove_package_wrappers
      Dir.children(directory).should eq(["other.bat"])
      File.file?(RvmCliTools.rvm_config_path).should be_true
      File.file?(File.join(RvmCliTools.envs["ruby-3.2.6"].as_s, "bin/ruby.exe")).should be_true
    end
  end
end
