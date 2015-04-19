require 'dcell'
require 'reel'
require 'pathname'
require 'erb'

module DCell
  # Web UI for DCell
  # TODO: rewrite this entire thing with less hax
  class Explorer < Reel::Server
    ASSET_ROOT = Pathname.new File.expand_path('../../../explorer', __FILE__)

    def initialize(host = '127.0.0.1', port = 7778)
      super(host, port, &method(:on_connection))
    end

    def on_connection(connection)
      request = connection.request
      return unless request
      route connection, request
    end

    def route(connection, request)
      if request.url == '/'
        path = 'index.html'
      else
        path = request.url[%r{^/([a-z0-9\.\-_]+(/[a-z0-9\.\-_]+)*)$}, 1]
      end

      if !path or path['..']
        Logger.info "404 Not Found: #{request.path}"
        connection.respond :not_found, 'Not found'
        return
      end

      render_resource connection, path
    end

    def render_resource(connection, path)
      if node_id = path[%r{^nodes/(.*)$}, 1]
        node = DCell::Node[node_id] rescue nil
        path = 'index.html'
      else
        node = DCell.me
      end

      asset_path = ASSET_ROOT.join(path)
      if asset_path.exist?
        asset_path.open('r') do |file|
          connection.respond :ok, file
        end

        Logger.info "200 OK: /#{path}"
      elsif File.exist?(asset_path.to_s + '.erb') and node
        connection.respond :ok, render_template(asset_path.to_s + '.erb', node)
        Logger.info "200 OK: /#{path}"
      else
        connection.respond :not_found, 'Not found'
        Logger.info "404 Not Found: /#{path}"
      end
    end

    def render_template(template, node)
      @node = node
      @info = @node[:info].to_hash

      template = ERB.new File.read(template, mode: 'rb')
      template.result(binding)
    end

    def node_path(node)
      "/nodes/#{node.id}"
    end
  end
end
