require "./spec_helper"

# Optional differential tests against the unmodified source checkout.
# Node is a development-only dependency for this opt-in compatibility check.
if reference = ENV["RVM_JS_REFERENCE"]?
  describe "JavaScript reference parity" do
    it "preserves original text/status colors while replacing primary Chalk green with Windows blue" do
      previous = %w(FORCE_COLOR NO_COLOR).to_h { |key| {key, ENV[key]?} }
      begin
        ENV["FORCE_COLOR"] = "1"
        ENV.delete("NO_COLOR")
        Fixtures.with_home do
          data = RvmCliTools.config
          data.as_h["proxy"] = JSON.parse(%({"hostname":"http://proxy.example:1234","enabled":false}))
          RvmCliTools.write_rvm_config(data)
          source = <<-'JS'
            const fs = require('fs');
            const path = require('path');
            const root = process.argv[1];
            const config = JSON.parse(fs.readFileSync(0, 'utf8'));
            require(path.join(root, 'node_modules/chalk')).level = 1;
            const Tools = require(path.join(root, 'src/cli/_tools'));
            Tools.config = () => config;
            Tools.getCurrentVersion = () => config.default;
            const List = require(path.join(root, 'src/cli/tasks/_list'));
            const Config = require(path.join(root, 'src/cli/tasks/_config'));
            const originalLog = console.log;
            function capture(fn) {
              const lines = [];
              console.log = value => lines.push(value === undefined ? '' : String(value));
              fn();
              console.log = originalLog;
              return lines.join('\n') + '\n';
            }
            originalLog(JSON.stringify({
              list: capture(() => List.runList()),
              data: capture(() => Config.printData()),
              proxy: capture(() => Config.runProxy())
            }));
            JS
          output = IO::Memory.new
          error = IO::Memory.new
          status = Process.run("node", ["-e", source, File.expand_path(reference)], input: IO::Memory.new(data.to_json), output: output, error: error)
          status.success?.should be_true, error.to_s
          result = JSON.parse(output.to_s)
          io = IO::Memory.new
          RvmCliList.run_list(io)
          io.to_s.should eq(result["list"].as_s.gsub("\e[32m", "\e[94m"))
          io.to_s.should contain("\e[94m")
          io.clear
          RvmCliConfig.print_data(io)
          io.to_s.should eq(result["data"].as_s.gsub("\e[32m", "\e[94m"))
          io.clear
          RvmCliConfig.run_proxy(io: io)
          io.to_s.should eq(result["proxy"].as_s)
          io.to_s.should contain("\e[31mdisabled\e[39m")
        end
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

    it "matches numeric version resolution, list output and wrapper selection" do
      Fixtures.with_home do |home|
        ruby = Fixtures.add_command("ruby-3.2.6", "ruby.exe")
        File.write(File.join(home, ".ruby-version"), "3.2.6\r\n")
        source = <<-'JS'
          const fs = require('fs');
          const path = require('path');
          const root = process.argv[1];
          const fixture = JSON.parse(fs.readFileSync(0, 'utf8'));
          const Tools = require(path.join(root, 'src/cli/_tools'));
          Tools.config = () => fixture.config;
          Tools.getCurrentVersion = () => fixture.config.default;
          const List = require(path.join(root, 'src/cli/tasks/_list'));
          const Wrapper = require(path.join(root, 'src/cli/_wrapper'));
          const lines = [];
          const originalLog = console.log;
          console.log = value => lines.push(value === undefined ? '' : String(value));
          List.runList();
          console.log = originalLog;
          originalLog(JSON.stringify({
            matches: fixture.queries.map(q => Tools.matchingVersion(q, fixture.versions) || null),
            list: lines.join('\n') + '\n',
            pathVersion: Wrapper.getRubyVersionForPath(fixture.home),
            commandPath: Wrapper.getRubyEnvCommandPath('ruby-3.2', 'ruby')
          }));
          JS
        versions = %w(ruby-3.2.9 ruby-3.2.10 ruby-3.10.1 ruby-2.4.10)
        queries = %w(ruby-3 ruby-3.2 ruby-3.2.9 ruby-3.2.8 ruby-2 ruby-9)
        fixture = {config: RvmCliTools.config, home: home, versions: versions, queries: queries}.to_json
        output = IO::Memory.new
        error = IO::Memory.new
        status = Process.run("node", ["-e", source, File.expand_path(reference)], input: IO::Memory.new(fixture), output: output, error: error)
        status.success?.should be_true, error.to_s
        result = JSON.parse(output.to_s)
        expected_matches = queries.map { |query| RvmCliTools.matching_version(query, versions) }
        result["matches"].to_json.should eq(expected_matches.to_json)
        io = IO::Memory.new
        RvmCliList.run_list(io)
        result["list"].as_s.should eq(io.to_s)
        result["pathVersion"].as_s.should eq(Wrapper.get_ruby_version_for_path(home))
        RvmCliTools.normalize_path(result["commandPath"].as_s).should eq(RvmCliTools.normalize_path(ruby))
      end
    end
  end
end
