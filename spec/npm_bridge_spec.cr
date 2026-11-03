require "./spec_helper"
require "yaml"
require "./support/migration_fixture"

module NpmFixtures
  def self.source(home : String) : String
    root = File.join(home, "bridge-source")
    Dir.mkdir_p(root)
    %w(package.json install.ps1 rvm.cmd README.md).each do |file|
      content = File.read(File.expand_path("../npm/#{file}", __DIR__))
      content = content.gsub("\r\n", "\n").gsub("\n", "\r\n") if file.ends_with?(".cmd")
      File.write(File.join(root, file), content)
    end
    Dir.mkdir_p(File.join(root, "src/tools"))
    FileUtils.cp_r(File.join(RvmCliTools.rvm_root_path, "src/tools/current"), File.join(root, "src/tools/current"))
    executable = Fixtures.build_executable("setup-fixture", File.join(__DIR__, "support/setup_fixture.cr"))
    FileUtils.cp(executable, File.join(root, "rvm-windows-setup.exe"))
    root
  end

  def self.npm(args : Array(String), home : String, env = {} of String => String?) : String
    output = IO::Memory.new
    error = IO::Memory.new
    command = "& npm.cmd #{args.map { |arg| "'#{arg.gsub("'", "''")}'" }.join(' ')}; exit $LASTEXITCODE"
    env = env.merge({"npm_config_cache" => File.join(home, "npm-cache"), "npm_config_userconfig" => File.join(home, ".npmrc")})
    File.write(File.join(home, ".npmrc"), "")
    status = Process.run("powershell.exe", ["-NoProfile", "-Command", command], env: env, output: output, error: error)
    raise "npm fixture command failed: #{output}\n#{error}" unless status.success?
    output.to_s
  end

  def self.native(home : String) : String
    root = File.join(home, "Matthäus Native Installation")
    Dir.mkdir_p(File.join(root, "bin"))
    Dir.mkdir_p(File.join(root, "src"))
    FileUtils.cp(Fixtures.executable, File.join(root, "bin/rvm.exe"))
    %w(tools templates).each do |dir|
      FileUtils.cp_r(File.join(RvmCliTools.rvm_root_path, "src", dir), File.join(root, "src", dir))
    end
    root
  end
end

describe "npm installation bridge" do
  it "has a versioned Windows-only manifest with no application dependencies" do
    manifest = JSON.parse(File.read(File.expand_path("../npm/package.json", __DIR__)))
    manifest["name"].as_s.should eq("rvm-windows")
    manifest["version"].as_s.should eq(RvmCliVersion.get_version)
    manifest["rvmWindowsBridge"].as_i.should eq(1)
    manifest["os"].as_a.map(&.as_s).should eq(["win32"])
    manifest["cpu"].as_a.map(&.as_s).should eq(["x64"])
    manifest["bin"]["rvm"].as_s.should eq("rvm.cmd")
    manifest["dependencies"]?.should be_nil
  end

  it "previews custom Unicode setup paths without installing or modifying launchers" do
    Fixtures.with_home do |home|
      root = File.join(home, "prefix/node_modules/rvm-windows")
      Dir.mkdir_p(root)
      script = File.join(root, "install.ps1")
      FileUtils.cp(File.expand_path("../npm/install.ps1", __DIR__), script)
      target = File.join(home, "Matthäus Native")
      result = JSON.parse(RvmCliTools.capture("powershell.exe", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script, "-Manual", "-Preview", "-InstallRoot", target]))
      result["installRoot"].as_s.should eq(target)
      result["arguments"].as_s.should eq("/S /NPMBRIDGE /D=#{target}")
      File.exists?(File.join(root, "install-root.txt")).should be_false
      File.exists?(target).should be_false
    end
  end

  if ENV["RVM_NPM_TESTS"]? == "1"
    it "updates a legacy global package and preserves sessions through real npm CMD and PowerShell shims" do
      Fixtures.with_home do |home|
        prefix = File.join(home, "Matthäus npm Prefix")
        legacy = File.join(home, "legacy-source")
        Dir.mkdir_p(File.join(legacy, "src/cli"))
        File.write(File.join(legacy, "package.json"), %({"name":"rvm-windows","version":"1.0.8","main":"src/cli/cli.js","bin":{"rvm":"src/cli/cli.js"}}))
        File.write(File.join(legacy, "src/cli/cli.js"), "#!/usr/bin/env node\nconsole.log('legacy fixture');\n")
        NpmFixtures.npm(["pack", legacy, "--ignore-scripts", "--pack-destination", home], home)
        NpmFixtures.npm(["install", "--global", "--prefix", prefix, "--ignore-scripts", "--no-audit", "--no-fund", File.join(home, "rvm-windows-1.0.8.tgz")], home)
        source = NpmFixtures.source(home)
        native = NpmFixtures.native(home)
        Fixtures.add_command("ruby-3.1.5", "ruby.exe")
        args_file = File.join(home, "setup-args.json")
        NpmFixtures.npm(["pack", source, "--ignore-scripts", "--pack-destination", home], home)
        npm_cli = File.join(File.dirname(Process.find_executable("npm.cmd").not_nil!), "node_modules/npm/bin/npm-cli.js")
        output = IO::Memory.new
        error = IO::Memory.new
        status = Process.run("node.exe", [File.join(__DIR__, "support/legacy_update_fixture.js"), prefix,
                                          File.join(home, "rvm-windows-#{RvmCliVersion.get_version}.tgz"), npm_cli],
          env: {"RVM_NPM_INSTALL_ROOT" => native, "RVM_TEST_SETUP_ARGS" => args_file,
                "npm_config_cache" => File.join(home, "npm-cache"), "npm_config_userconfig" => File.join(home, ".npmrc")},
          output: output, error: error)
        status.success?.should be_true, "#{output}\n#{error}"
        output.to_s.should contain("Legacy update finalisation completed")
        package = File.join(prefix, "node_modules/rvm-windows")
        File.exists?(File.join(package, "src/cli/cli.js")).should be_false
        File.read(File.join(package, "install-root.txt")).strip.should eq(native)
        JSON.parse(File.read(args_file)).as_a.map(&.as_s).join(' ').should eq("/S /NPMBRIDGE /D=#{native}")

        # An old `rvm get` finishes by reading the replacement manifest and
        # prepending these helper paths to npm shims. Keep those paths valid.
        %w(cmd_rvm_prepend.bat ps_rvm_prepend.ps1).each do |helper|
          File.file?(File.join(package, "src/tools/current", helper)).should be_true
        end
        script = File.join(home, "session.cmd")
        File.write(script, "@echo off\r\nchcp 65001 > NUL\r\ncall \"#{prefix}\\rvm.cmd\" use 3.1.5\r\ncall \"#{prefix}\\rvm.cmd\" current\r\necho SESSION=%RVM_SESSION%\r\n")
        [%w(cmd.exe /d /c) + [script], ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command",
                                        "& '#{prefix.gsub("'", "''")}\\rvm.ps1' use 3.1.5; & '#{prefix.gsub("'", "''")}\\rvm.ps1' current; Write-Output \"SESSION=$env:RVM_SESSION\"; exit $LASTEXITCODE"]].each do |command|
          output = IO::Memory.new
          error = IO::Memory.new
          status = Process.run(command.first, command.skip(1), env: {"RVM_SESSION" => nil, "RVM_ROOT" => nil}, output: output, error: error)
          status.success?.should be_true, "#{output}\n#{error}"
          error.to_s.should eq("")
          output.to_s.should contain("Using ruby-3.1.5")
          output.to_s.should contain("ruby-3.1.5")
          output.to_s.should match(/SESSION=\d+/)
          output.to_s.should_not contain("No rvm session found!")
        end
      end
    end

    it "removes only the old global package through npm, preserving shared state and unrelated packages" do
      Fixtures.with_home do |home|
        prefix = File.join(home, "prefix")
        source = MigrationFixtures.legacy(File.join(home, "legacy-source-prefix"))
        NpmFixtures.npm(["pack", source, "--ignore-scripts", "--pack-destination", home], home)
        NpmFixtures.npm(["install", "--global", "--prefix", prefix, "--ignore-scripts", "--no-audit", "--no-fund", File.join(home, "rvm-windows-1.0.8.tgz")], home)
        package = File.join(prefix, "node_modules/rvm-windows")
        %w(.cmd .ps1).each do |extension|
          shim = File.join(prefix, "rvm#{extension}")
          text = File.read(shim)
          line = extension == ".cmd" ? %Q(call "#{package}\\src\\tools\\current\\cmd_rvm_prepend.bat") : %Q(& "#{package}\\src\\tools\\current\\ps_rvm_prepend.ps1")
          File.write(shim, text.sub("\n", "\n#{line}\r\n"))
        end
        other = File.join(prefix, "node_modules/other-tool")
        Dir.mkdir_p(other)
        File.write(File.join(other, "package.json"), %({"name":"other-tool","version":"1.0.0"}))
        ruby = Fixtures.add_command("ruby-3.2.6", "ruby.exe", "keep ruby")
        config = File.read(RvmCliTools.rvm_config_path)
        migration = MigrationFixtures.migration(home)
        migration.prepare([prefix])
        job = migration.commit(false)
        migration.cleanup_with(job, IO::Memory.new) do |candidate|
          NpmFixtures.npm(["uninstall", "--global", "--prefix", candidate, "--ignore-scripts", "--no-audit", "--no-fund", "rvm-windows"], home)
          !File.directory?(package)
        end.should be_true
        File.directory?(package).should be_false
        %w(rvm rvm.cmd rvm.ps1).each { |name| File.exists?(File.join(prefix, name)).should be_false }
        File.file?(File.join(other, "package.json")).should be_true
        File.read(RvmCliTools.rvm_config_path).should eq(config)
        File.read(ruby).should eq("keep ruby")
      end
    end

    it "provides a manual recovery path when scripts are blocked, and propagates setup failures" do
      Fixtures.with_home do |home|
        prefix = File.join(home, "prefix")
        source = NpmFixtures.source(home)
        native = NpmFixtures.native(home)
        NpmFixtures.npm(["pack", source, "--ignore-scripts", "--pack-destination", home], home)
        NpmFixtures.npm(["install", "--global", "--prefix", prefix, "--ignore-scripts", "--no-audit", "--no-fund", File.join(home, "rvm-windows-#{RvmCliVersion.get_version}.tgz")], home)
        package = File.join(prefix, "node_modules/rvm-windows")
        output = IO::Memory.new
        error = IO::Memory.new
        status = Process.run("powershell.exe", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "& '#{prefix.gsub("'", "''")}\\rvm.ps1' version; exit $LASTEXITCODE"], output: output, error: error)
        status.success?.should be_false
        error.to_s.should contain("setup has not run")
        args = ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", File.join(package, "install.ps1"), "-Manual", "-InstallRoot", native]
        status = Process.run("powershell.exe", args, env: {"RVM_TEST_SETUP_EXIT" => "42"}, output: output, error: error)
        status.success?.should be_false
        File.exists?(File.join(package, "install-root.txt")).should be_false
        RvmCliTools.capture("powershell.exe", args)
        before = File.read(File.join(prefix, "rvm.ps1"))
        RvmCliTools.capture("powershell.exe", args)
        File.read(File.join(prefix, "rvm.ps1")).should eq(before)
        # A GitHub self-update may already be newer than npm's latest package.
        # Never downgrade that installation when npm updates its small bridge.
        newer = Fixtures.build_executable("newer-version-fixture", File.join(__DIR__, "support/newer_version_fixture.cr"))
        FileUtils.cp(newer, File.join(native, "bin/rvm.exe"))
        output.clear
        error.clear
        status = Process.run("powershell.exe", args, env: {"RVM_TEST_SETUP_EXIT" => "42"}, output: output, error: error)
        status.success?.should be_true, "#{output}\n#{error}"
        output.to_s.should contain("Keeping the newer native")
        NpmFixtures.npm(["uninstall", "--global", "--prefix", prefix, "--ignore-scripts", "--no-audit", "--no-fund", "rvm-windows"], home)
        File.exists?(File.join(prefix, "rvm.cmd")).should be_false
        File.exists?(File.join(prefix, "rvm.ps1")).should be_false
        File.file?(File.join(native, "bin/rvm.exe")).should be_true
      end
    end
  end
end
