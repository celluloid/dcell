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

      def symbolize_keys(hash)
        hash.each_with_object({}) do |(k, v), obj|
          obj[k.to_sym] = v
        end
      end
    end
  end
end
