require "./_uninstall"
require "./_install"

class RvmCliReinstall
  def self.run_reinstall(version : String, io : IO = STDOUT)
    version = RvmCliTools.normalize_version(version)
    if RvmCliTools.envs.has_key?(version)
      RvmCliUninstall.run_uninstall(version, false, io)
      RvmCliInstall.run_install(version, io: io)
    else
      RvmCliUninstall.run_uninstall(version, false, io)
    end
  end
end
