require "../cli/_tools"

module WrapperPath
  def self.run(cwd : String, command : String, io : IO = STDOUT) : Int32
    path = "#{RvmCliTools.get_rvm_data_dir}\\wrapper".tr("/", "\\")
    io.puts RvmCliTools.get_current_version == "system" ? "@echo off" : "set \"PATH=#{path};%PATH%\""
    0
  end
end
