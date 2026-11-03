require "./spec_helper"

describe RvmCli do
  it "preserves complete missing-version explanations for commands and aliases" do
    aliases = {
      "install"   => %w(install i),
      "upgrade"   => %w(upgrade up),
      "kick"      => %w(kick k),
      "reinstall" => %w(reinstall ri),
      "uninstall" => %w(uninstall ui remove rem delete del),
      "use"       => %w(use u),
    }
    aliases.each do |command, names|
      expected = if command == "upgrade"
                   "No version given. Run rvm upgrade <version> or rvm upgrade <from_version> <to_version> to upgrade an existing environment, for example: rvm upgrade ruby-3.0\n"
                 else
                   "No version given. Run rvm #{command} <version>, for example: rvm #{command} ruby-3.2.2\n"
                 end
      names.each do |name|
        [[name], [name, ""]].each do |args|
          output = IO::Memory.new
          error = IO::Memory.new
          RvmCli.run(args, false, output, error).should eq(1)
          output.to_s.should eq("")
          error.to_s.should eq(expected)
        end
      end
    end
  end

  it "prints both upgrade forms and the original example in the compiled executable" do
    Fixtures.with_home do
      %w(upgrade up).each do |command|
        output = IO::Memory.new
        error = IO::Memory.new
        status = Process.run(Fixtures.executable, [command], env: {"NO_COLOR" => "1"}, output: output, error: error)
        status.exit_code.should eq(1)
        error.to_s.should eq("No version given. Run rvm upgrade <version> or rvm upgrade <from_version> <to_version> to upgrade an existing environment, for example: rvm upgrade ruby-3.0\n")
      end
    end
  end

  it "dispatches non-mutating commands and their aliases" do
    Fixtures.with_home do
      [%w(version v --version -v), %w(current c), %w(list l ls)].each do |aliases|
        expected = IO::Memory.new
        RvmCli.run([aliases.first], false, expected).should eq(0)
        aliases.each do |command|
          actual = IO::Memory.new
          RvmCli.run([command], false, actual).should eq(0)
          actual.to_s.should eq(expected.to_s)
        end
      end
      io = IO::Memory.new
      RvmCli.run(%w(cfg d), false, io).should eq(0)
      io.to_s.should eq("ruby-3.2.6\n")
    end
  end

  it "supports both --default argument orders while preserving unknown config keys" do
    Fixtures.with_home do
      Fixtures.add_command("ruby-3.1.5", "ruby.exe")
      io = IO::Memory.new
      RvmCli.run(%w(use --default 3.1), false, io).should eq(0)
      RvmCliTools.get_default_version.should eq("ruby-3.1.5")
      RvmCli.run(%w(u 3.2 --default), false, io).should eq(0)
      RvmCliTools.get_current_version.should eq("ruby-3.2.6")
      RvmCliTools.get_default_version.should eq("ruby-3.2.6")
      # Preserve the original prefixed-version/flag-order quirk.
      RvmCli.run(%w(use --default ruby-3.1), false, io).should eq(0)
      RvmCliTools.get_current_version.should eq("ruby-3.1.5")
      RvmCliTools.get_default_version.should eq("ruby-3.2.6")
    end
  end

  it "reports missing required arguments with failure and unknown tasks compatibly" do
    Fixtures.with_home do
      error = IO::Memory.new
      RvmCli.run(["use"], false, IO::Memory.new, error).should eq(1)
      error.to_s.should contain("No version given")
      io = IO::Memory.new
      RvmCli.run(["not-a-task"], false, io).should eq(0)
      io.to_s.should contain("Invalid task")
      io.to_s.should contain("The given task not-a-task is invalid.")
      # Preserve dispatch precedence: k is kick, not kit.
      error.clear
      RvmCli.run(["k"], false, IO::Memory.new, error).should eq(1)
      error.to_s.should contain("rvm kick")
    end
  end

  it "renders every original help command" do
    io = IO::Memory.new
    RvmCli.run(["help"], false, io).should eq(0)
    RvmCliHelp::TASKS.each { |name, _, _| io.to_s.should contain(name) }
    io.to_s.should contain("Install a bunch of widely used x64 dependencies automatically to the current ruby environment, which are needed to build native gems like postgresql, mysql2, ...")
  end

  it "removes only the explicitly selected temporary installation" do
    Fixtures.with_home do |home|
      target = RvmCliTools.envs["ruby-3.1.5"].as_s
      Dir.mkdir_p(target)
      File.write(File.join(target, "marker"), "fixture")
      RvmCliUninstall.run_uninstall("3.1.5", false, IO::Memory.new)
      File.exists?(target).should be_false
      RvmCliTools.envs.has_key?("ruby-3.1.5").should be_false
      File.file?(File.join(home, ".rvm.json")).should be_true
    end
  end

  it "retains installer flags, registry minor-version search and kit gem pins" do
    RvmCliInstall.installer_args("C:/Ruby With Spaces").should eq([
      "/verysilent", "/currentuser", "/dir=C:/Ruby With Spaces", "/tasks=noassocfiles,nomodpath",
    ])
    RvmCliInstall.registry_search_args("ruby-3.3.9")[3].should eq("RubyInstaller-3.3")
    commands = RvmCliKit.after_commands("x64-mingw32", "C:/ruby", "2.4.10")
    commands.join('\n').should contain("gem install pg -v 1.2.3 ")
    commands.join('\n').should contain("gem install nokogiri -v 1.10.10 ")
    commands.join('\n').should contain("msys64/mingw64")
  end
end
