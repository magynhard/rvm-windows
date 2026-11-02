require "../_tools"

class RvmCliCurrent
  def self.run_current(io : IO = STDOUT)
    io.puts RvmCliTools.get_current_version
  end
end
