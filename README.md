[![Build Status](https://travis-ci.org/adrienkohlbecker/ruote-resque.png)](https://travis-ci.org/adrienkohlbecker/ruote-resque) [![Coverage Status](https://coveralls.io/repos/adrienkohlbecker/ruote-resque/badge.png?branch=master)](https://coveralls.io/r/adrienkohlbecker/ruote-resque) [![Code Climate](https://codeclimate.com/github/adrienkohlbecker/ruote-resque.png)](https://codeclimate.com/github/adrienkohlbecker/ruote-resque) [![Dependency Status](https://gemnasium.com/adrienkohlbecker/ruote-resque.png)](https://gemnasium.com/adrienkohlbecker/ruote-resque)

# Ruote::Resque

- **Homepage**: [github.com/adrienkohlbecker/ruote-resque](https://github.com/adrienkohlbecker/ruote-resque)
- **Rdoc**: [rdoc.info/gems/ruote-resque](http://rdoc.info/gems/ruote-resque)
- **Author**: Adrien Kohlbecker
- **License**: MIT License
- **Latest Version**: 0.0.1
- **Release Date**: `nil`

## Synopsis

Ruote::Resque allows a Ruote engine to delegates the work of it's participants to Resque workers.

Common use cases include:

- You run a lot of jobs and need the reliability of Resque to process your jobs
- You have a Resque system you need to integrate with
- You want a separation of concerns between process orchestration and actual execution

## How it works

- The library uses a specific Resque queue for message passing.
- Participants are empty shells that just queue jobs to Resque, and the job itself replies (via an after_perform hook) with the mutated workitem.
- Under the hood, a thread polls the reply queue every five seconds for new replies.
- When a reply is received, the process continues with the new workitem.

Note that:

- Ruote is not needed as a dependency on the Resque side.
- Error handling is supported on both sides (exceptions show up both on the Resque failure backend and in ruote-kit)

## Usage

### Set Up

#### Inside your Ruote instance

Add to your Ruote instance gemfile :

    # The version released on RubyGems is old and not supported.
    # Note that ruote is not a hard dependency of ruote-resque,
    # to allow for lightweight use as a client (see below)
    gem 'ruote', :git => 'git://github.com/jmettraux/ruote.git'
    gem 'ruote-resque'

Then when booting your engine do this :

```ruby

require 'ruote/resque'

# Configure the library (optional, default values shown)
Ruote::Resque.configure do |config|
  config.reply_queue = :ruote_replies
  config.logger = Logger.new(STDOUT).tap { |log| log.level = Logger::INFO }
  config.interval = 5
end

# Override the default error handler (optional, but recommended. Default is to log at ERROR level)
class Ruote::Resque::Receiver
  def handle_error(e)
    MyErrorHandler.handle(e)
  end
end

# Run the poller thread.
Ruote::Resque::Receiver.new(dashboard)

```

#### Inside your Resque worker instance

Add to your Resque worker instance gemfile :

    gem 'ruote-resque'

Then when booting your worker do this :

```ruby

# You should not require the full library inside your worker, the client will suffice
require 'ruote/resque/client'

# Duplicate the configuration if you are using custom parameters
Ruote::Resque.configure do |config|
  config.reply_queue = :ruote_replies
  config.logger = Logger.new(STDOUT).tap { |log| log.level = Logger::INFO }
  config.interval = 5
end

```

### Participants

There are two ways of registering participants.

- When your Ruote instance has access to the jobs
- When it does not (eg: jobs are on a distant worker)

#### If ruote has access to the jobs

```ruby

# Include ruote-resque inside your jobs
class MyAwesomeJob
  include Ruote::Resque::ParticipantModule
  extend Ruote::Resque::Job

  @queue = :my_queue

  def self.perform(workitem)
    workitem['fields']['be_awesome'] = true
  end
end


dashboard.register_participant 'be_awesome', MyAwesomeJob
```

#### If ruote does not have access to your jobs

```ruby

# Inside your worker, add Job to your jobs
class MyAwesomeJob
  extend Ruote::Resque::Job

  @queue = :my_queue

  def self.perform(workitem)
    workitem['fields']['be_awesome'] = true
  end
end

# Inside your Ruote instance
dashboard.register_participant 'be_awesome', Ruote::Resque::Participant, :class => 'MyAwesomeJob', :queue => :my_queue
```

## Requirements

A functional installation of [Ruote](http://ruote.rubyforge.org) and [Resque](http://github.com/resque/resque) is needed.

ruote-resque has been tested on Ruby 1.8+.

## Installation

Add this line to your application's Gemfile:

    gem 'ruote-resque'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ruote-resque

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Run the tests (`bundle exec rspec`)
6. Create new Pull Request
