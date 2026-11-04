require "../_wrapper"
require "./_install"

class RvmCliKit
  DEPENDENCIES = {
    "x64-mingw-ucrt" => %w(mingw-w64-ucrt-x86_64-postgresql mingw-w64-ucrt-x86_64-libmariadbclient mingw-w64-ucrt-x86_64-libyaml),
    "x64-mingw32"    => %w(mingw-w64-x86_64-postgresql mingw-w64-x86_64-libmariadbclient mingw-w64-x86_64-libyaml),
  }
  LATEST_SUPPORTED_VERSIONS = {
    "2.4" => {"pg" => "1.2.3", "nokogiri" => "1.10.10"},
    "2.7" => {"nokogiri" => "1.15.6"},
  }

  def self.after_commands(platform : String, ruby_env_path : String, raw_version : String) : Array(String)
    directory = platform == "x64-mingw-ucrt" ? "ucrt64" : "mingw64"
    %w(mysql2 pg eventmachine nokogiri).map do |gem|
      pin = LATEST_SUPPORTED_VERSIONS.find { |version, _| raw_version.starts_with?(version) }.try(&.[1][gem]?)
      if gem == "nokogiri" && platform == "x64-mingw-ucrt"
        # The native gem bundles its libraries. Forcing a source build invokes
        # libiconv/libtool, which cannot reliably handle Ruby paths with spaces.
        "gem install nokogiri --platform=#{platform}"
      else
        "gem install #{gem} #{pin ? "-v #{pin} " : ""}--platform=ruby -- --with-mysql-dir=\"#{RvmCliTools.normalize_path(ruby_env_path)}/msys64/#{directory}\""
      end
    end
  end

  def self.run_kit(io : IO = STDOUT)
    ruby_env_path = Wrapper.get_path_of_matching_ruby_version(Wrapper.get_ruby_version_for_path(Dir.current)) || raise "No current Ruby environment"
    io.puts "Installing a bunch of helpful dependencies for building native gems ...\n"
    install_ridk_tools(io)
    io.puts "Updating pacman dependencies ...\n"
    platform = RvmCliFix.get_ruby_platform_from_ruby_path(ruby_env_path)
    if dependencies = DEPENDENCIES[platform]?
      dependencies.each do |dependency|
        io.puts "Installing pacman dependency #{RvmCliColor.primary(dependency, io)} ..."
        install_pacman_dependency(dependency)
      end
      after_commands(platform, ruby_env_path, RvmCliTools.get_current_raw_version).each do |command|
        io.puts "Running fix command #{RvmCliColor.primary(command, io)} ..."
        RvmCliTools.run_shell(command)
      end
      io.puts "\nInstallation complete!"
    else
      io.puts "Platform invalid or not supported: #{platform}"
    end
  end

  def self.install_pacman_dependency(dependency : String)
    dependency = dependency.split.first
    RvmCliTools.run_shell(%Q(chcp 65001 > NUL && ridk exec sh -c "pacman --noconfirm -S #{dependency}"))
  end

  def self.install_ridk_tools(io : IO = STDOUT)
    RvmCliTools.kill_running_msys_processes(io)
    io.puts "Ensure ridk tools are installed ... please wait ..."
    version = RvmCliTools.get_current_raw_version
    if version.starts_with?("2.4.") || version.starts_with?("2.5.")
      old_version = RvmCliTools.get_current_version
      unless RvmCliTools.matching_version("ruby-2.6")
        io.puts "Installing #{RvmCliColor.primary("ruby-2.6.x", io)} to patch current #{RvmCliColor.primary(old_version, io)} with its msys64 ... please wait ..."
        RvmCliInstall.run_install("2.6", io: io)
        RvmCliUse.run_use(old_version, io: io)
      end
      matching = RvmCliTools.matching_version("ruby-2.6") || raise "Ruby 2.6 required for MSYS patch"
      io.puts "Patch current version #{RvmCliColor.primary(old_version, io)} with msys from #{RvmCliColor.primary(matching, io)} ... please wait ..."
      source = File.join(RvmCliTools.envs[matching].as_s, "msys64")
      target = File.join(RvmCliTools.envs[old_version].as_s, "msys64")
      FileUtils.rm_rf(target)
      FileUtils.cp_r(source, target)
      io.puts "Patch complete!\n\nUpdating dev tools by ridk ... please wait ...\n"
    end
    RvmCliTools.run_shell("chcp 65001 > NUL && ridk install 1 2 3")
    RvmCliTools.run_shell("ridk exec pacman --noconfirm -Sy")
  end
end
