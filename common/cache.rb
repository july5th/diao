require 'redis'
require 'json'

module Diao
  class CommonCache
    @@redis = Redis.new(::Diao.config[:redis])

    def self.set k, v
      @@redis.set k, v
    end

    def self.get k
      @@redis.get k
    end
  end
end
