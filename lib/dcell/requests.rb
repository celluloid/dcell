module DCell
  # Locate a register actor by name on a remote node
  class LookupRequest
    attr_reader :caller, :name

    def initialize(caller, name)
      @caller, @name = caller, name
    end
  end
end
