require "../cli/_tools"
require "../cli/tasks/_fix"
require "digest/sha256"
require "semantic_version"

{% if flag?(:win32) %}
  @[Link("kernel32")]
  lib MigrationKernel32
    fun get_file_attributes = GetFileAttributesW(path : UInt16*) : UInt32
  end
{% end %}

# Temporary compatibility boundary. Installers prepare migrations; explicit
# init may retry committed jobs. Everyday commands/wrappers never discover or
# remove other installations.
class LegacyInstallationMigration
  getter root : String

  def initialize(@root = RvmCliTools.rvm_root_path)
    @root = File.expand_path(@root)
  end

  def self.path_key(path : String) : String
    File.expand_path(path).tr("\\", "/").rstrip('/').downcase
  end

  def self.inside?(path : String, directory : String) : Bool
    path = path_key(path)
    directory = path_key(directory)
    path == directory || path.starts_with?("#{directory}/")
  end

  def self.candidate_prefixes : Array(String)
    paths = (ENV["PATH"]? || "").split(';').reject(&.empty?)
    if appdata = ENV["APPDATA"]?
      paths << File.join(appdata, "npm")
    end
    if prefix = ENV["npm_config_prefix"]?
      paths << prefix
    end
    paths.map { |path| File.expand_path(path.strip('"')) }.uniq { |path| path_key(path) }
  end

  def package_path(prefix : String) : String
    File.join(File.expand_path(prefix), "node_modules", "rvm-windows")
  end

  private def linked_path?(path : String) : Bool
    current = File.expand_path(path)
    loop do
      {% if flag?(:win32) %}
        wide = current.to_utf16.to_a << 0_u16
        attributes = MigrationKernel32.get_file_attributes(wide.to_unsafe)
        return true if attributes == UInt32::MAX || attributes.bits_set?(0x400_u32)
      {% else %}
        return true if File.symlink?(current)
      {% end %}
      parent = File.dirname(current)
      break if parent == current
      current = parent
    end
    false
  end

  # Refuse linked development checkouts, current bridges, unrelated packages,
  # unrecognised versions and any package containing shared/user/native data.
  def legacy?(prefix : String) : Bool
    package = package_path(prefix)
    return false unless File.directory?(package)
    return false if linked_path?(package) || linked_path?(File.join(package, "package.json"))
    return false unless self.class.path_key(File.realpath(package)) == self.class.path_key(package)
    manifest = JSON.parse(File.read(File.join(package, "package.json")))
    return false unless manifest["name"]?.try(&.as_s?) == "rvm-windows"
    return false if manifest["rvmWindowsBridge"]?
    return false unless manifest["main"]?.try(&.as_s?) == "src/cli/cli.js"
    return false unless manifest["bin"]?.try(&.as_h?).try(&.["rvm"]?).try(&.as_s?) == "src/cli/cli.js"
    version = SemanticVersion.parse(manifest["version"].as_s)
    return false unless version < SemanticVersion.parse("1.1.0")
    return false unless File.file?(File.join(package, "src/cli/cli.js"))
    protected_paths = [root, RvmCliTools.home_path, RvmCliTools.rvm_config_path, RvmCliTools.rvm_sessions_dir]
    if File.file?(RvmCliTools.rvm_config_path)
      protected_paths << RvmCliTools.get_rvm_data_dir
      RvmCliTools.envs.each_value { |value| protected_paths << value.as_s }
    end
    !protected_paths.any? { |path| self.class.inside?(path, package) }
  rescue
    false
  end

  def discover(prefixes = self.class.candidate_prefixes) : Array(String)
    prefixes.map { |path| File.expand_path(path) }.uniq { |path| self.class.path_key(path) }.select { |prefix| legacy?(prefix) }
  end

  def self.active_ruby?(commands : Array(String), ruby_roots : Array(String)) : Bool
    commands.any? do |command|
      command = command.downcase.tr("\\", "/")
      ruby_roots.any? do |root|
        %w(ruby.exe rubyw.exe).any? { |name| command.includes?("#{path_key(root)}/bin/#{name}") }
      end
    end
  end

  def ensure_no_active_ruby
    return unless File.file?(RvmCliTools.rvm_config_path)
    roots = RvmCliTools.envs.values.map(&.as_s)
    return if roots.empty?
    script = "ConvertTo-Json -Compress -InputObject @(Get-CimInstance Win32_Process -Filter \"Name='ruby.exe' OR Name='rubyw.exe'\" -ErrorAction Stop | ForEach-Object { [string]$_.CommandLine })"
    result = RvmCliTools.capture("powershell.exe", ["-NoProfile", "-Command", "$ErrorActionPreference='Stop'; [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false); #{script}"])
    if self.class.active_ruby?(JSON.parse(result).as_a.map(&.as_s), roots)
      raise "Close running RVM Ruby tools (including IRB and Ruby servers) before updating; their batch wrappers may still be in use."
    end
  end

  private def pointer : String
    File.join(root, ".legacy-migration.json")
  end

  private def jobs_root : String
    File.join(RvmCliTools.home_path, ".rvm", "migration")
  end

  private def wrapper_path : String
    File.join(File.file?(RvmCliTools.rvm_config_path) ? RvmCliTools.get_rvm_data_dir : RvmCliTools.get_default_rvm_data_dir, "wrapper")
  end

  def prepare(prefixes = self.class.candidate_prefixes)
    raise "An unfinished installation migration exists: #{pointer}" if File.exists?(pointer)
    # Parsing before any wrapper changes prevents a damaged config from being
    # silently replaced. The original bytes (including extension fields) survive.
    RvmCliTools.config if File.file?(RvmCliTools.rvm_config_path)
    candidates = discover(prefixes).map do |prefix|
      {"prefix" => prefix, "manifest_sha256" => Digest::SHA256.hexdigest(File.read(File.join(package_path(prefix), "package.json")))}
    end
    job = File.join(jobs_root, "#{Time.utc.to_unix_ms}-#{Random::Secure.hex(8)}")
    Dir.mkdir_p(job)
    if File.file?(RvmCliTools.rvm_config_path)
      FileUtils.cp(RvmCliTools.rvm_config_path, File.join(job, "config.json"))
    end
    if File.directory?(wrapper_path)
      FileUtils.cp_r(wrapper_path, File.join(job, "wrappers"))
    end
    state = {"schema" => 1, "root" => root, "wrapper" => wrapper_path, "job" => job, "candidates" => candidates}.to_json
    File.write(File.join(job, "state.json"), state)
    File.write(pointer, state)
  end

  private def read_job(file : String) : JSON::Any
    state = JSON.parse(File.read(file))
    raise "Invalid migration state" unless state["schema"].as_i == 1 && self.class.path_key(state["root"].as_s) == self.class.path_key(root)
    job = state["job"].as_s
    raise "Invalid migration backup path" unless self.class.inside?(job, jobs_root) && self.class.path_key(job) != self.class.path_key(jobs_root)
    raise "Invalid migration wrapper path" unless self.class.path_key(state["wrapper"].as_s) == self.class.path_key(wrapper_path)
    state
  end

  def rollback
    return unless File.file?(pointer)
    state = read_job(pointer)
    # Never overwrite files another installation may have created meanwhile.
    RvmCliFix.remove_package_wrappers
    backup = File.join(state["job"].as_s, "wrappers")
    if File.directory?(backup)
      Dir.mkdir_p(wrapper_path)
      Dir.children(backup).each do |name|
        source = File.join(backup, name)
        destination = File.join(wrapper_path, name)
        FileUtils.cp(source, destination) if File.file?(source) && !File.exists?(destination)
      end
    end
    File.delete(pointer)
    File.write(File.join(state["job"].as_s, "cancelled"), "rollback\n")
    # Keep the backup and log for diagnosis. Config is never rewritten here.
  end

  def commit(start_worker = true) : String
    state = read_job(pointer)
    job_file = File.join(state["job"].as_s, "state.json")
    File.write(File.join(state["job"].as_s, "committed"), "installed\n")
    File.delete(pointer)
    File.write(File.join(state["job"].as_s, "done"), "no legacy packages\n") if state["candidates"].as_a.empty?
    start_cleanup(job_file) if start_worker && !state["candidates"].as_a.empty?
    job_file
  end

  private def start_cleanup(job_file : String)
    log = File.open(File.join(File.dirname(job_file), "cleanup.log"), "a")
    begin
      Process.new(Process.executable_path.not_nil!, ["--internal-migration", "cleanup", job_file],
        input: Process::Redirect::Close, output: log, error: log,
        env: {"RVM_ROOT" => root})
    ensure
      log.close
    end
  end

  def retry(io : IO = STDOUT)
    Dir.glob(File.join(jobs_root, "*/state.json")).each do |file|
      begin
        job = File.dirname(file)
        next unless File.file?(File.join(job, "committed"))
        next if File.exists?(File.join(job, "done")) || File.exists?(File.join(job, "cancelled"))
        state = JSON.parse(File.read(file))
        next unless self.class.path_key(state["root"].as_s) == self.class.path_key(root)
        start_cleanup(file)
      rescue ex
        io.puts "Could not retry migration #{file}: #{ex.message}"
      end
    end
  end

  # The uninstall action is injected in tests; it is never invoked against a
  # real package manager or user installation by the offline suite.
  def cleanup_with(job_file : String, io : IO = STDOUT, &uninstall : String -> Bool) : Bool
    state = read_job(job_file)
    raise "Migration was not committed" unless File.file?(File.join(state["job"].as_s, "committed"))
    return true if File.file?(File.join(state["job"].as_s, "done"))
    success = true
    state["candidates"].as_a.each do |candidate|
      prefix = candidate["prefix"].as_s
      next unless legacy?(prefix)
      manifest = File.join(package_path(prefix), "package.json")
      next unless Digest::SHA256.hexdigest(File.read(manifest)) == candidate["manifest_sha256"].as_s
      if yield prefix
        io.puts "Removed previous RVM package from #{prefix}."
      else
        io.puts "Could not remove previous RVM package from #{prefix}. Native RVM is installed; remove the old package manually."
        success = false
      end
    end
    File.write(File.join(state["job"].as_s, "done"), "complete\n") if success
    success
  end

  def cleanup(job_file : String, io : IO = STDOUT) : Bool
    state = read_job(job_file)
    raise "Migration was not committed" unless File.file?(File.join(state["job"].as_s, "committed"))
    return true if File.file?(File.join(state["job"].as_s, "done"))
    prefixes = state["candidates"].as_a.map { |candidate| candidate["prefix"].as_s }
    # An old `rvm get` or another npm operation may still be running. Do not
    # uninstall from inside an npm lifecycle, or delete files in active use.
    120.times do
      break unless busy?(prefixes)
      sleep 1.second
    end
    if busy?(prefixes)
      io.puts "Migration cleanup postponed: a package-manager/legacy process is still running. Run rvm init after it exits."
      return false
    end
    npm = Process.find_executable("npm.cmd")
    node = Process.find_executable("node.exe")
    cli = npm.try { |path| File.join(File.dirname(path), "node_modules/npm/bin/npm-cli.js") }
    unless node && cli && File.file?(cli)
      io.puts "Migration cleanup requires npm. Remove the previous global rvm-windows package manually."
      return false
    end
    cleanup_with(job_file, io) do |prefix|
      status = Process.run(node, [cli] + self.class.uninstall_arguments(prefix), output: io, error: io)
      status.success? && !File.directory?(package_path(prefix))
    end
  end

  def self.uninstall_arguments(prefix : String) : Array(String)
    ["uninstall", "--global", "--prefix", prefix, "--ignore-scripts", "--no-audit", "--no-fund", "rvm-windows"]
  end

  def self.busy_commands?(commands : Array(String), prefixes : Array(String)) : Bool
    commands = commands.map { |command| command.downcase.tr("\\", "/") }.join('\n')
    commands.includes?("npm-cli.js") || prefixes.any? { |prefix| commands.includes?(path_key(File.join(prefix, "node_modules/rvm-windows"))) }
  end

  private def busy?(prefixes : Array(String)) : Bool
    script = "ConvertTo-Json -Compress -InputObject @(Get-CimInstance Win32_Process -Filter \"Name='node.exe' OR Name='npm.exe'\" -ErrorAction Stop | ForEach-Object { [string]$_.CommandLine })"
    result = RvmCliTools.capture("powershell.exe", ["-NoProfile", "-Command", "$ErrorActionPreference='Stop'; [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false); #{script}"])
    self.class.busy_commands?(JSON.parse(result).as_a.map(&.as_s), prefixes)
  rescue
    # If process discovery is unavailable, leave old packages untouched.
    true
  end
end
