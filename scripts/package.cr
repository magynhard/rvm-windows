require "file_utils"
require "yaml"

root = File.expand_path("..", __DIR__)
Dir.cd(root) do
  status = Process.run("crystal", ["run", "scripts/build.cr"], output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
  exit status.exit_code unless status.success?
  version = YAML.parse(File.read("shard.yml"))["version"].as_s
  name = "rvm-windows-#{version}-windows-x64"
  stage = File.join(root, "dist", name)
  # A version-specific generated directory; never touch installed application data.
  FileUtils.rm_rf(stage)
  Dir.mkdir_p(File.join(stage, "bin"))
  Dir.mkdir_p(File.join(stage, "src"))
  FileUtils.cp("bin/rvm.exe", File.join(stage, "bin/rvm.exe"))
  %w(rvm.cmd rvm.ps1 LICENSE README.md CHANGELOG.md).each { |file| FileUtils.cp(file, File.join(stage, file)) }
  %w(tools templates).each { |dir| FileUtils.cp_r("src/#{dir}", File.join(stage, "src", dir)) }
  FileUtils.cp_r("doc", File.join(stage, "doc"))
  archive = File.join(root, "dist", "#{name}.zip")
  # Use the inbox ZIP implementation; no external archiver is required.
  source = File.join(stage, "*").gsub("'", "''")
  target = archive.gsub("'", "''")
  command = "Compress-Archive -Path '#{source}' -DestinationPath '#{target}' -Force"
  status = Process.run("powershell.exe", ["-NoProfile", "-Command", command], output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
  exit status.exit_code unless status.success?
  if makensis = ENV["MAKENSIS"]?
    status = Process.run(makensis, ["/DVERSION=#{version}", "/DPACKAGE_DIR=#{stage}", "installer/rvm-windows.nsi"],
      output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
    exit status.exit_code unless status.success?
  else
    puts "NSIS not compiled: set MAKENSIS to makensis.exe to include setup."
  end
  puts "Packaged #{archive}"
end
