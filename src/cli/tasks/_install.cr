require "../_tools"
require "./_list"
require "./_use"
require "./_config"

class RvmCliInstall
  def self.run_install(version : String, install_dir : String? = nil, io : IO = STDOUT)
    version = RvmCliTools.normalize_version(version)
    releases = RvmCliList.ruby_installer_releases_list(io)
    match = RvmCliTools.matching_version(version, RvmCliList.release_versions(releases))
    unless match
      io.puts "#{RvmCliColor.red("Version #{version} is not available.", io)}\nTo list available versions use:\n#{RvmCliColor.green("\n\trvm list known", io)}"
      return
    end
    if is_already_installed(match)
      io.puts "#{RvmCliColor.yellow("Already installed #{match}.", io)}\nTo reinstall use:\n#{RvmCliColor.green("\n\trvm reinstall #{match}", io)}"
      return
    end
    io.puts "Installing #{RvmCliColor.green(match, io)} ...\n"
    release = releases.find { |entry| "ruby-#{entry.version}" == match }.not_nil!
    destination = File.join(RvmCliTools.get_rvm_data_dir, "downloads", release.url.split('/').last)
    if File.file?(destination)
      io.puts "Found and use cached #{RvmCliColor.green(destination, io)}"
    else
      io.puts "Downloading #{RvmCliColor.green(release.url, io)} ... please wait ..."
      download(release.url, destination)
      io.puts "Download successful!\n"
    end
    run_installer(destination, match, install_dir, io)
  end

  def self.installer_args(install_dir : String) : Array(String)
    ["/verysilent", "/currentuser", "/dir=#{install_dir}", "/tasks=noassocfiles,nomodpath"]
  end

  def self.run_installer(source : String, version : String, install_dir : String? = nil, io : IO = STDOUT)
    install_dir ||= File.join(RvmCliTools.get_rvm_data_dir, "envs", version)
    Dir.mkdir_p(install_dir)
    io.puts "Installing at #{RvmCliColor.green(File.expand_path(install_dir), io)} ... please wait, this task will take some minutes ..."
    remove_ruby_installer_registry_key(version)
    env = {} of String => String
    if proxy = RvmCliTools.proxy_hostname
      env["HTTP_PROXY"] = proxy
      env["HTTPS_PROXY"] = proxy
    end
    status = Process.run(source, installer_args(install_dir), env: env,
      output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
    raise "Installer failed (#{status.exit_code})" unless status.success?
    data = RvmCliTools.config
    RvmCliTools.envs(data).reject! { |_, path| path.as_s == install_dir }
    RvmCliTools.envs(data)[version] = JSON::Any.new(install_dir)
    data.as_h["default"] = JSON::Any.new(version) if (data["default"]?.try(&.as_s?) || "").empty?
    RvmCliTools.write_rvm_config(data)
    RvmCliFix.fix_wrapper_files
    io.puts "Installation complete!\n"
    RvmCliUse.run_use(version, io: io)
    RvmCliConfig.run_default(version, io) unless RvmCliTools.envs.has_key?(RvmCliTools.get_default_version)
    RvmCliTools.kill_running_msys_processes(io)
    io.puts "\nRun #{RvmCliColor.green("rvm kit", io)} to install development tools and a bunch of widely used x64 dependencies automatically."
  end

  def self.registry_search_args(version : String) : Array(String)
    minor = version.sub("ruby-", "").split('.')[0, 2].join('.')
    ["query", "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall", "/f", "RubyInstaller-#{minor}", "/k"]
  end

  def self.remove_ruby_installer_registry_key(version : String)
    args = registry_search_args(version)
    output = RvmCliTools.capture("reg", args)
    marker = args[3]
    output.lines.select(&.includes?(marker)).each do |line|
      key = line.strip
      next if key.empty?
      Process.run("reg", ["delete", key, "/f"], output: Process::Redirect::Close, error: Process::Redirect::Close)
    end
  rescue
    # Missing key or inaccessible registry: original behavior is best effort.
  end

  def self.is_already_installed(version : String) : Bool
    !!RvmCliTools.matching_version(version)
  end

  def self.download(url : String, destination : String)
    return if File.file?(destination)
    download_promise(url, destination)
  end

  def self.download_promise(url : String, destination : String)
    RvmCliTools.make_dir_of_file(destination)
    # Commit the cache entry only after a complete response; do not reuse a
    # partially downloaded installer after a network failure.
    partial = "#{destination}.part-#{Process.pid}"
    begin
      RvmCliTools.fetch_with_proxy(url) do |response|
        File.open(partial, "w") do |file|
          if body = response.body_io?
            IO.copy(body, file)
          else
            file << response.body
          end
        end
      end
      File.rename(partial, destination)
    ensure
      File.delete(partial) if File.file?(partial)
    end
  end
end
