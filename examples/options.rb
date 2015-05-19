require 'dcell/registries/redis_adapter'

def registry
  DCell::Registry::RedisAdapter.new
end
