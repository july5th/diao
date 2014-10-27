#!/usr/bin/env ruby
# -*- coding: binary -*-

require 'yaml'
require 'json'
require 'redis'

begin
  @@config = YAML::load File.open("./config/config.yml")
  redis = Redis.new
rescue => e
  p "#{e}"
  exit
end

@@config.each_pair do |k, v|
  rk = "#{k}_config"
  p "set k:#{rk}, v:#{v}"
  redis.set rk, v.to_json
end

