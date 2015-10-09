require 'ircfly/fly'

module Ircfly
  class Swarm

    def initialize
      @bots = Array.new
      @bots_ready = Array.new
      @fence_complete = Array.new
      @fence_mutex = Mutex.new
    end

    def fly(server: 'irc.test.com', port: 6667, nick: 'bot', ssl: false, password: '', name: 'Bot', user: 'Bot')
      bot = Fly.new(server: server, port: port, nick: nick, ssl: ssl, password: password, name: name, user: user, swarm: self)
      @bots << bot
      bot
    end

    def perform(&block)
      @execute = block
    end

    def fence
      return unless ready?
      @fence_mutex.synchronize do
        @fence_waiting = Array.new
      end

      @bots.each do |b|
        b.fence()
      end

      sleep(1) until @fence_mutex.synchronize { @fence_complete.count == @bots.count }
    end

    def fence_complete(bot)
      @fence_mutex.synchronize { @fence_complete << bot }
    end

    def ready?
      @bots.count == @bots_ready.count
    end

    def ready(bot)
      @bots_ready << bot
      if @bots.count == @bots_ready.count
        @execute.call
        @bots.each do |b|
          b.quit
        end
      end
    end

    def execute
      @bots.each do |b|
        b.start
      end
      @bots.each do |b|
        b.wait
      end
    end

  end
end
