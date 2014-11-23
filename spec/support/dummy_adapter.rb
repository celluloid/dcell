module DCell::Registry
  class DummyAdapter
    def initialize(options)
      @options = options
    end

    def unique
      @options[:seed]
    end
  end

  class NoopAdapter
    def initialize(options)
    end
  end
end
