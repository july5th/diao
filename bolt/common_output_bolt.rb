# encoding: utf-8

require 'red_storm'
require 'diao/diao'
require 'json'
require 'elasticsearch'
require 'time'

module Diao
    class CommonOutputBolt < ::RedStorm::DSL::Bolt

      # 通用输出Bolt
      # 根据相应输入，做出输出.
      # 接收数据如下:
      #   data : 数据
      #   name : 报警bolt名称
      #   type : 报警种类，可选：queue, key
      #   level: 等级 [1,2,3,4,5]
      #   key: 关键字，会对其重复报警做冗余

      on_receive do |tuple|
        t = @time_list.add_and_clear("#{tuple['name']}_#{tuple['output_key']}")

	if @alert_time.include?(t)
          tmp_hash = JSON.parse tuple['data']
          tmp_hash['output_time'] = Time.now.to_i
          tmp_hash['output_name'] = tuple['name']
          tmp_hash['common_msg'] = tuple['msg']
          tmp_hash['output_msg'] = "30m hit #{t} times"
          # 首先对所有数据存入Queue 或 Cache 中
          if tuple["type"] == "queue"
            ::Diao::CommonQueue.lpush "diao_output_queue", tmp_hash.to_json
          elsif tuple["type"] == "key"
            ::Diao::CommonCache.set "#{tuple["name"]}_output_key", tuple[0]
          end

	  @client.transport.reload_connections!
          index_name = "logstash-#{Time.now.strftime('%Y.%m.%d')}"

	  body_hash = {}
          body_hash['@timestamp'] = Time.at(tmp_hash['time']).utc.iso8601(3)
          body_hash['host'] = 'storm'
          body_hash['datetime'] = Time.at(tmp_hash['time']).strftime('%m/%d/%Y-%H:%M:%S')
          body_hash['desc'] = tuple['msg']
          body_hash['classification'] = tuple['name']
          body_hash['level'] = 1
          body_hash['pro'] = 'TCP'
          body_hash['srcip'] = tmp_hash['src_ip']
          body_hash['dstip'] = tmp_hash['dst_ip']
          body_hash['real_url'] = tmp_hash['real_url']
          body_hash['dsthost'] = tmp_hash['host']
          body_hash['alertfrom'] = 'storm'
          body_hash['times'] = t
	  
          @client.index index: index_name, type: 'logs', body: body_hash
	end

        # 根据报警等级做进一步处理:
        # 稍候完善
        # 最后一个bolt? 不输出
        nil
      end

      on_init do
        @tmp_hash = {}
        @time_list = ::Diao::CommonTimeList.new(30 * 60)
        @alert_time = [1,3,5,10,30,50,100,300,500,1000]
	@client = Elasticsearch::Client.new url: 'http://10.10.40.60:9200'
      end

    end
end
