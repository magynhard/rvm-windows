require "./spec_helper"

if package_root = ENV["RVM_PACKAGE_ROOT"]?
  describe "static release package" do
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
