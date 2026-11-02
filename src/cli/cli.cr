require "./tasks/*"
require "../wrapper/*"

class RvmCli
  def self.required(args : Array(String), command : String) : String
    value = args.first?
    raise "No version given. Run rvm #{command} <version>, for example: rvm #{command} ruby-3.2.2" if value.nil? || value.empty?
    value
  end

  def self.run(args = ARGV, initialize = true, io : IO = STDOUT, error : IO = STDERR) : Int32
    if args.first? == "--internal-install"
      Dir.mkdir_p(RvmCliTools.rvm_sessions_dir)
      if File.file?(RvmCliTools.rvm_config_path)
        RvmCliFix.fix_config
        RvmCliFix.fix_wrapper_files
        io.puts RvmCliTools.get_rvm_data_dir
      else
        # Leave first-run discovery to normal startup, exactly as before. Setup
        # must not create an empty config that would suppress that discovery.
        io.puts RvmCliTools.get_default_rvm_data_dir
      end
      return 0
    end
    if args.first? == "--internal-uninstall"
      RvmCliFix.remove_package_wrappers
      return 0
    end
    if args.first? == "--internal-wrapper"
      mode = args[1]? || ""
      cwd = args[2]? || Dir.current
      command = args[3]? || ""
      return case mode
      when "path"     then WrapperPath.run(cwd, command, io)
      when "rubypath" then WrapperRubypath.run(cwd, command, io)
      when "proxy"    then WrapperProxy.run(cwd, command, io)
      when "runner"   then WrapperRunner.run(cwd, command, io)
      when "after"    then WrapperAfter.run(cwd, command, io)
      else                 raise "Unknown internal wrapper: #{mode}"
      end
    end
    command = args.first? || "help"
    if initialize
      RvmCliInit.init_after_install(io: io)
      RvmCliInit.init_session_to_rvm_exes(command: command, io: io)
      RvmCliInit.ensure_wrapper_is_first_in_path(io)
    end
    params = args.skip(1)
    if command.in?("version", "v") || args.any? { |arg| arg.in?("--version", "-v") }
      RvmCliVersion.run_version(io)
      return 0
    end
    # Preserve the source dispatch precedence: version, add, then help.
    if command.in?("add", "a", "mount", "m")
      raise "No path given. Run rvm add <path>" if params.empty?
      RvmCliAdd.run_add(params.join(' '), io)
      return 0
    end
    if args.any? { |arg| arg.in?("--help", "-h") }
      io.puts RvmCliTools.logo
      RvmCliHelp.run_help(io)
      return 0
    end
    case command
    when "help", "h"
      io.puts RvmCliTools.logo
      RvmCliHelp.run_help(io)
    when "init"
      RvmCliInit.init_after_install(true, io)
      RvmCliInit.init_session_to_rvm_exes(true, command, io)
    when "config", "cfg"
      RvmCliConfig.run_config(params, io)
    when "current", "c"
      RvmCliCurrent.run_current(io)
    when "default", "d"
      RvmCliDefault.run_default(io)
    when "system"
      RvmCliSystem.run_system(io)
    when "info"
      RvmCliInfo.run_info(io)
    when "fix", "f"
      RvmCliFix.run_fix(io)
    when "install", "i"
      RvmCliInstall.run_install(required(params, "install"), io: io)
    when "upgrade", "up"
      RvmCliUpgrade.run_upgrade(required(params, "upgrade"), params[1]?, io)
    when "get", "g"
      RvmCliGet.run_get(io)
    when "kick", "k"
      RvmCliKick.run_kick(required(params, "kick"), io)
    when "reinstall", "ri"
      RvmCliReinstall.run_reinstall(required(params, "reinstall"), io)
    when "uninstall", "ui", "remove", "rem", "delete", "del"
      RvmCliUninstall.run_uninstall(required(params, "uninstall"), io: io)
    when "scan", "s", "automount", "am"
      RvmCliScan.run_scan(io)
    when "kit"
      RvmCliKit.run_kit(io)
    when "list", "l", "ls", "lv", "la", "lk", "lu"
      subcommand = params.first?
      if subcommand == "known" || command == "lk"
        RvmCliList.run_list_known(io: io)
      elsif subcommand == "all" || command == "la"
        RvmCliList.run_list_all(io: io)
      elsif subcommand.in?("verbose", "v") || command == "lv"
        RvmCliList.run_list_verbose(io)
      elsif subcommand.in?("upgrades", "u") || command == "lu"
        RvmCliList.run_list_upgrades(io)
      else
        RvmCliList.run_list(io)
      end
    when "debug"
      RvmCliList.run_list_verbose(io)
    when "use", "u"
      first = params.first? || ""
      second = params[1]?
      version = required(first.starts_with?("--") ? params.skip(1) : params, "use")
      parameter = first.starts_with?("--") && RvmCliTools.starts_with_number(second) ? first : second
      RvmCliUse.run_use(version, parameter == "--default", io)
    else
      RvmCliHelp.run_unknown_command(command.gsub("-", ""), io)
    end
    0
  rescue ex
    error.puts ex.message
    1
  end
end
