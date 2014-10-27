
module Diao
  class CommonOutput
    def self.get_output tuple
      # output_fields :src_ip, :real_url, :host, :code, :method, :useragent, :referer, :url
      {'src_ip' => tuple['src_ip'], \
       'dst_ip' => tuple['dst_ip'], \
       'real_url' => tuple['real_url'], \
       'host' => tuple['host'], \
       'code' => tuple['code'], \
       'method' => tuple['method'], \
       'useragent' => tuple['useragent'], \
       'referer' => tuple['referer'], \
       'cookie' => tuple['cookie'], \
       'url' => tuple['url'], \
       'data' => nil, \
       'time' => tuple['time'], \
      }
    end
  end
end
