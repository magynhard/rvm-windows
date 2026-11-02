require "../_tools"

class RvmCliList
  record Release, url : String, version : String
  ARCHIVES_URL = "https://rubyinstaller.org/downloads/archives/"

  def self.prefix(version : String) : String
    if version == RvmCliTools.get_current_version
      version == RvmCliTools.get_default_version ? "=*" : "=>"
    else
      version == RvmCliTools.get_default_version ? " *" : "  "
    end
  end

  def self.run_list(io : IO = STDOUT)
    RvmCliTools.versions.reverse_each { |version| io.puts "#{prefix(version)} #{version}" }
    legend(io)
  end

  def self.run_list_verbose(io : IO = STDOUT)
    RvmCliTools.versions.reverse_each do |version|
      path = RvmCliTools.envs[version].as_s
      description = RvmCliTools.capture(File.join(path, "bin", "ruby.exe"), ["--version"]).strip
      io.puts "#{prefix(version)} #{version.ljust(14)} #{File.expand_path(path)}  #{description}"
    end
    legend(io)
  end

  def self.has_valid_msys2_path(silent = false, io : IO = STDOUT) : Bool
    return false unless path = ENV["MSYS2_PATH"]?
    if File.file?(File.join(path, "usr", "bin", "msys-2.0.dll"))
      io.puts "\nMSYS2_PATH found: #{path} ...\nFilter for ruby version(s) without devkit ..." unless silent
      true
    else
      io.puts "MSYS2_PATH is set, but seems to be invalid: #{path} ... ignoring path ..." unless silent
      false
    end
  end

  def self.parse_releases(html : String, without_devkit = false) : Array(Release)
    regex = without_devkit ? /href="([^"]*[Rr]ubyinstaller-([^"-]*)[-]?[0-9]?-x64.exe)"/ : /href="([^"]*[Dd]evkit-([^"-]*)[-]?[0-9]?-x64.exe)"/
    html.scan(regex).map { |match| Release.new(match[1], match[2]) }
  end

  def self.ruby_installer_releases_list(io : IO = STDOUT) : Array(Release)
    html = RvmCliTools.fetch_text(ARCHIVES_URL)
    parse_releases(html, has_valid_msys2_path(io: io))
  rescue ex
    io.puts "Error retrieving releases from #{ARCHIVES_URL}\n\nAre you using a proxy? If yes, ensure you have configured a valid proxy with rvm config. See more information by running rvm help."
    raise ex
  end

  def self.github_releases_list : Array(Release)
    response = JSON.parse(RvmCliTools.fetch_text("https://api.github.com/repos/oneclick/rubyinstaller2/releases"))
    without_devkit = has_valid_msys2_path
    response.as_a.flat_map do |release|
      release["assets"].as_a.compact_map do |asset|
        url = asset["browser_download_url"].as_s
        name = asset["name"].as_s
        next unless url.ends_with?("x64.exe") && name.includes?("devkit") != without_devkit
        version = name.sub("rubyinstaller-devkit-", "").sub("rubyinstaller-", "").sub("-x64.exe", "")[0, 5]
        Release.new(url, version)
      end
    end
  end

  def self.release_versions(releases : Array(Release), latest_minor = false) : Array(String)
    versions = releases.map(&.version).sort { |a, b| RvmCliTools.version_sort(b, a) }
    versions = versions.uniq { |version| version.split('.')[0, 2].join('.') } if latest_minor
    versions.map { |version| "ruby-#{version}" }
  end

  def self.run_list_all(silent = false, io : IO = STDOUT, releases : Array(Release)? = nil) : Array(String)
    io.puts "\nRetrieving all x64 devkit releases on\n#{ARCHIVES_URL}\n..." unless silent
    versions = release_versions(releases || ruby_installer_releases_list(io))
    io.puts "\n - #{versions.join("\n - ")}" unless silent
    versions
  end

  def self.run_list_known(silent = false, io : IO = STDOUT, releases : Array(Release)? = nil) : Array(String)
    io.puts "\nRetrieving latest minor x64 devkit releases on\n#{ARCHIVES_URL}\n..." unless silent
    versions = release_versions(releases || ruby_installer_releases_list(io), latest_minor: true)
    io.puts "\n - #{versions.join("\n - ")}" unless silent
    versions
  end

  def self.run_list_upgrades(io : IO = STDOUT)
    io.puts "Checking for available upgrades for installed ruby environments ...\n"
    releases = run_list_known(true, io)
    RvmCliTools.envs.each_key do |version|
      minor = version.split('.')[0, 2].join('.')
      upgrade = RvmCliTools.matching_version(minor, releases)
      io.puts "#{version} >> #{upgrade == version ? "(up to date)" : upgrade}"
    end
  end

  def self.legend(io : IO = STDOUT)
    io.puts "\n# => - current\n# =* - current && default\n#  * - default"
  end
end
