require "../_tools"
require "./_fix"

class RvmCliInfo
  def self.run_info(io : IO = STDOUT)
    version = RvmCliTools.get_current_version
    path = RvmCliTools.envs[version].as_s
    description = RvmCliFix.ruby_description(path).strip
    command_path = RvmCliTools.capture("where", ["rvm"]).lines.map(&.strip).reject(&.empty?).join(" - ")
    os_version = RvmCliTools.shell("ver").strip
    os_name = "Microsoft Windows"
    architecture = ENV["PROCESSOR_ARCHITECTURE"]? == "ARM64" ? "arm64" : "x64"
    io.puts "\n#{version}\n\n  system:"
    io.puts "    uname:        #{os_name} (#{os_version}) [#{architecture}]"
    io.puts "    name:         #{os_name}\n    version:      #{os_version}\n    architecture: #{architecture}\n    bash:         CMD"
    io.puts "\n  rvm:\n    version:      #{RvmCliVersion.get_version}\n    path:         #{RvmCliTools.rvm_root_path}\n    command_path: #{command_path}\n    data_path:    #{RvmCliTools.get_rvm_data_dir}"
    io.puts "\n  ruby:\n    interpreter:  ruby\n    version:      #{RvmCliTools.get_current_raw_version}"
    io.puts "    date:         #{description.match(/\(([^\s]+).*\)/).try(&.[1])}"
    io.puts "    platform:     #{description.match(/\[([^\]]+)\]/).try(&.[1])}"
    io.puts "    patchlevel:   #{description.match(/\(([^\]]+)\)/).try(&.[1])}"
    io.puts "    full_version: #{description}\n\n  homes:\n    ruby:  #{File.expand_path(path)}"
  end
end
