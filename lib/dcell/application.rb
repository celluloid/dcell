module DCell
  # Actors which run when DCell is active
  class Application < Celluloid::Application
    supervise Mailbox
  end
end