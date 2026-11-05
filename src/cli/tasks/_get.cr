require "../_tools"
require "./_install"
require "semantic_version"

class RvmCliGet
  REPOSITORY = "magynhard/rvm-windows"

  def self.release_is_newer?(release_version : String, current_version : String) : Bool
    SemanticVersion.parse(release_version) > SemanticVersion.parse(current_version)
  end

  def self.updater_script(pid : Int, destination : String, root : String) : String
    escaped = destination.gsub("'", "''")
    escaped_root = root.gsub("'", "''")
    # Windows PowerShell 5.1 reads scripts without a BOM using the system ANSI
    # codepage, which corrupts non-ASCII installation and download paths.
    "\uFEFF" + <<-POWERSHELL
      $ErrorActionPreference = 'Stop'
      $log = $PSCommandPath + '.log'
      try {
        Wait-Process -Id #{pid} -ErrorAction SilentlyContinue
        $setup = Start-Process -FilePath '#{escaped}' -ArgumentList '/S /D=#{escaped_root}' -Wait -PassThru
        [IO.File]::WriteAllText($log, "Setup exit code: $($setup.ExitCode)`r`n", [Text.UTF8Encoding]::new($true))
        exit $setup.ExitCode
      } catch {
        [IO.File]::WriteAllText($log, $_.Exception.ToString(), [Text.UTF8Encoding]::new($true))
        exit 1
      }
      POWERSHELL
  end

  def self.run_get(io : IO = STDOUT, latest_url : String = "https://api.github.com/repos/#{REPOSITORY}/releases/latest")
    old_version = RvmCliVersion.get_version
    io.puts "Current version of rvm-windows is #{RvmCliColor.primary(RvmCliVersion.get_full_version, io)}."
    io.puts "Updating to its latest version ... please wait ..."
    release = begin
      JSON.parse(RvmCliTools.fetch_text(latest_url))
    rescue ex : RvmCliTools::HttpError
      raise ex unless ex.status_code == 404
      io.puts "No stable GitHub release was found. For develop updates, install rvm-windows@develop explicitly with npm or use a newer setup."
      return
    end
    new_version = release["tag_name"].as_s.lchop('v')
    unless release_is_newer?(new_version, old_version)
      if SemanticVersion.parse(new_version) == SemanticVersion.parse(old_version)
        io.puts "Nothing to do. rvm-windows is already up to date!"
      else
        io.puts "Nothing to do. Current rvm-windows version #{old_version} is newer than the latest release #{new_version}."
      end
      return
    end
    asset = release["assets"].as_a.find { |entry| entry["name"].as_s.ends_with?("-setup.exe") }
    raise "No Windows setup asset available for #{new_version}" unless asset
    destination = File.join(RvmCliTools.get_rvm_data_dir, "downloads", asset["name"].as_s)
    RvmCliInstall.download(asset["browser_download_url"].as_s, destination)
    # Start a detached updater that waits for this process before replacing the
    # running binary. NSIS then refreshes wrappers using the new executable.
    script = File.join(RvmCliTools.get_rvm_data_dir, "downloads", "update-#{Process.pid}.ps1")
    # NSIS requires /D to be the last, unquoted portion of the raw command line.
    RvmCliTools.write_file(script, updater_script(Process.pid, destination, RvmCliTools.rvm_root_path))
    Process.new("powershell.exe", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script],
      input: Process::Redirect::Close, output: Process::Redirect::Close, error: Process::Redirect::Close)
    io.puts "Update to #{RvmCliColor.primary(new_version, io)} scheduled. Setup will start after this command exits."
    io.puts "Setup runs silently. Result log: #{script}.log"
  end
end
