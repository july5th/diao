require 'redis'
require 'json'

module Diao
  class CommonQueue
    @@redis = Redis.new(::Diao.config[:redis])

    def self.lpush k, v
      @@redis.lpush k, v
    end

    def self.lpop k
      @@redis.lpop k
    end
  end
end
