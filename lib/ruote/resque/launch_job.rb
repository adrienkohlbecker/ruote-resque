module Ruote
module Resque

  module LaunchJob

    def self.queue
      Ruote::Resque.configuration.launch_queue
    end

    def self.perform(*args)
      #noop
    end

  end

end
end
