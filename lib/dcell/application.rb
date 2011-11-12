module DCell
  # Actors which run when DCell is active
  class Application < Celluloid::Application
    supervise Server, :as => :dcell_server
  end
end