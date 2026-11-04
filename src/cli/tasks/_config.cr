require "../_tools"

class RvmCliConfig
  def self.run_config(args : Array(String), io : IO = STDOUT)
    case args.first?
    when "d", "default" then run_default(args[1]?, io)
    when "p", "proxy"   then run_proxy(args[1]?, io)
    when "dt", "data"   then run_data(args[1]?, io)
    else                     print_config(io)
    end
  end

  def self.print_config(io : IO = STDOUT)
    io.puts "RVM configuration at #{RvmCliColor.primary(RvmCliTools.rvm_config_path, io)}\n\n#{RvmCliTools.config.to_pretty_json}"
  end

  def self.run_default(version : String? = nil, io : IO = STDOUT)
    version ? RvmCliTools.set_default_version(version, io) : print_default(io)
  end

  def self.print_default(io : IO = STDOUT)
    version = RvmCliTools.get_default_version
    io.puts version.empty? ? "There is no default ruby version set. To set, run #{RvmCliColor.primary("rvm default <version>", io)}" : version
  end

  def self.print_data(io : IO = STDOUT)
    io.puts "RVM data directory at #{RvmCliColor.primary(RvmCliTools.get_rvm_data_dir, io)}"
  end

  def self.run_data(path : String? = nil, io : IO = STDOUT)
    if path && !path.strip.empty?
      path = File.expand_path(path.strip)
      if File.directory?(path)
        data = RvmCliTools.config
        data.as_h["rvm_data_dir"] = JSON::Any.new(path)
        RvmCliTools.write_rvm_config(data)
      else
        io.puts "Given path #{RvmCliColor.red(path, io)} is not a valid directory!"
      end
    end
    print_data(io)
  end

  def self.run_proxy(hostname : String? = nil, io : IO = STDOUT)
    hostname = hostname.try(&.strip) || ""
    data = RvmCliTools.config
    proxy = data["proxy"]?.try(&.as_h?) || {} of String => JSON::Any
    unless hostname.empty?
      case hostname
      when "delete"
        proxy["hostname"] = JSON::Any.new("")
        io.puts "Removed proxy configuration!"
      when "enable", "disable"
        enabled = hostname == "enable"
        proxy["enabled"] = JSON::Any.new(enabled)
        io.puts enabled ? "Enabled proxy!" : "Disabled proxy!"
        io.puts "#{proxy["hostname"]?.try(&.as_s?) || ""} [#{proxy_status(enabled, io)}]"
      else
        hostname = "http://#{hostname}" unless hostname.starts_with?("http")
        proxy["hostname"] = JSON::Any.new(hostname)
        proxy["enabled"] = JSON::Any.new(true)
        io.puts "Set proxy #{RvmCliColor.primary(hostname, io)} ... [#{proxy_status(true, io)}]"
      end
      data.as_h["proxy"] = JSON::Any.new(proxy)
      RvmCliTools.write_rvm_config(data)
    else
      host = proxy["hostname"]?.try(&.as_s?) || ""
      enabled = proxy["enabled"]?.try(&.as_bool?) || false
      io.puts host.empty? ? "No proxy configured!" : "#{host} [#{proxy_status(enabled, io)}]"
    end
  end

  def self.proxy_status(enabled : Bool, io : IO = STDOUT) : String
    enabled ? RvmCliColor.green("enabled", io) : RvmCliColor.red("disabled", io)
  end
end
