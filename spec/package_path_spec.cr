require "./spec_helper"

describe "NSIS PATH helper (preview only, no registry writes)" do
  it "preserves long paths and unexpanded variables while deduplicating owned entries" do
    root = "C:\\Author Software\\rvm"
    wrapper = "C:\\ProgramData\\rvm\\wrapper"
    entries = (1..250).map { |i| "C:\\some-long-existing-directory-#{i}\\bin" }
    raw = (["%USERPROFILE%\\bin", root.downcase, wrapper.downcase] + entries).join(';')
    script = File.expand_path("../src/tools/path/package_path.ps1", __DIR__)
    result = RvmCliTools.capture("powershell.exe", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script,
                                                    "-InstallRoot", root, "-WrapperPath", wrapper, "-Preview", "-CurrentPath", raw]).strip
    result.should eq(([wrapper, root, "%USERPROFILE%\\bin"] + entries).join(';'))
    result.size.should be > 8192
  end

  it "removes only the package root and preserves the shared wrapper entry" do
    root = "C:\\Author Software\\rvm"
    wrapper = "C:\\ProgramData\\rvm\\wrapper"
    script = File.expand_path("../src/tools/path/package_path.ps1", __DIR__)
    result = RvmCliTools.capture("powershell.exe", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script,
                                                    "-InstallRoot", root, "-Remove", "-Preview", "-CurrentPath", "#{wrapper};#{root};%USERPROFILE%\\bin"]).strip
    result.should eq("#{wrapper};%USERPROFILE%\\bin")
  end
end
