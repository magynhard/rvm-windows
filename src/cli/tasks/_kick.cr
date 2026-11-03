require "../_tools"
require "./_use"

class RvmCliKick
  def self.run_kick(version : String, io : IO = STDOUT)
    version = RvmCliTools.normalize_version(version)
    if RvmCliTools.envs.has_key?(version)
      io.puts "Remove #{RvmCliColor.green(version, io)} from list ... please wait ..."
      data = RvmCliTools.config
      RvmCliTools.envs(data).delete(version)
      RvmCliTools.write_rvm_config(data)
      io.puts "The environment #{RvmCliColor.red(version, io)} has been successfully removed from the list!\n"
      RvmCliUse.fix_default_and_current(io)
    else
      io.puts "Given version #{RvmCliColor.red(version, io)} not found. To list all installed versions, run #{RvmCliColor.green("rvm list", io)}."
    end
  end
end
