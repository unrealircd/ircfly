require 'cinch'
require 'delegate'
require 'securerandom'
require 'thread'

module Ircfly
  class Fly < SimpleDelegator
    def initialize(server: 'irc.test.com', port: 6667, nick: 'bot', ssl: false, password: '', name: 'Bot', user: 'Bot', swarm: nil)
      @swarm = swarm
      @logger = Logger.new
      @pong_mutex = Mutex.new
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
        c.messages_per_second = 100
      end

      bot = self
      super(@bot)

      @bot.on :connect do
        swarm.ready(bot)
      end

      @bot.on :pong do |msg|
        bot.pong_received(msg)
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

    def pong_received(message)
      ack_received = false
      @pong_mutex.synchronize do
        if message.raw.include?(@pong_token)
          @pong_token = nil
          ack_received = true
        end
      end
      @swarm.fence_complete(self) if ack_received
    end

    def fence
      @pong_mutex.synchronize do
        @pong_token = SecureRandom.uuid
        send("PING :#{@pong_token}")
      end
    end

    # Sending IRC messages
    def send(message)
        @bot.irc.send(message)
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
