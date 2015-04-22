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

      if !path || path['..']
        Logger.info "404 Not Found: #{request.path}"
        connection.respond :not_found, 'Not found'
        return
      end

      render_resource connection, path
    end

    def resolve_resource(path)
      id = path[%r{^nodes/(.*)$}, 1]
      if id
        node = DCell::Node[id] rescue nil # rubocop:disable Style/RescueModifier
        path = 'index.html'
      else
        node = DCell.me
      end
      [path, node]
    end

    def respond(connection, path, status, what)
      connection.respond status, what
      status = Reel::Response::SYMBOL_TO_STATUS_CODE[status]
      reason = Reel::Response::STATUS_CODES[status]
      Logger.info "#{status} #{reason}: /#{path}"
    end

    def render_resource(connection, path)
      path, node = resolve_resource path
      asset = ASSET_ROOT.join path

      if asset.exist?
        respond connection, path, :ok, asset.open('r')
      elsif File.exist?(asset.to_s + '.erb') && node
        respond connection, path, :ok, render_template(asset.to_s + '.erb', node)
      else
        respond connection, path, :not_found, 'Not found'
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
