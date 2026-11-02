require "../../spec_helper"

describe RvmCliInit do
  it "reads the user PATH when the installation path contains spaces" do
    {% if flag?(:win32) %}
      Fixtures.with_home do |home|
        source = RvmCliTools.rvm_root_path
        expected = RvmCliInit.get_user_path
        ["NoSpaces", "Author Software"].each do |name|
          root = File.join(home, name)
          RvmCliTools.copy_file(File.join(source, "src/tools/path/get_user_path.bat"), File.join(root, "src/tools/path/get_user_path.bat"))
          ENV["RVM_ROOT"] = root
          RvmCliInit.get_user_path.should eq(expected)
        end
      end
    {% end %}
  end

  it "inserts a second line only once" do
    Fixtures.with_home do |home|
      file = File.join(home, "launcher.cmd")
      File.write(file, "@echo off\noriginal\n")
      2.times { RvmCliInit.write_to_second_line(file, "call session.bat") }
      File.read(file).should eq("@echo off\ncall session.bat\noriginal\n")
    end
  end

  it "cleans stale sessions but preserves sessions from this boot" do
    Fixtures.with_home do
      data = RvmCliTools.config
      data.as_h["last_run_boot_time"] = JSON::Any.new("2000-01-01T00:00:00.000Z")
      RvmCliTools.write_rvm_config(data)
      RvmCliTools.set_current_version("ruby-3.1.5")
      RvmCliInit.clean_sessions
      RvmCliTools.get_current_version.should eq("ruby-3.2.6")
      RvmCliTools.set_current_version("ruby-3.0.7")
      RvmCliInit.clean_sessions
      RvmCliTools.get_current_version.should eq("ruby-3.0.7")
    end
  end
end
