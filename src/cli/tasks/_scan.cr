require "../_tools"
require "./_fix"
require "./_list"

class RvmCliScan
  def self.run_scan(io : IO = STDOUT)
    io.puts "Scanning for installed rubies and add them to list ...\n"
    scan_missing_environment_paths
    RvmCliFix.fix_environment_versions
    RvmCliFix.fix_wrapper_files
    RvmCliList.run_list_verbose(io)
  end

  def self.scan_missing_environment_paths(write = true) : Array(String)
    # The original's shadowed local discards `where ruby` output. Preserve the
    # resulting search locations rather than silently broadening the scan.
    patterns = ["C:/Program Files/Ruby*", "C:/Ruby*", "#{RvmCliTools.get_rvm_data_dir}/envs/*"]
    paths = patterns.flat_map { |pattern| Dir.glob(RvmCliTools.normalize_path(pattern)) }
    data = RvmCliTools.config
    paths.each_with_index do |path, i|
      path = RvmCliTools.normalize_path(path.strip).sub("/bin/ruby.exe", "")
      RvmCliTools.envs(data)["unknown_#{i}"] = JSON::Any.new(path)
    end
    RvmCliTools.write_rvm_config(data) if write
    paths
  end
end
