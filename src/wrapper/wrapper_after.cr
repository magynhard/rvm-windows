require "../cli/_wrapper"
require "../cli/tasks/_fix"

module WrapperAfter
  def self.run(cwd : String, command : String, io : IO = STDOUT) : Int32
    Wrapper.get_ruby_version_for_path(cwd)
    RvmCliFix.fix_wrapper_files if command.split('.').first.in?("gem", "bundle")
    0
  end
end
