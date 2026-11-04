require "./_use"

class RvmCliDefault
  def self.run_default(io : IO = STDOUT)
    RvmCliUse.run_use("default", io: io)
  end
end
