require "json"
require "file_utils"
require "http/client"
require "base64"
require "./tasks/_version"
require "./_color"

class RvmCliTools
  # These overrides are also passed to subprocesses by the isolated test harness.
  # Without them, all paths are exactly those of the JavaScript implementation.
  def self.home_path : String
    ENV["RVM_HOME"]? || Path.home.to_s
  end

  def self.rvm_root_path : String
    ENV["RVM_ROOT"]? || File.dirname(File.dirname(Process.executable_path.not_nil!))
  end

  def self.project_root_path : String
    Dir.current
  end

  def self.rvm_config_path : String
    File.join(home_path, ".rvm.json")
  end

  def self.rvm_sessions_dir : String
    File.join(home_path, ".rvm", "sessions")
  end

  def self.rvm_config_template_path : String
    File.join(rvm_root_path, "src", "templates", ".rvm.json")
  end

  def self.rvm_batch_template_path : String
    File.join(rvm_root_path, "src", "templates", "wrapper_template.bat")
  end

  def self.read_rvm_config : String
    File.read(rvm_config_path)
  end

  # JSON::Any intentionally preserves unknown fields from an existing installation.
  def self.config : JSON::Any
    JSON.parse(read_rvm_config)
  end

  def self.write_rvm_config(content : JSON::Any | String)
    write_file(rvm_config_path, content.is_a?(String) ? content : content.to_pretty_json)
  end

  def self.envs(config = self.config) : Hash(String, JSON::Any)
    config["envs"].as_h
  end

  def self.get_default_rvm_data_dir : String
    File.expand_path("C:/ProgramData/rvm")
  end

  def self.get_rvm_data_dir : String
    dir = config["rvm_data_dir"]?.try(&.as_s?)
    (dir && !dir.empty? ? dir : get_default_rvm_data_dir).rstrip("/\\")
  end

  def self.normalize_path(path : String) : String
    path.tr("\\", "/")
  end

  def self.starts_with_number(content : String?) : Bool
    !!content.try(&.matches?(/\A[0-9]/))
  end

  def self.normalize_version(version : String) : String
    starts_with_number(version) ? "ruby-#{version}" : version
  end

  def self.version_parts(version : String) : Array(Int32)
    parts = version.sub("ruby-", "").split('.')
    (0..2).map { |i| parts[i]?.try(&.to_i?) || 0 }
  end

  def self.version_sort(a : String, b : String) : Int32
    version_parts(a) <=> version_parts(b)
  end

  def self.versions : Array(String)
    envs.keys.sort { |a, b| version_sort(a, b) }
  end

  def self.raw_versions : Array(String)
    versions.map(&.sub("ruby-", ""))
  end

  def self.matching_version(version : String, versions : Array(String) = self.versions) : String?
    return version if versions.includes?(version)
    return unless version.split('.').size <= 2
    versions.sort { |a, b| version_sort(b, a) }.find(&.starts_with?("#{version}."))
  end

  def self.get_default_version : String
    config["default"]?.try(&.as_s?) || ""
  end

  def self.get_current_version : String
    if session = ENV["RVM_SESSION"]?
      file = File.join(rvm_sessions_dir, session)
      return File.read(file) if File.file?(file)
    end
    get_default_version
  end

  def self.get_current_raw_version : String
    get_current_version.sub("ruby-", "")
  end

  def self.set_current_version(version : String)
    if session = ENV["RVM_SESSION"]?
      write_file(File.join(rvm_sessions_dir, session), version) unless version.empty?
    end
  end

  def self.set_default_version(version : String, io : IO = STDOUT)
    version = normalize_version(version)
    if match = matching_version(version)
      data = config
      data.as_h["default"] = JSON::Any.new(match)
      write_rvm_config(data)
      io.puts "Set default #{RvmCliColor.primary(match, io)} from #{RvmCliColor.primary(envs(data)[match].as_s, io)} ..."
    else
      io.puts "No version for #{RvmCliColor.red(version, io)} available! Run #{RvmCliColor.primary("rvm list", io)} to show available versions."
    end
  end

  def self.make_dir(dir : String)
    Dir.mkdir_p(dir)
  end

  def self.make_dir_of_file(file : String)
    Dir.mkdir_p(File.dirname(file))
  end

  def self.read_file(path : String) : String
    File.read(path)
  end

  def self.write_file(path : String, content : String)
    make_dir_of_file(path)
    File.write(path, content)
  end

  def self.copy_file(source : String, destination : String)
    make_dir_of_file(destination)
    FileUtils.cp(source, destination)
  end

  def self.copy(source : String, destination : String)
    FileUtils.cp_r(source, destination)
  end

  def self.is_dir(path : String) : Bool
    File.directory?(path)
  end

  def self.is_file(path : String) : Bool
    File.file?(path)
  end

  def self.path_exists(path : String) : Bool
    File.exists?(path)
  end

  def self.remove_path(path : String)
    FileUtils.rm_rf(path)
  end

  def self.escape_reg_exp(value : String) : String
    Regex.escape(value)
  end

  def self.uniq_array(values : Array(T)) : Array(T) forall T
    values.uniq
  end

  def self.filter_deep_dirs_only(dirs : Array(String)) : Array(String)
    dirs.select { |dir| dirs.count(&.includes?(dir)) == 1 }
  end

  def self.print_line(text = "", io : IO = STDOUT)
    io.puts "  #{text}"
  end

  def self.print(text = "", io : IO = STDOUT)
    io.print "  #{text}"
  end

  def self.cli_question(question : String, options : Array(String)? = nil,
                        preselected_option : String? = nil, mandatory = false,
                        input : IO = STDIN, output : IO = STDOUT) : String
    loop do
      output.print "  #{question}#{preselected_option ? " [#{RvmCliColor.primary(preselected_option, output)}]" : ""}: "
      answer = input.gets || raise "Input cancelled"
      answer = answer.chomp
      answer = preselected_option || "" if answer.empty?
      next if mandatory && answer.empty?
      return answer if options.nil? || options.empty? || options.includes?(answer)
      output.puts "\n  #{RvmCliColor.red("Invalid input '#{answer}'.", output)}\n  Valid options are: #{options.map { |option| RvmCliColor.primary(option, output) }.join(" | ")}\n"
    end
  end

  def self.capture(command : String, args : Array(String) = [] of String) : String
    output = IO::Memory.new
    error = IO::Memory.new
    status = Process.run(command, args, output: output, error: error)
    raise "Command failed (#{status.exit_code}): #{command}\n#{error}" unless status.success?
    output.to_s
  end

  def self.shell(command : String) : String
    output = IO::Memory.new
    error = IO::Memory.new
    status = Process.run(command, shell: true, output: output, error: error)
    raise "Command failed (#{status.exit_code}): #{command}\n#{error}" unless status.success?
    output.to_s
  end

  def self.run_shell(command : String)
    status = Process.run(command, shell: true,
      input: Process::Redirect::Inherit, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
    raise "Command failed (#{status.exit_code}): #{command}" unless status.success?
  end

  def self.kill_running_msys_processes(io : IO = STDOUT)
    io.puts "Kill running msys processes ..."
    %w(msys2.exe ucrt64.exe mingw64.exe mingw32.exe clang64.exe clang32.exe msys2_shell.cmd autorebase.cmd).each do |name|
      Process.run("taskkill", ["/f", "/im", name], output: Process::Redirect::Close, error: Process::Redirect::Close)
    end
    Process.run("taskkill", ["/f", "/fi", "MODULES eq msys-2.0.dll"], output: Process::Redirect::Close, error: Process::Redirect::Close)
  end

  def self.proxy_hostname : String?
    proxy = config["proxy"]?.try(&.as_h?)
    return unless proxy && proxy["enabled"]?.try(&.as_bool?)
    host = proxy["hostname"]?.try(&.as_s?)
    host unless host.try(&.empty?)
  end

  # HTTPS through an HTTP proxy uses CONNECT, including Basic authentication.
  # Network bodies are streamed; installers are never buffered in memory.
  def self.fetch_with_proxy(url : String, redirects = 10, &block : HTTP::Client::Response -> T) : T forall T
    raise "Too many redirects" if redirects < 0
    uri = URI.parse(url)
    host = uri.host || raise "Missing URL host"
    port = uri.port || (uri.scheme == "https" ? 443 : 80)
    headers = HTTP::Headers{"User-Agent" => "rvm-windows/#{RvmCliVersion.get_version}", "Accept" => "*/*"}
    resource = uri.request_target
    client = if proxy_host = proxy_hostname
               proxy = URI.parse(ENV["HTTPS_PROXY"]? || proxy_host)
               proxy_name = proxy.host || raise "Missing proxy host"
               raise "Unsupported proxy scheme" unless proxy.scheme.in?("http", "https")
               tcp = TCPSocket.new(proxy_name, proxy.port || (proxy.scheme == "https" ? 443 : 80))
               socket = proxy.scheme == "https" ? OpenSSL::SSL::Socket::Client.new(tcp, hostname: proxy_name, sync_close: true) : tcp
               if user = proxy.user
                 auth = Base64.strict_encode("#{URI.decode(user)}:#{URI.decode(proxy.password || "")}")
                 headers["Proxy-Authorization"] = "Basic #{auth}"
               end
               if uri.scheme == "https"
                 socket << "CONNECT #{host}:#{port} HTTP/1.1\r\nHost: #{host}:#{port}\r\n"
                 if auth_header = headers["Proxy-Authorization"]?
                   socket << "Proxy-Authorization: #{auth_header}\r\n"
                 end
                 socket << "\r\n"
                 socket.flush
                 status_line = socket.gets(chomp: false) || raise "Proxy closed connection"
                 until (line = socket.gets(chomp: false)).nil? || line == "\r\n" || line == "\n"
                 end
                 unless status_line.split[1]? == "200"
                   socket.close
                   raise "Proxy CONNECT failed: #{status_line.strip}"
                 end
                 headers.delete("Proxy-Authorization")
                 tls = OpenSSL::SSL::Socket::Client.new(socket, hostname: host, sync_close: true)
                 HTTP::Client.new(tls, host, port)
               else
                 resource = url
                 HTTP::Client.new(socket, host, port)
               end
             else
               HTTP::Client.new(uri)
             end
    begin
      client.get(resource, headers: headers) do |response|
        if response.status_code.in?(301, 302, 303, 307, 308)
          location = response.headers["Location"]? || raise "Redirect without Location"
          fetch_with_proxy(uri.resolve(location).to_s, redirects - 1, &block)
        else
          raise "HTTP #{response.status_code} retrieving #{url}" unless response.success?
          block.call(response)
        end
      end
    ensure
      client.close
    end
  end

  def self.fetch_text(url : String) : String
    fetch_with_proxy(url) { |response| response.body_io?.try(&.gets_to_end) || response.body }
  end

  def self.logo(io : IO = STDOUT) : String
    art = "\n      ██████╗  ██╗   ██╗ ███╗   ███╗\n      ██╔══██╗ ██║   ██║ ████╗ ████║\n      ██████╔╝ ██║   ██║ ██╔████╔██║\n      ██╔══██╗ ╚██╗ ██╔╝ ██║╚██╔╝██║\n      ██║  ██║  ╚████╔╝  ██║ ╚═╝ ██║\n      ╚═╝  ╚═╝   ╚═══╝   ╚═╝     ╚═╝\n\n"
    RvmCliColor.style(art, :light_red, io, bold: true) +
      "      " + RvmCliColor.style("Ruby Version Manager", :light_red, io, bold: true) +
      RvmCliColor.style(" 4 ", :light_gray, io, bold: true) +
      RvmCliColor.primary("Windows", io, bold: true) +
      "\n                #{RvmCliColor.style(RvmCliVersion.get_version, :light_gray, io)}\n"
  end
end
