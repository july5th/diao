# encoding: utf-8

require 'red_storm'
require 'diao/diao'
require 'json'

module Diao
    class WordAlertBolt < ::RedStorm::DSL::Bolt

      # 关键字报警Bolt
      #   会对触发的关键字做IP维度的频率报警。
      #
      # 配置文件：diao/config/config.yml
      # 字段word_alert
      #   word:
      #     all : [sqlmap, hahaha]
      #     url : [sqlmap]
      #  rate:
      #     5: 1

      # 输出:
      #   data : 数据
      #   name : 报警bolt名称
      #   type : 报警种类，可选：queue, key
      #   level: 等级 [1,2,3,4,5]

      output_fields :data, :name, :type, :level, :msg, :output_key

      on_receive do |tuple|
	@config = @configure.load_config
        is_alert = ::Diao::CommonWordMatch.word_match(tuple, @config['word'])
        if is_alert != false
          [::Diao::CommonOutput.get_output(tuple).to_json, "word_alert", "queue", 1, "word_alert:#{is_alert.to_json}", "#{tuple['src_ip']}_#{is_alert.keys[0]}_#{is_alert.values[0]}"]
        else
          nil
        end
      end

      on_init do
	@configure = ::Diao::CommonConfigure.new('word_alert_config', ::Diao.config[:reload_config])
      end
    end
end
