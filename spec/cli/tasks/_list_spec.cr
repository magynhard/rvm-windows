require "../../spec_helper"

describe RvmCliList do
  it "lists installed versions in descending numeric order and includes the legend" do
    Fixtures.with_home do
      io = IO::Memory.new
      RvmCliList.run_list(io)
      lines = io.to_s.lines
      %w(ruby-3.2.6 ruby-3.1.5 ruby-3.0.7 ruby-2.4.10).each_with_index do |version, i|
        lines[i].should contain(version)
      end
      lines.first.should start_with("=* ")
      io.to_s.should contain("# => - current")
      RvmCliTools.set_current_version("ruby-3.0.7")
      io.clear
      RvmCliList.run_list(io)
      io.to_s.should contain(" * ruby-3.2.6")
      io.to_s.should contain("=> ruby-3.0.7")
    end
  end

  it "parses archives and lists all releases including duplicate builds" do
    releases = RvmCliList.parse_releases(File.read(File.expand_path("../../fixtures/archives.html", __DIR__)))
    releases.size.should be > 10
    versions = RvmCliList.run_list_all(true, releases: releases)
    %w(ruby-3.2.6 ruby-3.1.5 ruby-3.0.7 ruby-2.4.10).each { |version| versions.should contain(version) }
    versions.count("ruby-3.4.4").should eq(2)
    versions.should_not contain("ruby-3.4.5-1")
  end

  it "lists the latest patch of every known minor version" do
    releases = RvmCliList.parse_releases(File.read(File.expand_path("../../fixtures/archives.html", __DIR__)))
    versions = RvmCliList.run_list_known(true, releases: releases)
    versions.size.should be > 5
    %w(3.4 3.3 3.2 3.1 3.0 2.7 2.6 2.5 2.4).each do |minor|
      versions.join(',').should contain("ruby-#{minor}")
    end
    versions.should contain("ruby-3.2.9")
    versions.should_not contain("ruby-3.2.6")
  end

  it "selects non-devkit links only for an existing MSYS2 DLL" do
    Fixtures.with_home do |home|
      ENV["MSYS2_PATH"] = File.join(home, "central msys")
      RvmCliList.has_valid_msys2_path(true).should be_false
      RvmCliTools.write_file(File.join(ENV["MSYS2_PATH"], "usr/bin/msys-2.0.dll"), "")
      RvmCliList.has_valid_msys2_path(true).should be_true
      releases = RvmCliList.parse_releases(File.read(File.expand_path("../../fixtures/archives.html", __DIR__)), true)
      releases.size.should eq(1)
      releases.first.url.should_not contain("devkit")
    end
  end
end
