require "./spec_helper"

module ColorFixtures
  class Terminal < IO::Memory
    def tty? : Bool
      true
    end
  end

  def self.with_environment(&)
    previous = %w(NO_COLOR FORCE_COLOR TERM).to_h { |key| {key, ENV[key]?} }
    begin
      previous.each_key { |key| ENV.delete(key) }
      yield
    ensure
      previous.each do |key, value|
        if value
          ENV[key] = value
        else
          ENV.delete(key)
        end
      end
    end
  end

  def self.plain(text : String) : String
    text.gsub(/\e\[[0-9;]*m/, "")
  end
end

describe RvmCliColor do
  it "uses Windows blue for primary highlights and green/red/yellow for status" do
    ColorFixtures.with_environment do
      io = ColorFixtures::Terminal.new
      RvmCliColor.primary("version", io).should eq("\e[94mversion\e[39m")
      RvmCliColor.green("version", io).should eq("\e[32mversion\e[39m")
      RvmCliColor.red("error", io).should eq("\e[31merror\e[39m")
      RvmCliColor.yellow("warning", io).should eq("\e[33mwarning\e[39m")
    end
  end

  it "detects the destination stream instead of global stdout/stderr" do
    ColorFixtures.with_environment do
      RvmCliColor.primary("version", IO::Memory.new).should eq("version")
      RvmCliColor.primary("version", ColorFixtures::Terminal.new).should contain("\e[94m")
    end
  end

  it "supports NO_COLOR, FORCE_COLOR and dumb terminals without global state" do
    ColorFixtures.with_environment do
      io = ColorFixtures::Terminal.new
      ENV["TERM"] = "dumb"
      RvmCliColor.enabled?(io).should be_false
      ENV["FORCE_COLOR"] = "1"
      RvmCliColor.enabled?(IO::Memory.new).should be_true
      ENV["NO_COLOR"] = "1"
      RvmCliColor.enabled?(io).should be_false
      ENV["NO_COLOR"] = ""
      RvmCliColor.enabled?(io).should be_true
      ENV["FORCE_COLOR"] = "0"
      RvmCliColor.enabled?(io).should be_false
      ENV.delete("FORCE_COLOR")
      ENV.delete("TERM")
      RvmCliColor.enabled?(io).should be_true
    end
  end

  it "leaves ASCII art plain and colors the Ruby title red, 4/version white and Windows blue" do
    ColorFixtures.with_environment do
      logo = RvmCliTools.logo(ColorFixtures::Terminal.new)
      logo.split("\n\n", 2).first.should_not contain("\e[")
      logo.should match(/\e\[[0-9;]*91[0-9;]*m/)
      logo.should contain("\e[91;1mRuby Version Manager\e[39;22m")
      logo.should contain("\e[37;1m 4 \e[39;22m")
      logo.should contain("\e[94;1mWindows\e[39;22m")
      logo.should contain("\n                \e[37m#{RvmCliVersion.get_version}\e[39m\n")
      ColorFixtures.plain(logo).lines.last.should eq("                #{RvmCliVersion.get_version}")
      ColorFixtures.plain(logo).should eq(RvmCliTools.logo(IO::Memory.new))
    end
  end

  it "keeps list markers and legends plain while highlighting version names blue" do
    ColorFixtures.with_environment do
      Fixtures.with_home do
        io = ColorFixtures::Terminal.new
        RvmCliList.run_list(io)
        io.to_s.should contain("=* \e[94mruby-3.2.6\e[39m")
        io.to_s.should contain("# => - current\n# =* - current && default")
        plain = IO::Memory.new
        RvmCliList.run_list(plain)
        ColorFixtures.plain(io.to_s).should eq(plain.to_s)
      end
    end
  end

  it "highlights only installed archive releases without changing returned version strings" do
    ColorFixtures.with_environment do
      Fixtures.with_home do
        io = ColorFixtures::Terminal.new
        releases = [RvmCliList::Release.new("unused", "3.2.6"), RvmCliList::Release.new("unused", "3.2.9")]
        versions = RvmCliList.run_list_all(false, io, releases)
        versions.should eq(%w(ruby-3.2.9 ruby-3.2.6))
        io.to_s.should contain(" - ruby-3.2.9\n - \e[32mruby-3.2.6\e[39m")
      end
    end
  end

  it "distinguishes up-to-date and upgradeable environments" do
    ColorFixtures.with_environment do
      io = ColorFixtures::Terminal.new
      RvmCliList.print_upgrade("ruby-3.2.6", "ruby-3.2.9", io)
      io.to_s.should eq("\e[33mruby-3.2.6\e[39m >> \e[94mruby-3.2.9\e[39m\n")
      io.clear
      RvmCliList.print_upgrade("ruby-3.2.9", "ruby-3.2.9", io)
      io.to_s.should eq("\e[32mruby-3.2.9\e[39m >> (up to date)\n")
    end
  end

  it "colors help commands and shortcuts without shifting columns" do
    ColorFixtures.with_environment do
      io = ColorFixtures::Terminal.new
      RvmCliHelp.run_help(io)
      io.to_s.should contain("\e[94madd <path>")
      io.to_s.should contain("\e[94mrvm version\e[39m")
      plain = IO::Memory.new
      RvmCliHelp.run_help(plain)
      ColorFixtures.plain(io.to_s).should eq(plain.to_s)
    end
  end

  it "colors config paths and proxy status but never JSON configuration values" do
    ColorFixtures.with_environment do
      Fixtures.with_home do
        io = ColorFixtures::Terminal.new
        RvmCliConfig.run_proxy("proxy.example:1234", io)
        io.to_s.should contain("\e[94mhttp://proxy.example:1234\e[39m")
        io.to_s.should contain("[\e[32menabled\e[39m]")
        RvmCliConfig.run_proxy("disable", io)
        io.to_s.should contain("[\e[31mdisabled\e[39m]")
        RvmCliConfig.print_config(io)
        io.to_s.should contain("\e[94m#{RvmCliTools.rvm_config_path}\e[39m")
        RvmCliTools.read_rvm_config.should_not contain("\e[")
        RvmCliTools.config["proxy"]["hostname"].as_s.should eq("http://proxy.example:1234")
      end
    end
  end

  it "colors selected versions and paths but keeps config/session writes uncolored" do
    ColorFixtures.with_environment do
      Fixtures.with_home do
        io = ColorFixtures::Terminal.new
        Fixtures.add_command("ruby-3.1.5", "ruby.exe")
        RvmCliUse.run_use("3.1", true, io)
        io.to_s.should contain("Using \e[94mruby-3.1.5\e[39m from \e[94m")
        io.to_s.should contain("Set default \e[94mruby-3.1.5\e[39m")
        RvmCliTools.get_current_version.should eq("ruby-3.1.5")
        RvmCliTools.get_default_version.should eq("ruby-3.1.5")
        io.clear
        RvmCliUse.run_use("99", io: io)
        io.to_s.should contain("\e[31mruby-99\e[39m")
        io.to_s.should contain("\e[94mrvm list\e[39m")
      end
    end
  end

  it "colors missing arguments on stderr and unknown tasks on their output stream" do
    ColorFixtures.with_environment do
      output = ColorFixtures::Terminal.new
      error = ColorFixtures::Terminal.new
      RvmCli.run(["use"], false, output, error).should eq(1)
      error.to_s.should contain("\e[31mNo version given.\e[39m")
      error.to_s.should contain("\e[94mrvm use <version>\e[39m")
      RvmCli.run(["unknown"], false, output, error).should eq(0)
      output.to_s.should contain("\e[31munknown\e[39m")
      output.to_s.should contain("\e[94mhelp\e[39m")
    end
  end

  it "renders MSYS warnings yellow and installation removal details blue/red" do
    ColorFixtures.with_environment do
      Fixtures.with_home do |home|
        io = ColorFixtures::Terminal.new
        ENV["MSYS2_PATH"] = File.join(home, "missing")
        RvmCliList.has_valid_msys2_path(io: io).should be_false
        io.to_s.should contain("\e[33mMSYS2_PATH")
        path = RvmCliTools.envs["ruby-3.1.5"].as_s
        Dir.mkdir_p(path)
        RvmCliUninstall.run_uninstall("3.1.5", false, io)
        io.to_s.should contain("Uninstalling \e[94mruby-3.1.5\e[39m from \e[31m")
        io.to_s.should contain("The environment \e[31mruby-3.1.5\e[39m")
      end
    end
  end

  it "honors forced/disabled colors in real executable output redirected to a pipe" do
    ColorFixtures.with_environment do
      Fixtures.with_home do
        executable = Fixtures.executable
        [{"1", nil, true}, {"0", nil, false}, {"1", "1", false}].each do |force, no_color, colored|
          output = IO::Memory.new
          error = IO::Memory.new
          status = Process.run(executable, ["list"], env: {"FORCE_COLOR" => force, "NO_COLOR" => no_color}, output: output, error: error)
          status.success?.should be_true, error.to_s
          output.to_s.includes?("\e[").should eq(colored)
          output.to_s.should contain("\e[94mruby-3.2.6\e[39m") if colored
        end
      end
    end
  end

  it "never colors internal wrapper/setup protocols or their errors, even when forced" do
    ColorFixtures.with_environment do
      Fixtures.with_home do |home|
        ENV["FORCE_COLOR"] = "1"
        Fixtures.add_command("ruby-3.2.6", "ruby.exe")
        %w(path rubypath proxy runner after invalid).each do |mode|
          output = ColorFixtures::Terminal.new
          error = ColorFixtures::Terminal.new
          RvmCli.run(["--internal-wrapper", mode, home, "ruby"], false, output, error)
          output.to_s.should_not contain("\e[")
          error.to_s.should_not contain("\e[")
        end
        output = ColorFixtures::Terminal.new
        RvmCli.run(["--internal-install"], false, output).should eq(0)
        output.to_s.should eq("#{RvmCliTools.get_rvm_data_dir}\n")
      end
    end
  end
end
