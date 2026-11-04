require "../spec_helper"

module InfoFixtures
  def self.with_installation(&)
    ruby = Fixtures.ruby_executable
    Fixtures.with_home do |home|
      path = File.join(home, "Ruby Installation")
      bin = File.join(path, "bin")
      commands = File.join(home, "Command Wrappers")
      Dir.mkdir_p(bin)
      Dir.mkdir_p(commands)
      FileUtils.cp(ruby, File.join(bin, "ruby.exe"))
      File.write(File.join(commands, "rvm.cmd"), "@echo off\r\nexit /b 0\r\n")
      config = RvmCliTools.config
      config.as_h["envs"] = JSON.parse({"ruby-3.2.6" => path}.to_json)
      RvmCliTools.write_rvm_config(config)
      previous_path = ENV["PATH"]?
      begin
        ENV["PATH"] = "#{commands};#{previous_path}"
        yield path
      ensure
        if previous_path
          ENV["PATH"] = previous_path
        else
          ENV.delete("PATH")
        end
      end
    end
  end
end
