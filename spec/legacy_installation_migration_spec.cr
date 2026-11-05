require "./support/migration_fixture"

describe LegacyInstallationMigration do
  it "fails before modifying wrappers if the user's config is invalid" do
    Fixtures.with_home do |home|
      migration = MigrationFixtures.migration(home)
      wrapper = File.join(RvmCliTools.get_rvm_data_dir, "wrapper/ruby.bat")
      RvmCliTools.write_file(wrapper, "keep legacy wrapper")
      File.write(RvmCliTools.rvm_config_path, "invalid config, do not replace")
      expect_raises(JSON::ParseException) { migration.prepare([] of String) }
      File.read(RvmCliTools.rvm_config_path).should eq("invalid config, do not replace")
      File.read(wrapper).should eq("keep legacy wrapper")
      File.exists?(File.join(migration.root, ".legacy-migration.json")).should be_false
    end
  end

  it "recognises active managed Ruby tools before shared wrappers are replaced" do
    roots = ["C:/Matthäus Rubies/ruby-3.2.6"]
    LegacyInstallationMigration.active_ruby?([%q("C:\Matthäus Rubies\ruby-3.2.6\bin\ruby.exe" irb)], roots).should be_true
    LegacyInstallationMigration.active_ruby?([%q("C:\Matthäus Rubies\ruby-3.2.6\bin\rubyw.exe" app.rb)], roots).should be_true
    LegacyInstallationMigration.active_ruby?([%q("C:\OtherRuby\bin\ruby.exe" app.rb)], roots).should be_false
  end

  it "defers cleanup during npm or matching legacy processes, but not unrelated tools" do
    prefixes = ["C:/Matthäus npm Prefix"]
    LegacyInstallationMigration.busy_commands?([%q(node "C:\Program Files\nodejs\node_modules\npm\bin\npm-cli.js" install)], prefixes).should be_true
    LegacyInstallationMigration.busy_commands?([%q(node "C:\Matthäus npm Prefix\node_modules\rvm-windows\src\cli\cli.js" get)], prefixes).should be_true
    LegacyInstallationMigration.busy_commands?([%q(node "C:\other\server.js")], prefixes).should be_false
    LegacyInstallationMigration.busy_commands?([] of String, prefixes).should be_false
  end

  it "targets exactly one global package and prefix with lifecycle scripts disabled" do
    prefix = "C:/Matthäus & npm Prefix"
    LegacyInstallationMigration.uninstall_arguments(prefix).should eq(["uninstall", "--global", "--prefix", prefix, "--ignore-scripts", "--no-audit", "--no-fund", "rvm-windows"])
  end

  it "discovers only known old global packages, deduplicating prefixes" do
    Fixtures.with_home do |home|
      prefix = File.join(home, "Custom npm Prefix")
      MigrationFixtures.legacy(prefix)
      migration = MigrationFixtures.migration(home)
      migration.discover([prefix, prefix.upcase, File.join(home, "missing")]).should eq([prefix])
    end
  end

  it "does not remove current bridges, future versions, unrelated or malformed packages" do
    Fixtures.with_home do |home|
      prefix = File.join(home, "prefix")
      package = MigrationFixtures.legacy(prefix)
      manifest = File.join(package, "package.json")
      original = JSON.parse(File.read(manifest))
      migration = MigrationFixtures.migration(home)
      [{"rvmWindowsBridge", JSON::Any.new(1_i64)}, {"version", JSON::Any.new("1.1.1")},
       {"name", JSON::Any.new("unrelated")}, {"main", JSON::Any.new("other.js")}].each do |key, value|
        data = JSON.parse(original.to_json)
        data.as_h[key] = value
        File.write(manifest, data.to_json)
        migration.legacy?(prefix).should be_false
      end
      File.write(manifest, "not JSON")
      migration.legacy?(prefix).should be_false
    end
  end

  it "refuses to remove any package containing configured Ruby or data directories" do
    Fixtures.with_home do |home|
      prefix = File.join(home, "prefix")
      package = MigrationFixtures.legacy(prefix)
      migration = MigrationFixtures.migration(home)
      original = RvmCliTools.config.to_json
      ["ruby", "data"].each do |kind|
        config = JSON.parse(original)
        if kind == "ruby"
          config["envs"].as_h["ruby-3.2.6"] = JSON::Any.new(File.join(package, "my ruby"))
        else
          config.as_h["rvm_data_dir"] = JSON::Any.new(File.join(package, "my data"))
        end
        RvmCliTools.write_rvm_config(config)
        migration.legacy?(prefix).should be_false
      end
      RvmCliTools.write_rvm_config(original)
      LegacyInstallationMigration.new(File.join(package, "native")).legacy?(prefix).should be_false
    end
  end

  it "refuses linked development checkouts" do
    Fixtures.with_home do |home|
      prefix = File.join(home, "prefix")
      original = MigrationFixtures.legacy(prefix)
      checkout = File.join(home, "checkout")
      FileUtils.mv(original, checkout)
      output = IO::Memory.new
      status = Process.run(RvmCliTools.shell_command(%Q(mklink /J "#{original}" "#{checkout}")), shell: true, output: output, error: output)
      status.success?.should be_true, output.to_s
      begin
        MigrationFixtures.migration(home).legacy?(prefix).should be_false
      ensure
        # Remove the junction itself, not its target.
        RvmCliTools.shell(%Q(rmdir "#{original}"))
      end
      File.file?(File.join(checkout, "package.json")).should be_true
    end
  end

  it "backs up exact config and wrappers without changing configuration, sessions or Ruby files" do
    Fixtures.with_home do |home|
      prefix = File.join(home, "prefix")
      MigrationFixtures.legacy(prefix)
      ruby = Fixtures.add_command("ruby-3.2.6", "ruby.exe", "ruby installation sentinel")
      session = File.join(RvmCliTools.rvm_sessions_dir, "keep")
      File.write(session, "ruby-3.2.6")
      config = RvmCliTools.config
      config.as_h["custom-extension"] = JSON.parse(%({"keep":true}))
      RvmCliTools.write_rvm_config(config)
      config_before = File.read(RvmCliTools.rvm_config_path)
      wrapper = File.join(RvmCliTools.get_rvm_data_dir, "wrapper/ruby.bat")
      RvmCliTools.write_file(wrapper, "@echo off\r\nlegacy wrapper\r\n")
      migration = MigrationFixtures.migration(home)
      migration.prepare([prefix])
      state = JSON.parse(File.read(File.join(migration.root, ".legacy-migration.json")))
      File.read(File.join(state["job"].as_s, "config.json")).should eq(config_before)
      File.read(File.join(state["job"].as_s, "wrappers/ruby.bat")).should eq(File.read(wrapper))
      File.read(RvmCliTools.rvm_config_path).should eq(config_before)
      File.read(session).should eq("ruby-3.2.6")
      File.read(ruby).should eq("ruby installation sentinel")
      migration.rollback
    end
  end

  it "rolls back owned wrappers without overwriting unrelated new files" do
    Fixtures.with_home do |home|
      Fixtures.add_command("ruby-3.2.6", "ruby.exe")
      wrapper = File.join(RvmCliTools.get_rvm_data_dir, "wrapper/ruby.bat")
      RvmCliTools.write_file(wrapper, "legacy wrapper")
      migration = MigrationFixtures.migration(home)
      migration.prepare([] of String)
      RvmCliFix.fix_wrapper_files
      # The staged preflight executable differs from the target executable.
      File.write(wrapper, RvmCliFix.render_wrapper(File.join(migration.root, "bin", "rvm.exe")))
      extra = File.join(RvmCliTools.get_rvm_data_dir, "wrapper/other.bat")
      File.write(extra, "third-party wrapper")
      migration.rollback
      File.read(wrapper).should eq("legacy wrapper")
      File.read(extra).should eq("third-party wrapper")
      File.exists?(File.join(migration.root, ".legacy-migration.json")).should be_false
    end
  end

  it "does not clean anything before commit, and rechecks ownership after commit" do
    Fixtures.with_home do |home|
      prefix = File.join(home, "prefix")
      package = MigrationFixtures.legacy(prefix)
      migration = MigrationFixtures.migration(home)
      migration.prepare([prefix])
      state = JSON.parse(File.read(File.join(migration.root, ".legacy-migration.json")))
      job = File.join(state["job"].as_s, "state.json")
      expect_raises(Exception, "Migration was not committed") { migration.cleanup_with(job) { |_| true } }
      migration.commit(false).should eq(job)
      manifest = JSON.parse(File.read(File.join(package, "package.json")))
      manifest.as_h["rvmWindowsBridge"] = JSON::Any.new(1_i64)
      File.write(File.join(package, "package.json"), manifest.to_json)
      called = false
      migration.cleanup_with(job) { |_| called = true; false }.should be_true
      called.should be_false
      File.directory?(package).should be_true
    end
  end

  it "skips changed manifests and reports failed cleanup without deleting shared data" do
    Fixtures.with_home do |home|
      prefix = File.join(home, "prefix")
      package = MigrationFixtures.legacy(prefix)
      migration = MigrationFixtures.migration(home)
      migration.prepare([prefix])
      job = migration.commit(false)
      io = IO::Memory.new
      seen = [] of String
      migration.cleanup_with(job, io) { |value| seen << value; false }.should be_false
      seen.should eq([prefix])
      File.directory?(package).should be_true
      io.to_s.should contain("remove the old package manually")
      File.write(File.join(package, "package.json"), File.read(File.join(package, "package.json")) + "\n")
      seen.clear
      migration.cleanup_with(job, io) { |value| seen << value; true }.should be_true
      seen.should be_empty
      File.file?(RvmCliTools.rvm_config_path).should be_true
    end
  end
end
