require "../_tools"
require "./_fix"

class RvmCliAdd
  def self.run_add(path : String, io : IO = STDOUT)
    path = RvmCliTools.normalize_path(path).sub("/bin/ruby.exe", "")
    if RvmCliTools.envs.values.any? { |value| value.as_s == path }
      io.puts "Ruby at #{RvmCliColor.primary(File.expand_path(path), io)} is already added. Nothing to do."
    elsif !File.directory?(path)
      io.puts "Could not find path #{RvmCliColor.red(File.expand_path(path), io)}"
    else
      data = RvmCliTools.config
      RvmCliTools.envs(data)["add"] = JSON::Any.new(path)
      RvmCliTools.write_rvm_config(data)
      RvmCliFix.fix_environment_versions
      RvmCliFix.fix_wrapper_files
      io.puts "Added Ruby environment at #{RvmCliColor.primary(File.expand_path(path), io)}."
    end
  end
end
