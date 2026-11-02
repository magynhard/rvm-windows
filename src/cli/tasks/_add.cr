require "../_tools"
require "./_fix"

class RvmCliAdd
  def self.run_add(path : String, io : IO = STDOUT)
    path = RvmCliTools.normalize_path(path).sub("/bin/ruby.exe", "")
    if RvmCliTools.envs.values.any? { |value| value.as_s == path }
      io.puts "Ruby at #{File.expand_path(path)} is already added. Nothing to do."
    elsif !File.directory?(path)
      io.puts "Could not find path #{File.expand_path(path)}"
    else
      data = RvmCliTools.config
      RvmCliTools.envs(data)["add"] = JSON::Any.new(path)
      RvmCliTools.write_rvm_config(data)
      RvmCliFix.fix_environment_versions
      RvmCliFix.fix_wrapper_files
      io.puts "Added Ruby environment at #{File.expand_path(path)}."
    end
  end
end
