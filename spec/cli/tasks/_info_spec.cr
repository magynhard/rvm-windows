require "../../support/info_fixture"

describe RvmCliInfo do
  it "prints system, RVM, Ruby and home details using a quoted Ruby installation path" do
    InfoFixtures.with_installation do |path|
      io = IO::Memory.new
      RvmCliInfo.run_info(io)
      %w(system: rvm: ruby: homes:).each { |section| io.to_s.should contain(section) }
      io.to_s.should match(/Windows.*\d+\.\d+\.\d+/)
      io.to_s.should contain("version:      #{RvmCliVersion.get_version}")
      io.to_s.should contain("date:         2024-10-30")
      io.to_s.should contain("platform:     x64-mingw-ucrt")
      io.to_s.should contain("full_version: ruby 3.2.6")
      io.to_s.should contain(File.expand_path(path))
      io.to_s.should contain("rvm.cmd")
    end
  end

  it "runs info successfully through the compiled executable" do
    executable = Fixtures.executable
    InfoFixtures.with_installation do
      output = IO::Memory.new
      error = IO::Memory.new
      status = Process.run(executable, ["info"], output: output, error: error)
      status.success?.should be_true, error.to_s
      output.to_s.should contain("  system:")
      output.to_s.should contain("full_version: ruby 3.2.6")
      output.to_s.should_not contain("Error executing process")
    end
  end
end
