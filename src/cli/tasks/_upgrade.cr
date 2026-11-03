require "./_install"

class RvmCliUpgrade
  def self.run_upgrade(from_version : String, to_version : String? = nil, io : IO = STDOUT)
    releases = RvmCliList.run_list_all(true, io)
    from_version = RvmCliTools.normalize_version(from_version)
    to_version ||= RvmCliTools.matching_version(from_version.split('.')[0, 2].join('.'), releases)
    raise "No upgrade available for #{from_version}" unless to_version
    to_version = RvmCliTools.normalize_version(to_version)
    if path = RvmCliTools.envs[from_version]?.try(&.as_s)
      io.puts "Upgrading #{RvmCliColor.primary(from_version, io)} to #{RvmCliColor.primary(to_version, io)} ...\n"
      RvmCliInstall.run_install(to_version, path, io)
    else
      io.puts "Given version #{RvmCliColor.red(from_version, io)} not found. To list all installed versions, run #{RvmCliColor.primary("rvm list", io)}."
    end
  end
end
