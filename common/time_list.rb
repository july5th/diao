
module Diao
  class CommonTimeList
    def initialize(win_time)
      @win_time = win_time
      @tmp_hash = {}
    end

    def add_and_clear(key)
      add(key)
      time_clear(key)
      value_size(key)
    end

    def add(key)
      @tmp_hash.update({key => []}) if not @tmp_hash.has_key? key
      @tmp_hash[key] << Time.new.to_i
    end

    def time_clear(key)
      i = Time.new.to_i
      @tmp_hash[key].each do |t|
        @tmp_hash[key].delete(t) if (i - t > @win_time)
      end
    end

    def value_size(key)
      @tmp_hash[key].size
    end
  end
end
