require "../_tools"
require "./_install"

class RvmCliGet
  REPOSITORY = "magynhard/rvm-windows.cr"

  def self.run_get(io : IO = STDOUT)
    old_version = RvmCliVersion.get_version
    io.puts "Current version of rvm-windows is #{RvmCliVersion.get_full_version}."
    io.puts "Updating to its latest version ... please wait ..."
    release = JSON.parse(RvmCliTools.fetch_text("https://api.github.com/repos/#{REPOSITORY}/releases/latest"))
    new_version = release["tag_name"].as_s.lchop('v')
    if new_version == old_version
      io.puts "Nothing to do. rvm-windows is already up to date!"
      return
    end
    asset = release["assets"].as_a.find { |entry| entry["name"].as_s.ends_with?("-setup.exe") }
    raise "No Windows setup asset available for #{new_version}" unless asset
    destination = File.join(RvmCliTools.get_rvm_data_dir, "downloads", asset["name"].as_s)
    RvmCliInstall.download(asset["browser_download_url"].as_s, destination)
    # Start a detached updater that waits for this process before replacing the
    # running binary. NSIS then refreshes wrappers using the new executable.
    script = File.join(RvmCliTools.get_rvm_data_dir, "downloads", "update-#{Process.pid}.ps1")
    escaped = destination.gsub("'", "''")
    root = RvmCliTools.rvm_root_path.gsub("'", "''")
    RvmCliTools.write_file(script, "Wait-Process -Id #{Process.pid} -ErrorAction SilentlyContinue\n& '#{escaped}' /S \"/D=#{root}\"\nexit $LASTEXITCODE\n")
    Process.new("powershell.exe", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script],
      input: Process::Redirect::Close, output: Process::Redirect::Close, error: Process::Redirect::Close)
    io.puts "Update to #{new_version} scheduled. Setup will start after this command exits."
  end
end
