require "../spec_helper"

module MigrationFixtures
  def self.legacy(prefix : String, version = "1.0.8") : String
    package = File.join(prefix, "node_modules/rvm-windows")
    Dir.mkdir_p(File.join(package, "src/cli"))
    File.write(File.join(package, "src/cli/cli.js"), "// legacy CLI fixture\n")
    File.write(File.join(package, "package.json"), {
      "name" => "rvm-windows", "version" => version,
      "main" => "src/cli/cli.js", "bin" => {"rvm" => "src/cli/cli.js"},
    }.to_json)
    package
  end

  def self.migration(home : String)
    root = File.join(home, "Native Installation")
    Dir.mkdir_p(root)
    LegacyInstallationMigration.new(root)
  end
end
