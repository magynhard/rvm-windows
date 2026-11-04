# Harmless setup stand-in: logs arguments and exits; never installs anything.
require "json"
File.write(ENV["RVM_TEST_SETUP_ARGS"], ARGV.to_json) if ENV["RVM_TEST_SETUP_ARGS"]?
exit (ENV["RVM_TEST_SETUP_EXIT"]? || "0").to_i
