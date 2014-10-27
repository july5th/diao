
module Diao

  @@config = 
  {
      :redis => {
        :host => '10.10.40.72',
        :port => 6379,
        :password => nil,
      },

      :reload_config => 1000
  }

  def self.config
    @@config
  end
end

#:database:
#    :adapter: mysql2
#    :encoding: utf8
#    :database: an
#    :pool: 5
#    :username: root
#    :password:
#    :host: localhost
