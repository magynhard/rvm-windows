require "../_tools"

class RvmCliHelp
  TASKS = [
    {"add <path>", "a", "Add a installed ruby environment to the list (alias: mount)"},
    {"automount", "am", "Scan for ruby installations and add them to the RVM configuration (alias: scan)"},
    {"config", "cfg", "Print current RVM config"},
    {"config default", "cfg d", "Print default version"},
    {"config default <version>", "cfg d <version>", "Set default version"},
    {"config data", "cfg dt", "Print RVM data directory"},
    {"config data <path>", "cfg dt <path>", "Set RVM data directory"},
    {"config proxy", "cfg p", "Get the configured proxy host."},
    {"config proxy <host>", "cfg p <host>", "Set the proxy server host. E.g. http://proxy:12345"},
    {"config proxy delete", "cfg p delete", "Remove the proxy server host from the configuration."},
    {"config proxy enable", "cfg p enable", "Enable using the proxy server host from the configuration."},
    {"config proxy disable", "cfg p disable", "Disable using the proxy server host from the configuration."},
    {"current", "c", "Print current ruby environment version"},
    {"default", "d", "Use default ruby version (alias: rvm use default)"},
    {"delete <version>", "del <version>", "Delete given ruby environment (alias: remove)"},
    {"fix", "f", "Automatically fix paths and versions in RVM configuration"},
    {"get", "g", "Upgrade RVM to its latest release version"},
    {"help", "h", "Print this usage guide"},
    {"info", "", "Show the environment information for current ruby"},
    {"init", "", "Initialize RVM by adding it to the PATH environment variable"},
    {"install <version>", "i <version>", "Install a specific ruby version"},
    {"kick <version>", "", "Only remove given ruby environment from the RVM list without deleting any ruby environment."},
    {"kit", "k", "Install a bunch of widely used x64 dependencies automatically to the current ruby environment, which are needed to build native gems like postgresql, mysql2, ..."},
    {"list", "l ls", "List all installed ruby versions managed by RVM"},
    {"list all", "la", "List all installable ruby versions"},
    {"list known", "lk", "List all installable ruby versions with latest patch version"},
    {"list upgrades", "lu", "List all installed ruby versions and their available upgrade versions"},
    {"list verbose", "lv", "List all installed ruby versions managed by RVM with additional info"},
    {"mount <path>", "m", "Add a installed ruby environment to the list (alias: add <path>)"},
    {"reinstall <version>", "r <version>", "Delete given ruby environment and install it again."},
    {"remove <version>", "rem <version>", "Delete given ruby environment (alias: uninstall)"},
    {"scan", "", "Scan for ruby installations and add them to the RVM configuration (alias: automount)"},
    {"system", "s", "Use the system ruby (alias: rvm use system)"},
    {"uninstall <version>", "ui <version>", "Delete given ruby environment (alias: remove)"},
    {"upgrade <version>", "up <version>", "Upgrade given version to its latest patch version"},
    {"upgrade <from> <to>", "up <from> <to>", "Upgrade given from_version to given to_version"},
    {"use <version>", "u <version>", "Switch to specified ruby version"},
    {"use --default <version>", "u --default <version>", "Switch to specified ruby version and set it as default"},
    {"version", "v", "Display RVM build version"},
  ]

  def self.missing_version_message(command : String) : String
    usage, example = if command == "upgrade"
                       {"rvm upgrade <version> or rvm upgrade <from_version> <to_version> to upgrade an existing environment", "rvm upgrade ruby-3.0"}
                     else
                       {"rvm #{command} <version>", "rvm #{command} ruby-3.2.2"}
                     end
    "No version given. Run #{usage}, for example: #{example}"
  end

  def self.run_help(io : IO = STDOUT)
    io.puts "\n#{RvmCliColor.style("RVM CLI", :default, io, bold: true)}\n\n  The RVM CLI (rvm) provides several interactive tasks to ensure programmers happyness when working with several ruby environments on windows. 😊"
    io.puts "\n#{RvmCliColor.style("Available tasks", :default, io, bold: true)}\n\n  Use either the full length task name or its shortcut.\n"
    # Pad before adding ANSI escapes so colored columns keep their alignment.
    TASKS.each { |name, shortcut, summary| io.puts "  #{RvmCliColor.primary(name.ljust(27), io)} #{RvmCliColor.primary(shortcut.ljust(22), io)} #{summary}" }
    io.puts "\n#{RvmCliColor.style("Examples", :default, io, bold: true)}\n\n  #{RvmCliColor.primary("rvm version", io)}  Full name task, its shortcut is #{RvmCliColor.primary("v", io)}\n  #{RvmCliColor.primary("rvm h", io)}        Shortcut task for #{RvmCliColor.primary("help", io)}"
  end

  def self.run_unknown_command(task : String, io : IO = STDOUT)
    io.puts "\n#{RvmCliColor.style("Invalid task", :default, io, bold: true)}\n\n  The given task #{RvmCliColor.red(task, io)} is invalid. Run the command with task #{RvmCliColor.primary("help", io)} to get information about valid tasks."
  end
end
