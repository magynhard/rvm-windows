require "./spec_helper"

describe RvmCliVersion do
  it "can return a version" do
    RvmCliVersion.get_version.should contain(".")
  end
end

describe RvmCliTools do
  it "sorts numeric version components and matches the highest partial version" do
    versions = %w(ruby-3.2.9 ruby-3.2.10 ruby-2.4.10 ruby-3.10.1)
    RvmCliTools.matching_version("ruby-3.2", versions).should eq("ruby-3.2.10")
    RvmCliTools.matching_version("ruby-3", versions).should eq("ruby-3.10.1")
    RvmCliTools.matching_version("ruby-3.2.9", versions).should eq("ruby-3.2.9")
    RvmCliTools.matching_version("ruby-3.2.8", versions).should be_nil
  end

  it "preserves unknown config fields and reads/writes compatible session files" do
    Fixtures.with_home do
      data = RvmCliTools.config
      data.as_h["extension"] = JSON.parse(%({"keep": [1, true, "yes"]}))
      RvmCliTools.write_rvm_config(data)
      RvmCliTools.get_current_version.should eq("ruby-3.2.6")
      RvmCliTools.set_current_version("ruby-3.1.5")
      RvmCliTools.get_current_version.should eq("ruby-3.1.5")
      RvmCliTools.set_default_version("3.0", IO::Memory.new)
      RvmCliTools.config["extension"].should eq(data["extension"])
      RvmCliTools.get_default_version.should eq("ruby-3.0.7")
    end
  end

  it "filters intermediate directories" do
    RvmCliTools.filter_deep_dirs_only(%w(a/b/c a/b a/b/c/d e/f e/f/g/h i/j))
      .should eq(%w(a/b/c/d e/f/g/h i/j))
  end
end
