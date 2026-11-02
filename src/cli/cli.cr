require "./tasks/_version"

class RvmCli
  def self.run(args = ARGV) : Int32
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
