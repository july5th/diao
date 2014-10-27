# encoding: utf-8

require 'red_storm'
require 'diao/diao'

module Diao
    class SrcIpGroupCheckBolt < ::RedStorm::DSL::Bolt

      # 根据源IP分组的检测预警Bolt,包含功能如下：
      # 1.返回状态预警
      #   对异常的返回状态比率预警。
      # 2.频率预警
      #   对异常的请求频率预警。
      #
      # 配置文件：diao/config/config.yml
      # 字段src_ip_group_alert:
      #  common:
      #    win_time : 5
      #    min_request_count : 10
      #  response_status:
      #    below:
      #      200 : 80
      #    above:
      #      404 : 90
      #  request_frequency:
      #    below:
      #      200
      #   
      # 输出:
      #   data : 数据
      #   name : 报警bolt名称
      #   type : 报警种类，可选：queue, key
      #   level: 等级 [1,2,3,4,5]

      output_fields :data, :name, :type, :level, :msg, :output_key

      on_receive do |tuple|
        @config = @configure.load_config
        ip = tuple['src_ip']
        add_status(ip, tuple['code'])
        if clear_by_win_time(ip) == false
          nil
        else
          r_tuple = []
          m = check_status(ip)      
          r_tuple.push([::Diao::CommonOutput.get_output(tuple).to_json, "response_status_alert", "queue", 1, m, tuple['src_ip']]) if m

          n = check_request_freq(ip) 
          r_tuple.push([::Diao::CommonOutput.get_output(tuple).to_json, "request_frequency_alert", "queue", 1, n, tuple['src_ip']]) if n

          r_tuple.empty? ? nil : r_tuple
        end
      end

      on_init do
        @configure = ::Diao::CommonConfigure.new('src_ip_group_alert_config', ::Diao.config[:reload_config])
        @tmp_hash = {}
      end

      def add_status(ip, code)
        @tmp_hash.update({ip => {}}) if not @tmp_hash.has_key? ip 
        @tmp_hash[ip].update({code => []}) if not @tmp_hash[ip].has_key? code
        @tmp_hash[ip][code] << Time.new.to_i
      end

      def clear_by_win_time(ip)
        i = Time.new.to_i
        @tmp_code = {}
        @tmp_count = 0
        @tmp_hash[ip].each_pair do |code, time_list|
          time_list.each do |t|
            @tmp_hash[ip][code].delete(t) if (i - t > (@config['common']['win_time'].to_i * 60))
          end
          @tmp_code.update({code => @tmp_hash[ip][code].size}) if @tmp_hash[ip][code].size > 0
          @tmp_count += @tmp_hash[ip][code].size
        end
        return false if @tmp_count == 0 or @tmp_count < @config['common']['min_request_count'].to_i
        return true
      end

      def check_status(ip)
        if @config['response_status']['below'] and (not @config['response_status']['below'].empty?)
          @config['response_status']['below'].each_pair do |k, v|
            k = k.to_i
            return "#{k} below #{v}%" if @tmp_code.has_key?(k) and @tmp_code[k].to_f / @tmp_count.to_f * 100 < v.to_i
          end
        end
        if @config['response_status']['above'] and (not @config['response_status']['above'].empty?)
          @config['response_status']['above'].each_pair do |k, v|
            k = k.to_i
            return "#{k} above #{v}" if @tmp_code.has_key?(k) and @tmp_code[k].to_f / @tmp_count.to_f * 100 > v.to_i
          end
        end

        return false
      end

      def check_request_freq(ip)
        return "request #{@tmp_count} above #{@config['request_frequency']['above']}" if @tmp_count > @config['request_frequency']['above']
        return false
      end
    end
end
