require "json"
require "file_utils"

module NpmPackageBuilder
  def self.run(root : String, version : String)
    manifest = JSON.parse(File.read(File.join(root, "npm/package.json")))
    raise "npm/package.json and shard.yml versions differ" unless manifest["version"].as_s == version
    stage = File.join(root, "dist/npm-build/node_modules/rvm-windows")
    FileUtils.rm_rf(stage)
    Dir.mkdir_p(File.join(stage, "src/tools/current"))
    %w(package.json README.md install.ps1 rvm.cmd).each do |file|
      content = File.read(File.join(root, "npm", file))
      content = content.gsub("\r\n", "\n").gsub("\n", "\r\n") if file.ends_with?(".cmd")
      File.write(File.join(stage, file), content)
    end
    FileUtils.cp(File.join(root, "LICENSE"), File.join(stage, "LICENSE"))
    %w(cmd_rvm_prepend.bat ps_rvm_prepend.ps1).each do |file|
      FileUtils.cp(File.join(root, "src/tools/current", file), File.join(stage, "src/tools/current", file))
    end
    setup = File.join(root, "dist/rvm-windows-#{version}-windows-x64-setup.exe")
    FileUtils.cp(setup, File.join(stage, "rvm-windows-setup.exe"))
    destination = File.join(root, "dist").gsub("'", "''")
    command = "& npm.cmd pack --ignore-scripts --json --pack-destination '#{destination}'; exit $LASTEXITCODE"
    status = Process.run("powershell.exe", ["-NoProfile", "-Command", command], chdir: stage,
      output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
    raise "npm pack failed (#{status.exit_code})" unless status.success?
    puts "Packed npm bridge: dist/rvm-windows-#{version}.tgz (not published)"
  end
end
