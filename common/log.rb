require 'redis'
require 'json'

module Diao
  class CommonLog
    def self.alert v
      CommonQueue.lpush "log_alert_queue", v
    end

    def self.error v
      CommonQueue.lpush "log_error_queue", v
    end

    def self.info v
      CommonQueue.lpush "log_info_queue", v
    end
  end
end
