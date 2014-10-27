require 'red_storm'
require 'diao/diao'

module Diao

    class DiaoTopology < ::RedStorm::DSL::Topology
      spout RedisInputSpout, :parallelism => 64

      bolt ElasticsearchOutputBolt, :parallelism => 32 do
        #debug true
        source RedisInputSpout, :shuffle
      end

      bolt WordAlertBolt, :parallelism => 64 do
        #debug true
        source RedisInputSpout, :shuffle
      end

      bolt SrcIpGroupCheckBolt, :parallelism => 64 do
        #debug true
        source RedisInputSpout, :fields => ["src_ip"]
      end

      bolt RequestUrlGroupAlertBolt, :parallelism => 64 do
        #debug true
        source RedisInputSpout, :fields => ["real_url"]
      end

      bolt CommonOutputBolt, :parallelism => 1 do
        #debug true
        #source RedisInputSpout, :global
        source WordAlertBolt, :shuffle
        source SrcIpGroupCheckBolt, :shuffle
        source RequestUrlGroupAlertBolt, :shuffle
      end

      configure :diao do |env|
        #debug true
        max_task_parallelism 64
        num_workers 32
        max_spout_pending 100
      end

      on_submit do |env|
        if env == :local
          sleep(5555)
          cluster.shutdown
        end
      end
    end

end
