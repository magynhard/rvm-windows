require "../_tools"
require "./_fix"
require "./_scan"
require "./_add"
require "./_config"

class RvmCliUse
  def self.run_use(version : String, set_default = false, io : IO = STDOUT)
    case version
    when "default"
      version = RvmCliTools.get_default_version
    when "system"
      version = add_and_get_system_version(io) || ""
      raise "No system ruby found! You can manually add a system ruby by running rvm add <path>, e.g. rvm add C:\\Ruby-3.2.2x64." if version.empty?
    end
    version = RvmCliTools.normalize_version(version)
    if match = RvmCliTools.matching_version(version)
      RvmCliTools.set_current_version(match)
      io.puts "Using #{RvmCliColor.primary(match, io)} from #{RvmCliColor.primary(File.expand_path(RvmCliTools.envs[match].as_s), io)} ..."
      RvmCliFix.fix_wrapper_files
      RvmCliTools.set_default_version(version, io) if set_default
    else
      io.puts "No version for #{RvmCliColor.red(version, io)} available! Run #{RvmCliColor.primary("rvm list", io)} to show available versions."
    end
  end

  def self.fix_default_and_current(io : IO = STDOUT)
    RvmCliFix.run_fix(io)
    envs = RvmCliTools.envs
    new_version = envs.keys.first?
    default = RvmCliTools.get_default_version
    current = RvmCliTools.get_current_version
    unless envs.has_key?(current)
      candidate = envs.has_key?(default) ? default : new_version
      run_use(candidate, io: io) if candidate
    end
    unless envs.has_key?(default)
      candidate = envs.has_key?(current) ? current : new_version
      RvmCliConfig.run_default(candidate, io) if candidate
    end
  end

  def self.add_and_get_system_version(io : IO = STDOUT) : String?
    io.puts "Scanning for system rubies ...\n"
    paths = RvmCliScan.scan_missing_environment_paths(false)
    paths = paths.reject { |path| path.includes?("ProgramData\\rvm") || path.includes?("ProgramData/rvm") }
    unless paths.empty?
      io.puts "Found the following system rubies:"
      io.puts paths.map { |path| " - #{RvmCliColor.primary(path, io)}" }.join('\n')
      io.puts
    end
    if path = paths.first?
      RvmCliAdd.run_add(path, io)
      RvmCliFix.get_ruby_version_from_ruby_path(path)
    end
  end
end
