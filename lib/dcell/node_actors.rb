module DCell
  # Node actor tracker
  class Node
    module Actors
      def init_actors
        @actors = ResourceManager.new
      end

      def add_actor(actor)
        @actors.register(actor.object_id) { actor }
      end

      def kill_actors
        @actors.clear do |id, actor|
          begin
            actor.terminate
          rescue Celluloid::DeadActorError
          end
        end
      end
    end
  end
end
