require 'resque'
require 'ruote/resque'

RSpec.configure do |config|

  config.mock_with :rspec

  config.after(:each) do
    Resque.queues.each{|queue| Resque.remove_queue(queue) }
  end

end
