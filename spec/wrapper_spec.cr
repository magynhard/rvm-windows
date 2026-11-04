require "./spec_helper"

describe Wrapper do
  it "walks parent directories and prefers .ruby-version over Gemfile" do
    Fixtures.with_home do |home|
      project = File.join(home, "project")
      nested = File.join(project, "nested", "child")
      Dir.mkdir_p(nested)
      File.write(File.join(project, "Gemfile"), "ruby '3.1.5'\n")
      Wrapper.get_ruby_version_for_path(nested).should eq("ruby-3.1.5")
      File.write(File.join(project, ".ruby-version"), "3.2.6\r\n")
      Wrapper.get_ruby_version_for_path(nested).should eq("ruby-3.2.6")
      File.write(File.join(nested, ".ruby-version"), "ruby-3.0.7")
      Wrapper.get_ruby_version_for_path(nested).should eq("ruby-3.0.7")
    end
  end

  it "stops at the filesystem root and falls back to the current version" do
    Fixtures.with_home do |home|
      Wrapper.get_ruby_version_for_path(home).should eq("ruby-3.2.6")
    end
  end

  it "prefers exe over bat over cmd and falls back to the session command" do
    Fixtures.with_home do |home|
      bat = Fixtures.add_command("ruby-3.2.6", "ruby.bat")
      exe = Fixtures.add_command("ruby-3.2.6", "ruby.exe")
      Wrapper.get_ruby_env_command_path("ruby-3.2", "ruby").should eq(exe)
      File.delete(exe)
      Wrapper.get_ruby_env_command_path("ruby-3.2.6", "ruby").should eq(bat)
      File.write(File.join(home, ".ruby-version"), "3.1.5")
      io = IO::Memory.new
      WrapperRunner.run(home, "ruby", io).should eq(0)
      io.to_s.should contain(bat)
    end
  end

  it "emits only batch-compatible protocol output and the 9009 missing-command status" do
    Fixtures.with_home do |home|
      io = IO::Memory.new
      WrapperPath.run(home, "ruby", io).should eq(0)
      io.to_s.should contain("set \"PATH=")
      io.clear
      WrapperRubypath.run(home, "ruby", io)
      io.to_s.should contain("RUBYPATH=")
      io.clear
      WrapperProxy.run(home, "ruby", io)
      io.to_s.should eq("\n")
      io.clear
      WrapperRunner.run(home, "missing", io).should eq(9009)
      io.to_s.should contain("exit /b 9009")
    end
  end

  it "creates all supported wrapper filename variants using the native executable" do
    Fixtures.with_home do
      Fixtures.add_command("ruby-3.2.6", "ruby.exe")
      Fixtures.add_command("ruby-3.2.6", "gem.cmd")
      Fixtures.add_command("ruby-3.2.6", "bundle.bat")
      RvmCliFix.fix_wrapper_files
      dir = File.join(RvmCliTools.get_rvm_data_dir, "wrapper")
      Dir.children(dir).sort.should eq(%w(bundle.bat gem.bat gem.cmd.bat ruby.bat ruby.exe.bat))
      File.read(File.join(dir, "ruby.bat")).should contain("--internal-wrapper runner")
      File.read(File.join(dir, "ruby.bat")).should contain("SET \"RVM_EXECUTABLE=")
    end
  end
end
