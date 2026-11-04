require "./_tools"

class Wrapper
  def self.get_ruby_version_for_path(path : String) : String
    version = RvmCliTools.get_current_version
    path = File.expand_path(path)
    loop do
      version_file = File.join(path, ".ruby-version")
      gemfile = File.join(path, "Gemfile")
      if File.file?(version_file)
        version = File.read(version_file)
        break
      elsif File.file?(gemfile) && (match = File.read(gemfile).match(/ruby\s*["']([0-9.]+)['"]/))
        version = match[1].strip
        break
      end
      parent = File.dirname(path)
      break if parent == path || parent.empty?
      path = parent
    end
    RvmCliTools.normalize_version(version.strip)
  end

  def self.has_ruby_env_command(version : String, command : String) : Bool
    if RvmCliTools.versions.includes?(version)
      bin = File.join(RvmCliTools.envs[version].as_s, "bin")
      %w(bat cmd exe).any? { |ext| File.file?(File.join(bin, "#{command}.#{ext}")) }
    else
      !!RvmCliTools.matching_version(version)
    end
  end

  def self.get_ruby_env_command_path(version : String, command : String) : String?
    match = RvmCliTools.matching_version(version) || raise "Ruby version #{version} not found!"
    bin = File.join(RvmCliTools.envs[match].as_s, "bin")
    %w(exe bat cmd).each do |ext|
      path = File.join(bin, "#{command}.#{ext}")
      return path if File.file?(path)
    end
    nil
  end

  def self.get_path_of_matching_ruby_version(version : String) : String?
    if match = RvmCliTools.matching_version(version)
      RvmCliTools.envs[match].as_s
    end
  end
end
