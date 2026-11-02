require "./tasks/_version"
require "../wrapper/*"

class RvmCli
  def self.run(args = ARGV) : Int32
    if args.first? == "--internal-wrapper"
      mode = args[1]? || ""
      cwd = args[2]? || Dir.current
      command = args[3]? || ""
      return case mode
      when "path"     then WrapperPath.run(cwd, command)
      when "rubypath" then WrapperRubypath.run(cwd, command)
      when "proxy"    then WrapperProxy.run(cwd, command)
      when "runner"   then WrapperRunner.run(cwd, command)
      when "after"    then WrapperAfter.run(cwd, command)
      else                 raise "Unknown internal wrapper: #{mode}"
      end
    end
    case args.first?
    when "version", "v", "--version", "-v"
      RvmCliVersion.run_version
    else
      puts "RVM CLI — Ruby Version Manager 4 Windows"
      puts "Run rvm version to display the build version."
    end
    0
  end
end
