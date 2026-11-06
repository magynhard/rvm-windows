require "../_tools"
require "./_install"
require "semantic_version"

class RvmCliGet
  REPOSITORY = "magynhard/rvm-windows"

  def self.release_is_newer?(release_version : String, current_version : String) : Bool
    SemanticVersion.parse(release_version) > SemanticVersion.parse(current_version)
  end

  def self.update_status_path(root : String, session : String) : String
    File.join(root, ".rvm-update-#{session}.status")
  end

  def self.updater_script(pid : Int, destination : String, root : String, status_path : String) : String
    escaped = destination.gsub("'", "''")
    escaped_root = root.gsub("'", "''")
    escaped_status = status_path.gsub("'", "''")
    # Windows PowerShell 5.1 reads scripts without a BOM using the system ANSI
    # codepage, which corrupts non-ASCII installation and download paths.
    "\uFEFF" + <<-POWERSHELL
      $ErrorActionPreference = 'Stop'
      $log = $PSCommandPath + '.log'
      $status = '#{escaped_status}'
      try {
        Wait-Process -Id #{pid} -ErrorAction SilentlyContinue
        $setup = Start-Process -FilePath '#{escaped}' -ArgumentList '/S /D=#{escaped_root}' -Wait -PassThru
        [IO.File]::WriteAllText($log, "Setup exit code: $($setup.ExitCode)`r`n", [Text.UTF8Encoding]::new($true))
        [IO.File]::WriteAllText($status, [string]$setup.ExitCode, [Text.Encoding]::ASCII)
        exit $setup.ExitCode
      } catch {
        [IO.File]::WriteAllText($log, $_.Exception.ToString(), [Text.UTF8Encoding]::new($true))
        [IO.File]::WriteAllText($status, '1', [Text.Encoding]::ASCII)
        exit 1
      }
      POWERSHELL
  end

  def self.print_update_instructions(io : IO, version : String, log : String, launcher_waits : Bool)
    if launcher_waits
      io.puts "Updating rvm-windows to #{RvmCliColor.primary(version, io)}..."
    else
      io.puts "Updating rvm-windows to #{RvmCliColor.primary(version, io)} in the background."
      io.puts "Direct executable invocation does not wait; use rvm.cmd or rvm.ps1 to wait for setup completion."
      io.puts "Result log: #{log}"
    end
  end

  def self.run_get(io : IO = STDOUT, latest_url : String = "https://api.github.com/repos/#{REPOSITORY}/releases/latest")
    old_version = RvmCliVersion.get_version
    io.puts "Current version is #{RvmCliColor.primary(old_version, io)}."
    io.puts "Checking for updates..."
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
    # The launcher waits on this per-session marker after the executable exits.
    # NSIS then refreshes wrappers using the new executable.
    session = ENV["RVM_SESSION"]?
    status_path = update_status_path(RvmCliTools.rvm_root_path, session || Process.pid.to_s)
    if session && File.file?(status_path) && File.read(status_path).strip == "pending"
      raise "An RVM update is already in progress for this terminal session."
    end
    RvmCliTools.write_file(status_path, "pending")
    script = File.join(RvmCliTools.get_rvm_data_dir, "downloads", "update-#{Process.pid}.ps1")
    # NSIS requires /D to be the last, unquoted portion of the raw command line.
    begin
      RvmCliTools.write_file(script, updater_script(Process.pid, destination, RvmCliTools.rvm_root_path, status_path))
      Process.new("powershell.exe", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script],
        input: Process::Redirect::Close, output: Process::Redirect::Close, error: Process::Redirect::Close)
    rescue ex
      File.delete(status_path) if File.exists?(status_path)
      raise ex
    end
    launcher_waits = ENV["RVM_UPDATE_LAUNCHER"]? == "1"
    print_update_instructions(io, new_version, "#{script}.log", launcher_waits)
  end
end
