require 'forwardable'
require 'uri'

module DCell
  module Gossip
    class VersionVector
      extend Forwardable

      class Status
        STATES = [:precedes, :equal, :concurrent, :succeeds]
        
        STATES.each do |state|
          class_eval %Q{
            def #{state}?
              @state == '#{state}'.to_sym
            end
            def #{state}!
              @state = '#{state}'.to_sym
            end
          }
        end
      end

      def_delegators :@versions, :[]
      attr_reader :versions
      
      def initialize(id)
        @versions = {}
        update_at id
      end

      def update_at(id)
        observe id
        @versions[id] += 1
        Celluloid::Logger.debug "Vector updated #{self.to_s}"
      end
      
      def observe(id)
        @versions[id] ||= 0
      end

      def compare(other)
        v1_bigger = false
        v2_bigger = false

        @versions.each do |id, version|
          if not other.versions.include? id
            v1_bigger = true if version > 0
          else
            v1_bigger = true if version > other.versions[id]
            v2_bigger = true if version < other.versions[id]
          end
        end

        other.versions.each do |id, version|
          if not @versions.include? id
            v2_bigger = true if version > 0
          else
            v2_bigger = true if version > @versions[id]
            v1_bigger = true if version < @versions[id]
          end
        end

        status = Status.new
        if !v1_bigger
          if !v2_bigger
            status.equal!
          else
            status.precedes!
          end
        elsif !v2_bigger
          status.succeeds!
        else
          status.concurrent!
        end
        return status
      end

      # Take the entrywise maximum of the versions
      def merge!(other)
        @versions.each do |id, version|
          if other.versions.include? id
            @versions[id] = other.versions[id] if other.versions[id] > version
          end
        end

        other.versions.each do |id, version|
          if @versions.include? id
            @versions[id] = @versions[id] if @versions[id] > version
          end
        end
        @versions.merge!(other.versions.reject { |k,v| @versions.include? k })
      end

      def to_s
        @versions.to_s
      end
    end

    class Store
      class Data
        attr_reader :key, :value, :vector, :changed
        def initialize(key, value, id)
          @key    = key
          @value  = value
          @vector = VersionVector.new(id)
          changed!
        end

        def clear
          @vector.update_at DCell.id
          @deleted = true
          @value   = nil
          changed!
        end

        def deleted?
          @deleted
        end

        def send?
          if @changed > 0
            @changed -= 1
            true
          else
            false
          end
        end

        def changed!
          @changed = 2
        end

        def observe
          @vector.observe DCell.id
        end

        def value=(value)
          if @value != value
            @vector.update_at DCell.id
            @value   = value
            @deleted = value.nil?
            changed!
            Celluloid::Logger.debug "Updated key #{key} to #{value}"
          end
        end

        def merge!(other)
          # We'll take other if we preceded it, or if we are
          # concurrent with it (though issue a warning that data
          # has been lost).
          status = @vector.compare(other.vector)
          if status.precedes? or status.concurrent?
            if other.value != @value
              if status.concurrent?
                Celluloid::Logger.info "Dropping local copy of concurrent data for #{@key}, #{@vector}, other #{other.vector}"
              else
                Celluloid::Logger.debug "Observed updated data #{key} => #{other.value}"
              end
              @value   = other.value
              @deleted = @value.nil?
              @changed = other.changed - 1
            end
          elsif status.succeeds?
            Celluloid::Logger.info "Data succeeds for #{@key}"
          end
          unless status.equal?
            Celluloid::Logger.debug "Merging #{other.vector} into #{@vector}"
            @vector.merge!(other.vector)
            Celluloid::Logger.debug "Merged vector #{@vector}"
          end
        end
      end

      def initialize(base_path)
        @base_path = base_path
        @data = {}
      end

      def path_for(key)
        "#{@base_path}/#{key}"
      end

      def get(key)
        data = @data[path_for(key)]
        return data.value if data and not data.deleted?
        nil
      end
      
      def set(key, value)
        key = path_for(key)
        if not @data[key]
          @data[key] = Data.new(key, value, DCell.id)
        else
          @data[key].value = value
        end
      end

      def observe(other)
        key = other.key
        if not @data[key]
          @data[key] = other
          @data[key].observe
          Celluloid::Logger.debug "Observed new data #{key} => #{other.value}"
        else
          @data[key].merge!(other)
        end
      end

      def keys
        @data.keys
      end

      def clear
        @data.map(&:clear)
      end

      def changed
        @data.each_value.select(&:send?)
      end
    end
  end
end
