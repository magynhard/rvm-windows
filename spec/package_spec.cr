require "./spec_helper"

if package_root = ENV["RVM_PACKAGE_ROOT"]?
  describe "static release package" do
    it "supports colored and plain help with no external runtime on PATH" do
      Fixtures.with_home do
        windows = ENV["SystemRoot"]
        executable = File.join(package_root, "bin/rvm.exe")
        colored = IO::Memory.new
        plain = IO::Memory.new
        [{nil, colored}, {"1", plain}].each do |no_color, output|
          error = IO::Memory.new
          status = Process.run(executable, ["help"], output: output, error: error,
            env: {"PATH" => "#{windows}\\System32;#{windows}", "RVM_ROOT" => package_root,
                  "FORCE_COLOR" => "1", "NO_COLOR" => no_color})
          status.success?.should be_true, error.to_s
        end
        colored.to_s.should match(/\e\[[0-9;]*91[0-9;]*m/)
        colored.to_s.should contain("\e[94mrvm version\e[39m")
        colored.to_s.should contain("\n                \e[37m#{RvmCliVersion.get_version}\e[39m\n")
        plain.to_s.should_not contain("\e[")
        colored.to_s.gsub(/\e\[[0-9;]*m/, "").should eq(plain.to_s)
      end
    end

    it "runs with only Windows system directories on PATH" do
      Fixtures.with_home do |home|
        output = IO::Memory.new
        error = IO::Memory.new
        windows = ENV["SystemRoot"]
        executable = File.join(package_root, "bin/rvm.exe")
        status = Process.run(executable, ["version"], output: output, error: error,
          env: {"PATH" => "#{windows}\\System32;#{windows}", "RVM_ROOT" => package_root})
        status.exit_code.should eq(0), error.to_s
        output.to_s.should contain(RvmCliVersion.get_full_version)
        File.file?(File.join(package_root, "src/templates/.rvm.json")).should be_true
      end
    end
  end
end
