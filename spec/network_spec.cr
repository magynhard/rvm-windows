require "./spec_helper"
require "http/server"

module NetworkFixtures
  def self.serve(&block : String ->)
    server = HTTP::Server.new do |context|
      case context.request.path
      when "/redirect"
        context.response.status_code = 302
        context.response.headers["Location"] = "/payload"
      when "/failure"
        context.response.status_code = 500
      else
        context.response.print "installer\u0000bytes"
      end
    end
    address = server.bind_tcp("127.0.0.1", 0)
    spawn { server.listen }
    begin
      yield "http://127.0.0.1:#{address.port}"
    ensure
      server.close
    end
  end
end

describe "HTTP transport" do
  it "streams redirects into the download cache and never caches HTTP errors" do
    Fixtures.with_home do |home|
      NetworkFixtures.serve do |url|
        destination = File.join(home, "downloads", "payload.exe")
        RvmCliInstall.download("#{url}/redirect", destination)
        File.read(destination).should eq("installer\u0000bytes")
        # Cached files do not trigger another request, even if the URL fails.
        RvmCliInstall.download("#{url}/failure", destination)
        bad_destination = File.join(home, "downloads", "bad.exe")
        expect_raises(Exception, /HTTP 500/) { RvmCliInstall.download("#{url}/failure", bad_destination) }
        File.exists?(bad_destination).should be_false
        Dir.children(File.dirname(destination)).should eq(["payload.exe"])
      end
    end
  end

  it "sends absolute HTTP proxy requests with Basic authentication" do
    Fixtures.with_home do
      server = TCPServer.new("127.0.0.1", 0)
      request_channel = Channel(String).new(1)
      spawn do
        socket = server.accept
        begin
          request = String.build do |io|
            while line = socket.gets(chomp: false)
              break if line == "\r\n" || line == "\n"
              io << line
            end
          end
          request_channel.send(request)
          socket << "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nOK"
          socket.flush
        ensure
          socket.close
        end
      end
      previous = ENV["HTTPS_PROXY"]?
      begin
        ENV.delete("HTTPS_PROXY")
        RvmCliConfig.run_proxy("http://user:pass@127.0.0.1:#{server.local_address.port}", IO::Memory.new)
        RvmCliTools.fetch_text("http://example.invalid/payload").should eq("OK")
        request = request_channel.receive
        request.should contain("GET http://example.invalid/payload HTTP/1.1")
        request.should contain("Proxy-Authorization: Basic dXNlcjpwYXNz")
      ensure
        ENV["HTTPS_PROXY"] = previous if previous
        server.close
      end
    end
  end

  it "rejects an unsuccessful HTTPS proxy CONNECT" do
    Fixtures.with_home do
      server = TCPServer.new("127.0.0.1", 0)
      spawn do
        socket = server.accept
        begin
          while line = socket.gets(chomp: false)
            break if line == "\r\n" || line == "\n"
          end
          socket << "HTTP/1.1 407 Proxy Authentication Required\r\n\r\n"
          socket.flush
        ensure
          socket.close
        end
      end
      previous = ENV["HTTPS_PROXY"]?
      begin
        ENV.delete("HTTPS_PROXY")
        RvmCliConfig.run_proxy("http://127.0.0.1:#{server.local_address.port}", IO::Memory.new)
        expect_raises(Exception, /Proxy CONNECT failed: HTTP\/1.1 407/) do
          RvmCliTools.fetch_text("https://example.invalid/payload")
        end
      ensure
        ENV["HTTPS_PROXY"] = previous if previous
        server.close
      end
    end
  end
end

if ENV["RVM_LIVE_TESTS"]? == "1"
  describe "live RubyInstaller archive (opt-in)" do
    it "retrieves the same historical versions as the original Jasmine tests" do
      Fixtures.with_home do
        releases = RvmCliList.ruby_installer_releases_list
        releases.size.should be > 10
        versions = RvmCliList.release_versions(releases)
        %w(ruby-3.2.6 ruby-3.1.5 ruby-3.0.7 ruby-2.4.10).each { |version| versions.should contain(version) }
      end
    end
  end
end
