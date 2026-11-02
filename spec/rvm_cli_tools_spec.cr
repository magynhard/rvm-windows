require "spec"
require "../src/cli/tasks/_version"

describe RvmCliVersion do
  it "can return a version" do
    RvmCliVersion.get_version.should contain(".")
  end
end
