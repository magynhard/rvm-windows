require "../../spec_helper"

describe RvmCliConfig do
  it "can print the configured data directory" do
    Fixtures.with_home do
      io = IO::Memory.new
      RvmCliConfig.print_data(io)
      io.to_s.should contain(RvmCliTools.get_rvm_data_dir)
    end
  end

  it "sets, enables, disables and deletes a proxy without discarding extension fields" do
    Fixtures.with_home do
      io = IO::Memory.new
      RvmCliConfig.run_proxy("proxy:12345", io)
      RvmCliTools.proxy_hostname.should eq("http://proxy:12345")
      RvmCliConfig.run_proxy("disable", io)
      RvmCliTools.proxy_hostname.should be_nil
      RvmCliTools.config["proxy"]["hostname"].as_s.should eq("http://proxy:12345")
      RvmCliConfig.run_proxy("enable", io)
      RvmCliTools.proxy_hostname.should eq("http://proxy:12345")
      RvmCliConfig.run_proxy("delete", io)
      RvmCliTools.config["proxy"]["hostname"].as_s.should eq("")
    end
  end

  it "accepts an existing data directory and rejects a missing one" do
    Fixtures.with_home do |home|
      io = IO::Memory.new
      RvmCliConfig.run_data(home, io)
      RvmCliTools.get_rvm_data_dir.should eq(home)
      RvmCliConfig.run_data(File.join(home, "missing"), io)
      RvmCliTools.get_rvm_data_dir.should eq(home)
      io.to_s.should contain("not a valid directory")
    end
  end
end
