require 'resque'
require 'ruote/resque'

RSpec.configure do |config|

  config.mock_with :rspec

  config.before(:suite) do
    Resque.redis.namespace = "resque:rspec"
  end

  config.after(:each) do
    Resque.queues.each{|queue| Resque.remove_queue(queue) }
  end

end
