# encoding: utf-8

require 'red_storm'
require 'diao/diao'
require 'elasticsearch'
require 'time'

module Diao
    class ElasticsearchOutputBolt < ::RedStorm::DSL::Bolt

      output_fields :data

      on_receive do |tuple|
	@client.transport.reload_connections!
        index_name = "log-#{Time.now.strftime('%Y.%m.%d')}"
        #body_hash = ::Diao::CommonOutput.get_output(tuple)
      
	body_hash = { \
		'guestip' => tuple['src_ip'], \
		'real_url' => tuple['real_url'], \
		'requesthost' => tuple['host'], \
		'code' => tuple['code'], \
		'method' => tuple['method'], \
		'ua' => tuple['useragent'], \
		'referer' => tuple['referer'], \
		'cookie' => tuple['cookie'], \
		'url' => tuple['url'], \
		'data' => nil, \
		'time' => tuple['time'], \
		'byte' => 0,\
	}

        body_hash['@timestamp'] = Time.at(body_hash['time']).utc.iso8601(3)
        body_hash['time_str'] = Time.at(body_hash['time']).strftime('%Y-%m-%d %H:%M:%S')

        @client.index index: index_name, type: 'log', body: body_hash
        nil
      end

      on_init do
        @client = Elasticsearch::Client.new url: 'http://10.10.40.71:9200'
      end

    end
end
