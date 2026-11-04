require "../cli/_wrapper"

module WrapperProxy
  def self.run(cwd : String, command : String, io : IO = STDOUT) : Int32
    Wrapper.get_ruby_version_for_path(cwd)
    io.puts RvmCliTools.proxy_hostname || ""
    0
  end
end
