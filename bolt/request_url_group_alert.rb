# encoding: utf-8

require 'red_storm'
require 'diao/diao'

module Diao
    class RequestUrlGroupAlertBolt < ::RedStorm::DSL::Bolt

      # 请求URL分组预警
      #   1. 统计指定时间段内IP访问的个数, 对次数异常的报警
      #   
      #
      # 配置文件：diao/config/config.yml
      # 字段request_url_group_alert
      #  common:
      #    win_time : 5
      #    min_request_count : 1
      #  min_ip_count : 1
      #
      # 输出:
      #   data : 数据
      #   name : 报警bolt名称
      #   type : 报警种类，可选：queue, key
      #   level: 等级 [1,2,3,4,5]

      output_fields :data, :name, :type, :level, :msg, :output_key

      on_receive do |tuple|
	@config = @configure.load_config
        if check_data tuple
          add_visit(tuple['real_url'], tuple['src_ip'])
          if clear_visit(tuple['real_url'])
            r = check_visit(tuple['real_url'])
            if r == false
              nil
            else
              [::Diao::CommonOutput.get_output(tuple).to_json, "request_url_alert", "queue", 1, r, tuple['real_url']]
            end
          else
            nil
          end
        else
          nil
        end
      end

      on_init do
	@configure = ::Diao::CommonConfigure.new('request_url_group_alert_config', ::Diao.config[:reload_config])
        @tmp_hash = {}
        @start_time = Time.new.to_i
      end

      def add_visit(url, ip)
        @tmp_hash.update({url => {}}) if not @tmp_hash.has_key? url 
        @tmp_hash[url].update({ip => Time.new.to_i})
      end
   
      def clear_visit(url)
        i = Time.new.to_i
        return false if i - @start_time < (@config['common']['win_time'].to_i * 60)
        @tmp_hash[url].each_pair do |ip, vt|
          @tmp_hash[url].delete(ip) if (i - vt > (@config['common']['win_time'].to_i * 60))
        end
        return true
      end

      def check_visit(url)
        visit_count = @tmp_hash[url].keys.size
        return "visit ip: #{visit_count} below #{@config['min_ip_count']}" if visit_count <= @config['min_ip_count']
        return false
      end

      def check_data data
        # white_list:
        if @config['white_list'] and not @config['white_list'].empty?
          r = ::Diao::CommonWordMatch.word_match(data, @config['white_list'])
          return false if r == false
        end

        # black_list:
        if @config['black_list'] and not @config['black_list'].empty?
          r = ::Diao::CommonWordMatch.word_match(data, @config['black_list'])
          return false if r != false
        end

        return true
      end

    end

end
