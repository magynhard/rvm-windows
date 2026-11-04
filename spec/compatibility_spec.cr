require "./spec_helper"

module CompatibilityFixtures
  # Frozen reference data keeps compatibility checks independent of other
  # installations. Substitute only the isolated test home's dynamic path.
  def self.load(name : String, home : String? = nil) : JSON::Any
    text = File.read(File.join(__DIR__, "support", "#{name}_reference.json"))
    if home
      text = text.gsub("{{HOME}}", home.to_json[1..-2])
      text = text.gsub("{{HOME_POSIX}}", home.tr("\\", "/").to_json[1..-2])
    end
    JSON.parse(text)
  end
end

describe "CLI compatibility" do
  it "preserves complete missing-version explanations and every help task description" do
    result = CompatibilityFixtures.load("usage")
    result["messages"].as_h.each do |command, expected|
      output = IO::Memory.new
      error = IO::Memory.new
      RvmCli.run([command], false, output, error).should eq(expected["status"].as_i)
      error.to_s.gsub(/\e\[[0-9;]*m/, "").should eq(expected["error"].as_s)
      output.to_s.should eq("")
    end
    RvmCliHelp::TASKS.to_json.should eq(result["tasks"].to_json)
  end

  it "preserves text and semantic status colors with Windows-blue primary highlights" do
    previous = %w(FORCE_COLOR NO_COLOR).to_h { |key| {key, ENV[key]?} }
    begin
      ENV["FORCE_COLOR"] = "1"
      ENV.delete("NO_COLOR")
      Fixtures.with_home do |home|
        data = RvmCliTools.config
        data.as_h["proxy"] = JSON.parse(%({"hostname":"http://proxy.example:1234","enabled":false}))
        RvmCliTools.write_rvm_config(data)
        result = CompatibilityFixtures.load("color", home)
        io = IO::Memory.new
        RvmCliList.run_list(io)
        io.to_s.should eq(result["list"].as_s)
        io.to_s.should contain("\e[94m")
        io.clear
        RvmCliConfig.print_data(io)
        io.to_s.should eq(result["data"].as_s)
        io.clear
        RvmCliConfig.run_proxy(io: io)
        io.to_s.should eq(result["proxy"].as_s)
        io.to_s.should contain("\e[31mdisabled\e[39m")
      end
    ensure
      previous.each do |key, value|
        if value
          ENV[key] = value
        else
          ENV.delete(key)
        end
      end
    end
  end

  it "preserves numeric version resolution, list output and wrapper selection" do
    Fixtures.with_home do |home|
      ruby = Fixtures.add_command("ruby-3.2.6", "ruby.exe")
      File.write(File.join(home, ".ruby-version"), "3.2.6\r\n")
      versions = %w(ruby-3.2.9 ruby-3.2.10 ruby-3.10.1 ruby-2.4.10)
      queries = %w(ruby-3 ruby-3.2 ruby-3.2.9 ruby-3.2.8 ruby-2 ruby-9)
      result = CompatibilityFixtures.load("behavior", home)
      queries.map { |query| RvmCliTools.matching_version(query, versions) }.to_json.should eq(result["matches"].to_json)
      io = IO::Memory.new
      RvmCliList.run_list(io)
      io.to_s.gsub(/\e\[[0-9;]*m/, "").should eq(result["list"].as_s)
      Wrapper.get_ruby_version_for_path(home).should eq(result["pathVersion"].as_s)
      RvmCliTools.normalize_path(Wrapper.get_ruby_env_command_path("ruby-3.2", "ruby").not_nil!).should eq(RvmCliTools.normalize_path(result["commandPath"].as_s))
      RvmCliTools.normalize_path(result["commandPath"].as_s).should eq(RvmCliTools.normalize_path(ruby))
    end
  end
end
