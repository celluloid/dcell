module DCell
  # Global object registry shared among all DCell nodes
  module Global
    extend self

    # Get a global value
    def get(key)
      DCell.registry.get_global key.to_s
    end
    alias_method :[], :get

    # Set a global value
    def set(key, value)
      DCell.registry.set_global key.to_s, value
    end
    alias_method :[]=, :set

    # Get the keys for all the globals in the system
    def keys
      DCell.registry.global_keys.map(&:to_sym)
    end
  end
end
