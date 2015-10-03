require 'ircfly/fly'

module Ircfly
  class Swarm

    def initialize
      @bots = Array.new
      @bots_ready = Array.new
    end

    def fly(server: 'irc.test.com', port: 6667, nick: 'bot', ssl: false, password: '', name: 'Bot', user: 'Bot')
      bot = Fly.new(server: server, port: port, nick: nick, ssl: ssl, password: password, name: name, user: user, swarm: self)
      @bots << bot
      bot
    end

    def perform(&block)
      @execute = block
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
