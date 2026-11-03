require "./spec_helper"
require "./support/info_fixture"

if package_root = ENV["RVM_PACKAGE_ROOT"]?
  describe "static release package" do
    it "ships the README and installer artwork in src/assets/img without legacy PNG logos" do
      %w(rvm-windows-icon.svg rvm-windows-icon.png rvm-windows.ico).each do |name|
        File.file?(File.join(package_root, "src/assets/img", name)).should be_true
        File.exists?(File.join(package_root, "doc/img", name)).should be_false
      end
      Dir.glob(File.join(package_root, "doc/img/rvm_cmd*.png")).should be_empty
      File.read(File.join(package_root, "README.md")).should contain("src/assets/img/rvm-windows-icon.svg")
    end

    it "preserves the complete missing-parameter explanation for upgrade" do
      Fixtures.with_home do
        output = IO::Memory.new
        error = IO::Memory.new
        status = Process.run(File.join(package_root, "bin/rvm.exe"), ["upgrade"],
          env: {"RVM_ROOT" => package_root, "NO_COLOR" => "1"}, output: output, error: error)
        status.exit_code.should eq(1)
        error.to_s.should eq("No version given. Run rvm upgrade <version> or rvm upgrade <from_version> <to_version> to upgrade an existing environment, for example: rvm upgrade ruby-3.0\n")
      end
    end

    it "runs info using CMD built-ins and a quoted Ruby installation path" do
      InfoFixtures.with_installation do
        output = IO::Memory.new
        error = IO::Memory.new
        executable = File.join(package_root, "bin/rvm.exe")
        status = Process.run(executable, ["info"], env: {"RVM_ROOT" => package_root}, output: output, error: error)
        status.success?.should be_true, error.to_s
        output.to_s.should match(/Windows.*\d+\.\d+\.\d+/)
        output.to_s.should contain("version:      #{RvmCliVersion.get_version}")
        output.to_s.should contain("full_version: ruby 3.2.6")
      end
    end

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
        colored.to_s.split("\n\n", 2).first.should_not contain("\e[")
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
