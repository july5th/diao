require 'red_storm'
require 'diao/diao'
require 'json'
require 'uri'

module Diao
    class RedisInputSpout < ::RedStorm::DSL::Spout
      output_fields :src_ip, :dst_ip, :real_url, :host, :code, :method, :useragent, :referer, :url, :data, :time, :cookie

      on_send do
	@config = @configure.load_config
        get_data
      end

      on_init do
	@configure = ::Diao::CommonConfigure.new('before_filter_config', ::Diao.config[:reload_config])
      end

      def get_data
        begin
          data = ::Diao::CommonQueue.lpop "diao_input_queue"
          if data
            data = JSON.parse data
            if check_data data
              src_ip = data['src'].split(':')[0]
              dst_ip = data['dst'].split(':')[0]
              if data['host']
                host = data['host']
              else
                host = data['dst'].split(':')[0]
              end
              uri = URI(URI::escape("http://#{host}#{data['url']}"))
              url = uri.host + uri.path
              [src_ip, dst_ip, url, data['host'], data['code'], data['method'], data['user-agent'], data['referer'], data['url'], data['data'], data['time'], data['cookie']]
            else
              nil
            end
          else
            nil
          end
        rescue => e
          ::Diao::CommonLog.error e.to_s
          nil
        end
      end

      def check_data data
        # 检测数据key
        if not data.has_key?('src') \
             or not data.has_key?('dst') \
             or not data.has_key?('url') \
             or not data.has_key?('code') \
             or not data.has_key?('host') 
           return false
        end
        
        # 检测url格式
        return false if data['url'][0] != '/'
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
