require "spec"
require "../src/cli/cli"

module Fixtures
  TEMP_ROOT  = File.join(ENV["TEMP"]? || Dir.tempdir, "opencode")
  BUILD_ROOT = File.join(TEMP_ROOT, "rvm-cr-build-#{Random.rand(1_000_000_000)}")
  @@executables = {} of String => String

  def self.executable(fixture = false) : String
    name = fixture ? "wrapper-fixture" : "rvm"
    @@executables[name] ||= begin
      Dir.mkdir_p(BUILD_ROOT)
      source = fixture ? File.expand_path("support/wrapper_fixture.cr", __DIR__) : File.expand_path("../src/rvm-windows.cr", __DIR__)
      output = File.join(BUILD_ROOT, "#{name}.exe")
      RvmCliTools.capture("crystal", ["build", source, "-o", output])
      output
    end
  end

  def self.with_home(&)
    root = File.join(TEMP_ROOT, "rvm-cr-spec-#{Random.rand(1_000_000_000)}")
    keys = %w(RVM_HOME RVM_ROOT RVM_SESSION MSYS2_PATH)
    previous = keys.to_h { |key| {key, ENV[key]?} }
    begin
      Dir.mkdir_p(root)
      ENV["RVM_HOME"] = root
      ENV["RVM_ROOT"] = File.expand_path("..", __DIR__)
      ENV["RVM_SESSION"] = "spec-session"
      ENV.delete("MSYS2_PATH")
      data = JSON.parse(File.read(File.join(ENV["RVM_ROOT"], "src/templates/.rvm.json")))
      data.as_h["rvm_data_dir"] = JSON::Any.new(File.join(root, "data"))
      data.as_h["default"] = JSON::Any.new("ruby-3.2.6")
      data.as_h["envs"] = JSON.parse({
        "ruby-3.1.5"  => File.join(root, "ruby-3.1.5"),
        "ruby-2.4.10" => File.join(root, "ruby-2.4.10"),
        "ruby-3.0.7"  => File.join(root, "ruby-3.0.7"),
        "ruby-3.2.6"  => File.join(root, "ruby-3.2.6"),
      }.to_json)
      RvmCliTools.write_rvm_config(data)
      Dir.mkdir_p(RvmCliTools.rvm_sessions_dir)
      yield root
    ensure
      previous.each do |key, value|
        if value
          ENV[key] = value
        else
          ENV.delete(key)
        end
      end
      FileUtils.rm_rf(root)
    end
  end

  def self.add_command(version : String, command : String, contents = "") : String
    path = File.join(RvmCliTools.envs[version].as_s, "bin", command)
    RvmCliTools.write_file(path, contents)
    path
  end
end

Spec.after_suite { FileUtils.rm_rf(Fixtures::BUILD_ROOT) }
