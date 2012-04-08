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

    def handle_connection(connection)
      request = connection.request
      return unless request
      route connection, request
    end

    def route(connection, request)
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

      render_resource connection, path
    end

    def render_resource(connection, path)
      asset_path = ASSET_ROOT.join(path)
      if asset_path.exist?
        File.open(asset_path.to_s, "r") do |file|
          connection.respond :ok, file
        end

        Celluloid::Logger.info "200 OK: #{path}"
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
