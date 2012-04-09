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
      end
      
      def observe(id)
        @versions[id] ||= 0
      end

      def covers?(nodes, vector)
        nodes.each do |node|
          # We must have an entry for the node
          return false unless @versions.keys.include? node
          
          # And someone else must have seen the entry, too.
          version = vector.versions[node] || 0
          return false if @versions[node] != version
        end
        true
      end

      def compare(other)
        v1_bigger = false
        v2_bigger = false

        @versions.each do |id, version|
          if not other.versions.include? id
            # Version vectors behave like vector clocks, with slightly
            # different update rules. A vector clock assumes that all
            # processes initially observe version 0. Since we don't
            # know the topology ahead of time, we assume that a missing
            # entry corresponds to a node that has not yet been discovered,
            # and thus the version is implicitly 0.
            v1_bigger = true if version > 0
          else
            v1_bigger = true if version > other.versions[id]
            v2_bigger = true if version < other.versions[id]
          end
        end

        other.versions.each do |id, version|
          if not @versions.include? id
            # See the comment above for the similar v1_bigger calculation.
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
        attr_reader :key, :value, :vector
        def initialize(key, value, id)
          @key     = key
          @value   = value
          @vector  = VersionVector.new(id)
          @changed = true
        end

        def clear
          @vector.update_at DCell.id
          @deleted = true
          @value   = nil
          @changed = true
        end

        def deleted?
          @deleted
        end

        def changed?
          @changed
        end

        def observe
          @vector.observe DCell.id
        end

        def value=(value)
          if @value != value
            @vector.update_at DCell.id
            @value   = value
            @deleted = value.nil?
            @changed = true
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
                Celluloid::Logger.debug "Dropping local copy of concurrent data for #{@key}"
              else
                Celluloid::Logger.debug "Observed updated data #{key} => #{other.value}"
              end
              @value   = other.value
              @deleted = @value.nil?
            end
          elsif status.succeeds?
            Celluloid::Logger.debug "Local data succeeds for #{@key}"
          end
          @vector.merge!(other.vector) unless status.equal?

          # Stop gossiping if this has been seen by every known, healthy node
          nodes = DCell::Node.all.map { |node| node.state == :connected }
          @changed = false if @vector.covers?(nodes, other.vector)
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
        @data.keys.map { |k| k =~ /#{@base_path}\/(.+)$/; $1 }
      end

      def clear
        @data.map(&:clear)
      end

      def changed
        @data.each_value.select(&:changed?)
      end

      def values
        @data.values
      end
    end
  end
end
