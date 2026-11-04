require "../_tools"
require "./_fix"
require "./_scan"

{% if flag?(:win32) %}
  @[Link("kernel32")]
  lib RvmKernel32
    fun GetTickCount64 : UInt64
  end
{% end %}

class RvmCliInit
  def self.get_user_path : String
    batch = File.join(RvmCliTools.rvm_root_path, "src/tools/path/get_user_path.bat")
    RvmCliTools.shell(%Q("#{batch}"))
  end

  def self.ensure_wrapper_path_env_is_set(silent = false, io : IO = STDOUT)
    wrapper = File.expand_path(File.join(RvmCliTools.get_rvm_data_dir, "wrapper"))
    root = RvmCliTools.rvm_root_path
    script = File.join(root, "src/tools/path/package_path.ps1")
    RvmCliTools.capture("powershell.exe", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script,
                                           "-InstallRoot", root, "-WrapperPath", wrapper, "-WrapperOnly"])
    io.puts "Added path successfully!" unless silent
  rescue ex
    io.puts "Error when adding path: #{ex.message}" unless silent
  end

  def self.reload_cmd(path : String)
    Process.run(ENV["COMSPEC"]? || "cmd.exe", env: {"PATH" => path},
      input: Process::Redirect::Inherit, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
  end

  def self.write_to_second_line(file : String, line : String)
    raise "Could not find file '#{file}'" unless File.file?(file)
    lines = File.read(file).split('\n')
    unless lines[1]?.try(&.strip) == line.strip
      lines.insert(1, line)
      File.write(file, lines.join('\n'))
    end
  end

  def self.init_session_to_rvm_exes(force = false, command = "", io : IO = STDOUT)
    # Do not patch arbitrary launchers returned by `where rvm`.
    # The package owns root/rvm.cmd and root/rvm.ps1; bin/rvm.exe stays private
    # so the parent shell can establish RVM_SESSION before calling the EXE.
    unless File.directory?(RvmCliTools.rvm_sessions_dir) && !force
      root = RvmCliTools.rvm_root_path
      RvmCliTools.copy_file(File.join(root, "src/templates/rvm.cmd"), File.join(root, "rvm.cmd"))
      RvmCliTools.copy_file(File.join(root, "src/templates/rvm.ps1"), File.join(root, "rvm.ps1"))
      Dir.mkdir_p(RvmCliTools.rvm_sessions_dir)
    end
    unless ENV["RVM_SESSION"]? || command == "init"
      io.puts "#{RvmCliColor.red("No rvm session found!", io)} Run #{RvmCliColor.primary("rvm init", io)} to recreate session wrappers. Otherwise #{RvmCliColor.primary("rvm use", io)} is not working.\n"
    end
    clean_sessions
  end

  def self.clean_sessions
    {% if flag?(:win32) %}
      boot_time = Time.utc - RvmKernel32.GetTickCount64.milliseconds
      data = RvmCliTools.config
      last_boot = data["last_run_boot_time"]?.try(&.as_s?) || ""
      previous = last_boot.empty? ? nil : Time.parse_rfc3339(last_boot)
      if !same_boot?(previous, boot_time)
        FileUtils.rm_rf(RvmCliTools.rvm_sessions_dir) if previous
        Dir.mkdir_p(RvmCliTools.rvm_sessions_dir)
        data.as_h["last_run_boot_time"] = JSON::Any.new(boot_time.to_rfc3339(fraction_digits: 3))
        RvmCliTools.write_rvm_config(data)
      end
    {% end %}
  end

  def self.same_boot?(previous : Time?, current : Time) : Bool
    return false unless previous
    (previous.to_unix_ms - current.to_unix_ms).abs < 60_000
  end

  def self.init_after_install(force = false, io : IO = STDOUT)
    if !File.file?(RvmCliTools.rvm_config_path) || force
      RvmCliFix.fix_config
      ensure_wrapper_path_env_is_set(true, io)
      RvmCliScan.run_scan(io)
      io.puts "RVM has been initialized and is ready to use! (Open terminals will need to be restarted to reload PATH environment variable)"
    end
  end

  def self.ensure_wrapper_is_first_in_path(io : IO = STDOUT)
    paths = begin
      RvmCliTools.capture("where", ["ruby"]).lines.map(&.strip).reject(&.empty?)
    rescue
      [] of String
    end
    if !paths.empty? && !File.expand_path(paths.first).includes?("\\rvm\\wrapper")
      io.puts RvmCliColor.yellow("Warning: rvm-windows wrapper ruby is not the first ruby in path! Other ruby is configured before!", io)
      io.puts "To fix this, try #{RvmCliColor.primary("rvm init", io)} and restart your terminal!"
      io.puts "If this does not work, your system PATH may include rubies, that needs to be removed manually!\n"
      io.puts RvmCliColor.yellow("Ruby paths in following order found:", io)
      io.puts paths.map { |path| "- #{path}" }.join('\n')
      io.puts
    end
  end
end
