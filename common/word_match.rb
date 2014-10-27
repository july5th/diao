require 'redis'
require 'json'

module Diao
  class CommonWordMatch

    def self.word_match(target_hash, match_hash)
      is_alert = false
      match_hash.each_pair do |k, v|
        if k == "all"
          target_hash.each_pair do |k2, v2|
            v.each do |v3|
              if word_match_func(v2.to_s.downcase, v3.to_s.downcase)
                is_alert = {k => v3}
                break
              end
            end
          end
        elsif target_hash.has_key?(k)
          v.each do |v3|
            if word_match_func(target_hash[k].to_s.downcase, v3.to_s.downcase)
              is_alert = {k => v3}
              break
            end
          end
        end
        break if is_alert != false
      end
      return is_alert
    end

    def self.word_match_func(raw_string, match_string)
      raw_string =~ /#{match_string}/ ? true : false
    end
  end
end
