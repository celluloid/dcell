module DCell::Registry
  class DummyAdapter
    def initialize(options)
      @options = options
      @unique = @options[:seed] || '67'
    end

    def unique
      @unique
    end
  end

  class NoopAdapter
    def initialize(options)
    end
  end
end
