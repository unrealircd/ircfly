require 'cinch'

module Ircfly
  class Fly
    COMMAND_WAIT = 1

    def initialize(server: 'irc.test.com', port: 6667, nick: 'bot', ssl: false, password: '', name: 'Bot', user: 'Bot', swarm: nil)
      @swarm = swarm
      @logger = Logger.new
      @bot = Cinch::Bot.new
      @bot.loggers << @logger

      @bot.configure do |c|
        c.server = server
        c.nick = nick
        c.port = port
        c.ssl = ssl if ssl
        c.password = password if password != ''
        c.realname = name
        c.user = user
        c.reconnect = false
      end

      bot = self

      @bot.on :connect do
        swarm.ready(bot)
      end
    end

    # Lifecycle control
    def start
      @thread = Thread.new do
        @bot.start
      end
    end

    def wait
      @thread.join
    end

    # Sending IRC messages
    def send(message)
        @bot.irc.send(message)
    end


    def method_missing(name, *args, &block)
      @bot.public_send(name, args)
    end

    # Methods for expectations
    def messages
      @logger.received
    end

    def channel_with_name(name)
      @bot.channels.each do |channel|
        if channel.name == name
          return channel
        end
      end
    end

    def channel_names
      channels = Array.new
      @bot.channels.each do |channel|
        channels << channel.name
      end
      channels
    end

    def received_pattern(pattern)
      @logger.received.each do |m|
        if pattern.match(m)
          return true
        end
      end
    end

    class Logger < Cinch::Logger
      attr_reader :received

      def initialize
        super $stdout
        @mutex = Mutex.new
        @received = Array.new
      end

      def log(messages, event = :debug, level = event)
        @mutex.synchronize do
          Array(messages).each do |message|
            next if message.nil?
            @received << message
          end
        end
      end
    end

  end
end
