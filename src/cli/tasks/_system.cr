require "./_use"

class RvmCliSystem
  def self.run_system(io : IO = STDOUT)
    RvmCliUse.run_use("system", io: io)
  end
end
