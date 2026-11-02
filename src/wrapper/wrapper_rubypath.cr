require "../cli/_wrapper"

module WrapperRubypath
  def self.run(cwd : String, command : String, io : IO = STDOUT) : Int32
    version = Wrapper.get_ruby_version_for_path(cwd)
    if path = Wrapper.get_path_of_matching_ruby_version(version)
      io.puts "set \"RUBYPATH=#{path.tr("/", "\\")}/bin\""
    else
      io.puts "@echo off"
    end
    0
  end
end
