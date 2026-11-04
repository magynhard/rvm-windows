require "../cli/_wrapper"

module WrapperRunner
  def self.run(cwd : String, command : String, io : IO = STDOUT) : Int32
    command = command.split('.').first
    version = Wrapper.get_ruby_version_for_path(cwd)
    if Wrapper.has_ruby_env_command(version, command)
      io.puts %Q("#{Wrapper.get_ruby_env_command_path(version, command)}")
    elsif Wrapper.has_ruby_env_command(RvmCliTools.get_current_version, command)
      io.puts %Q("#{Wrapper.get_ruby_env_command_path(RvmCliTools.get_current_version, command)}")
    else
      io.puts "@echo off && echo '#{command}' is not recognized as an internal or external command, operable program or batch file. && exit /b 9009"
      return 9009
    end
    0
  end
end
