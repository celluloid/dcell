module DCell
  # misc helper functions
  module Utils
    class << self
      def full_const_get(name)
        list = name.split("::")
        obj = Object
        list.each do |x|
          next if x.length == 0
          obj = obj.const_get x
        end
        obj
      end
    end
  end
end
