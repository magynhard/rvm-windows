# Harmless NSIS acceptance fixture. This executable must never invoke RVM or
# touch user data; tests select the failure point through an environment value.
case ARGV
when ["--internal-version"]
  if ENV["RVM_TEST_INSTALLER_FAILURE"]? == "preflight"
    STDERR.puts "simulated blocked executable"
    exit 23
  end
  puts "9.99.97"
when ["--internal-migration", "prepare"]
  exit 24 if ENV["RVM_TEST_INSTALLER_FAILURE"]? == "prepare"
when ["--internal-migration", "rollback"]
  exit 0
when ["--internal-migration", "commit"]
  exit 0
when ["--internal-install"]
  exit 25 if ENV["RVM_TEST_INSTALLER_FAILURE"]? == "deployment"
else
  exit 26
end
