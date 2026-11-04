require "../spec_helper"

describe "wrapper_template.bat" do
  it "always renders CRLF batch lines, independently of checkout line endings" do
    Fixtures.with_home do
      rendered = RvmCliFix.render_wrapper("C:/Matthäus Software/rvm.exe")
      rendered.should contain("\r\n")
      rendered.gsub("\r\n", "").should_not contain("\n")
      rendered.should_not contain("\r\r\n")
    end
  end

  %w(cmd powershell).each do |shell|
    [{42, 0}, {0, 17}].each do |exit_code, after_code|
      it "preserves wrapped exit code #{exit_code} after cleanup and hook status #{after_code} in #{shell} with a UTF-8 executable path" do
        Fixtures.with_home do |home|
          directory = File.join(home, "Matthäus Software")
          Dir.mkdir_p(directory)
          executable = File.join(directory, "rvm.exe")
          FileUtils.cp(Fixtures.executable(true), executable)
          batch = File.join(home, "wrapper.bat")
          File.write(batch, RvmCliFix.render_wrapper(executable))
          output = IO::Memory.new
          error = IO::Memory.new
          command, args = if shell == "powershell"
                            {"powershell.exe", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "& '#{batch.gsub("'", "''")}'; exit $LASTEXITCODE"]}
                          else
                            {"cmd.exe", ["/d", "/c", batch]}
                          end
          status = Process.run(command, args,
            env: {"RUBYPATH" => "original-rubypath", "RVM_TEST_EXIT_CODE" => exit_code.to_s,
                  "RVM_TEST_AFTER_EXIT_CODE" => after_code.to_s}, output: output, error: error)
          error.to_s.should eq("")
          output.to_s.should contain("AFTER_COMMAND_RAN|RUBYPATH=original-rubypath")
          status.exit_code.should eq(exit_code)
        end
      end
    end
  end

  it "executes the real compiled wrapper with arguments and restores environment" do
    Fixtures.with_home do |home|
      executable = Fixtures.executable
      Fixtures.add_command("ruby-3.2.6", "probe.cmd", "@echo off\r\necho ARG=%~1 RUBYPATH=%RUBYPATH%\r\nexit /b 42\r\n")
      # Render directly so the test uses the standalone executable, not the spec runner.
      directory = File.join(RvmCliTools.get_rvm_data_dir, "wrapper")
      Dir.mkdir_p(directory)
      batch = File.join(directory, "probe.bat")
      File.write(batch, RvmCliFix.render_wrapper(executable))
      output = IO::Memory.new
      error = IO::Memory.new
      status = Process.run(%Q("#{batch}" "argument with spaces"), shell: true,
        env: {"RUBYPATH" => "original-rubypath"}, output: output, error: error, chdir: home)
      error.to_s.should eq("")
      output.to_s.should contain("ARG=argument with spaces RUBYPATH=")
      output.to_s.should contain("ruby-3.2.6")
      status.exit_code.should eq(42)
    end
  end

  it "returns 9009 for a missing command through the real batch wrapper" do
    Fixtures.with_home do |home|
      batch = File.join(home, "missing.bat")
      File.write(batch, RvmCliFix.render_wrapper(Fixtures.executable))
      output = IO::Memory.new
      status = Process.run(%Q("#{batch}"), shell: true, output: output, error: IO::Memory.new, chdir: home)
      status.exit_code.should eq(9009)
      output.to_s.should contain("'missing' is not recognized")
    end
  end
end
