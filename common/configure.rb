module Diao
  class CommonConfigure
    def initialize(config_name, reload_count)
      @config_name = config_name
      @reload_count = reload_count.to_i
      @tmp_count = 0
    end

    def load_config_func
      c = ::Diao::CommonCache.get @config_name
      if c
        @config = JSON.parse c
      else
        @config = Hash.new
      end
    end

    def load_config
      if @config.nil?
        load_config_func
      else
        @tmp_count = @tmp_count + 1
        if @tmp_count >= @reload_count
          @tmp_count = 0
          load_config_func
        end
      end
      @config
    end
  end
end
