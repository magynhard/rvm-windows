require "./spec_helper"

describe "Windows shell execution" do
  it "executes the CMD built-in ver instead of looking for ver.exe" do
    RvmCliTools.shell("ver").should match(/Windows.*\d+\.\d+\.\d+/)
  end

  it "preserves quoted batch paths and arguments containing spaces and ampersands" do
    Fixtures.with_home do |home|
      batch = File.join(home, "Author Software", "probe script.cmd")
      RvmCliTools.write_file(batch, "@echo off\r\necho ARG=%1\r\n")
      RvmCliTools.shell(%Q("#{batch}" "quoted & spaced argument")).strip.should eq(%Q(ARG="quoted & spaced argument"))
    end
  end

  it "interprets command chaining and redirection within the child CMD" do
    Fixtures.with_home do |home|
      file = File.join(home, "output with spaces.txt")
      output = RvmCliTools.shell(%Q(echo payload>"#{file}" && type "#{file}"))
      output.strip.should eq("payload")
      File.read(file).strip.should eq("payload")
    end
  end

  it "propagates nonzero shell statuses for captured and inherited output" do
    expect_raises(Exception, /Command failed \(42\)/) { RvmCliTools.shell("exit /b 42") }
    expect_raises(Exception, /Command failed \(42\)/) { RvmCliTools.run_shell("exit /b 42") }
    RvmCliTools.run_shell("ver > NUL")
  end
end
