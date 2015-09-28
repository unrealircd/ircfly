require 'ircfly/fly'

module Ircfly
  class Swarm

    def initialize(wait_interval)
      @wait_interval = wait_interval
      @bots = Array.new
      @bots_ready = Array.new
      @pending_messages = Array.new
    end

    def fly(server: 'irc.test.com', nick: 'bot', ssl: false, password: '', name: 'Bot', user: 'Bot')
      bot = Fly.new(server: server, nick: nick, ssl: ssl, password: password, name: name, user: user, swarm: self)
    end

    def perform(&block)
      @execute = block
    end

    def ready(bot)
      @bots_ready << bot
      if @bots.count == @bots_ready.count
        @execute.call
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
