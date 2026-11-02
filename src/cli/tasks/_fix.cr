require "../_tools"

class RvmCliFix
  def self.run_fix(io : IO = STDOUT)
    io.puts "Fix several issues that could have happened ..."
    RvmCliTools.kill_running_msys_processes(io)
    io.puts "Fix config ..."
    fix_config
    io.puts "Fix existing environment paths ..."
    fix_existing_environment_paths
    io.puts "Fix environment versions ..."
    fix_environment_versions
    io.puts "Fix wrapper files ..."
    fix_wrapper_files
    io.puts "Fixing finished!\n\nIf you still have trouble, you might try to run rvm init to reinit rvm-windows itself!"
  end

  def self.fix_config
    if File.file?(RvmCliTools.rvm_config_path)
      begin
        RvmCliTools.config
        return
      rescue JSON::ParseException
        # Same recovery policy as the original implementation.
      end
    end
    RvmCliTools.copy_file(RvmCliTools.rvm_config_template_path, RvmCliTools.rvm_config_path)
  end

  def self.fix_existing_environment_paths
    data = RvmCliTools.config
    RvmCliTools.envs(data).keys.each do |version|
      path = RvmCliTools.envs(data)[version].as_s
      if File.file?(File.join(path, "bin", "ruby.exe"))
        RvmCliTools.envs(data)[version] = JSON::Any.new(RvmCliTools.normalize_path(path))
      else
        RvmCliTools.envs(data).delete(version)
      end
    end
    RvmCliTools.write_rvm_config(data)
  end

  def self.ruby_description(path : String) : String
    RvmCliTools.capture(File.join(path, "bin", "ruby.exe"), ["--version"])
  end

  def self.get_ruby_version_from_ruby_path(path : String) : String
    result = ruby_description(path)
    result.match(/ruby\s+([0-9.]+)/).try(&.[1]) || raise "Could not detect version from: #{result}"
  end

  def self.get_ruby_platform_from_ruby_path(path : String) : String
    result = ruby_description(path)
    result.match(/\[([^\]]+)\]/).try(&.[1]) || raise "Could not detect platform from: #{result}"
  end

  def self.fix_environment_versions
    data = RvmCliTools.config
    RvmCliTools.envs(data).dup.each do |version, value|
      path = value.as_s
      RvmCliTools.envs(data).delete(version)
      if File.file?(File.join(path, "bin", "ruby.exe"))
        pure_version = get_ruby_version_from_ruby_path(path)
        RvmCliTools.envs(data)["ruby-#{pure_version}"] = JSON::Any.new(RvmCliTools.normalize_path(path))
      end
    end
    RvmCliTools.write_rvm_config(data)
  end

  def self.render_wrapper(executable = Process.executable_path.not_nil!) : String
    # CMD's nested FOR /F command parser strips a leading pair of quotes.
    # Preserve the original segment-quoting strategy for executable paths.
    executable = executable.tr("/", "\\").split('\\').map do |segment|
      segment.includes?(' ') ? %Q("#{segment}") : segment
    end.join('\\')
    File.read(RvmCliTools.rvm_batch_template_path)
      .sub("{{rvm_executable}}", executable)
      .sub("{{rvm_root_dir}}", RvmCliTools.rvm_root_path)
  end

  def self.fix_wrapper_files
    wrapper_path = File.join(RvmCliTools.get_rvm_data_dir, "wrapper")
    FileUtils.rm_rf(wrapper_path)
    Dir.mkdir_p(wrapper_path)
    template = render_wrapper
    RvmCliTools.envs.each_value do |value|
      Dir.glob(RvmCliTools.normalize_path(File.join(value.as_s, "bin", "*.*"))).each do |file|
        name = File.basename(file)
        case File.extname(name)
        when ".bat"
          destination = File.join(wrapper_path, name)
          File.write(destination, template) unless File.exists?(destination)
        when ".exe", ".cmd"
          ["#{name}.bat", "#{File.basename(name, File.extname(name))}.bat"].each do |wrapper|
            destination = File.join(wrapper_path, wrapper)
            File.write(destination, template) unless File.exists?(destination)
          end
        end
      end
    end
  end
end
