class RvmCliVersion
  VERSION = {{ read_file("#{__DIR__}/../../../shard.yml").split("version: ")[1].split('\n')[0].strip }}

  def self.get_version : String
    VERSION
  end

  def self.get_full_version : String
    "rvm-windows #{get_version}"
  end

  def self.run_version(io : IO = STDOUT)
    io.puts get_full_version
  end
end
