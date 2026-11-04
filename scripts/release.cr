require "yaml"
require "json"
require "semantic_version"

# Deliberately local-only. Pushing a tag and publishing a release are explicit
# maintainer actions; the workflow creates only a draft release.
root = File.expand_path("..", __DIR__)
Dir.cd(root) do
  abort "Usage: crystal run scripts/release.cr -- <new-version>" unless version = ARGV.first?
  parsed_version = begin
    SemanticVersion.parse(version)
  rescue ArgumentError
    abort "Invalid version"
  end
  manifest = File.read("shard.yml")
  old_version = YAML.parse(manifest)["version"].as_s
  npm_manifest = JSON.parse(File.read("npm/package.json"))
  abort "npm/package.json and shard.yml versions differ" unless npm_manifest["version"].as_s == old_version
  abort "Version must increase" unless parsed_version > SemanticVersion.parse(old_version)
  date = Time.utc.to_s("%F")
  abort "CHANGELOG.md needs '# #{version} - #{date}'" unless File.read("CHANGELOG.md").matches?(/^#\s+#{Regex.escape(version)}\s*-\s*#{date}/m)
  output = IO::Memory.new
  Process.run("git", ["status", "--porcelain"], output: output)
  abort "Commit outstanding changes before preparing a release" unless output.to_s.empty?
  status = Process.run("crystal", ["spec"], output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
  exit status.exit_code unless status.success?
  File.write("shard.yml", manifest.sub("version: #{old_version}", "version: #{version}"))
  npm_manifest.as_h["version"] = JSON::Any.new(version)
  File.write("npm/package.json", npm_manifest.to_pretty_json + "\n")
  [["add", "shard.yml", "npm/package.json"], ["commit", "-m", "Release #{version}"], ["tag", "v#{version}"]].each do |args|
    status = Process.run("git", args, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
    exit status.exit_code unless status.success?
  end
  puts "Prepared v#{version} locally. Review, then push the commit and tag explicitly."
end
