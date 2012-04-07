require 'dcell'
require 'reel'
require 'pathname'
require 'erb'

module DCell
  class Explorer
    ASSET_ROOT = Pathname.new File.expand_path("../../../explorer", __FILE__)

    def initialize(host = "127.0.0.1", port = 7778)
      @server = Reel::Server.new(host, port, &method(:handle_connection))
    end

    # TODO: real static file service for Reel :/
    def handle_connection(connection)
      request = connection.request
      return unless request

      if request.url == "/"
        path = "index.html"
      else
        path = request.url[%r{^/([a-z0-9\.\-_]+(/[a-z0-9\.\-_]+)*)$}, 1]
      end

      unless path or path[".."]
        Celluloid::Logger.info "404 Not Found: #{request.path}"
        connection.respond :not_found, "Not found"
        return
      end

      asset_path = ASSET_ROOT.join(path)
      if asset_path.exist?
        file = File.read(asset_path.to_s, :mode => 'rb')
        connection.respond :ok, file
        Celluloid::Logger.info "200 OK: #{request.url}"
      elsif File.exist?(asset_path.to_s + ".erb")
        template = ERB.new File.read("#{asset_path.to_s}.erb", :mode => 'rb')
        connection.respond :ok, template.result(binding)
      else
        connection.respond :not_found, "Not found"
        Celluloid::Logger.info "404 Not Found: #{request.url}"
      end
    end
  end
end
