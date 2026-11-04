require "../_tools"
require "./_use"

class RvmCliUninstall
  def self.run_uninstall(version : String, repair = true, io : IO = STDOUT)
    version = RvmCliTools.normalize_version(version)
    install_dir = RvmCliTools.envs[version]?.try(&.as_s)
    if install_dir && File.directory?(install_dir)
      io.puts "Uninstalling #{RvmCliColor.primary(version, io)} from #{RvmCliColor.red(File.expand_path(install_dir), io)} ... please wait ..."
      FileUtils.rm_rf(install_dir)
      data = RvmCliTools.config
      RvmCliTools.envs(data).delete(version)
      RvmCliTools.write_rvm_config(data)
      io.puts "The environment #{RvmCliColor.red(version, io)} has been successfully removed!\n"
      RvmCliUse.fix_default_and_current(io) if repair
    else
      io.puts "Given version #{RvmCliColor.red(version, io)} not found. To list all installed versions, run #{RvmCliColor.primary("rvm list", io)}."
    end
  end
end
