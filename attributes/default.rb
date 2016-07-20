default[:use_statsd] = true

# tcp address for metrictank to bind to for its HTTP interface
default[:chef_metric_tank][:listen] = ":6060"

# accounting period to track per-org usage metrics
default[:chef_metric_tank][:accounting_period] = "5min"


default[:chef_metric_tank][:packagecloud_repo] = "raintank/raintank"

# cluster node name and value used to differentiate metrics between nodes
default[:chef_metric_tank][:instance] = "default"
# the primary node writes data to cassandra. There should only be 1 primary node per cluster of nodes
default[:chef_metric_tank][:primary_node] = "false"

# minimum wait before metrics are removed from storage
default[:chef_metric_tank][:ttl] = "35d"
# duration of chunks
default[:chef_metric_tank][:chunkspan] = "2h"
# number of chunks to keep in memory. should be at least 1 more than what's needed to satisfy aggregation rules
default[:chef_metric_tank][:numchunks] = 5

# max age for a chunk before to be considered stale and to be persisted to Cassandra
default[:chef_metric_tank][:chunk_max_stale] = "1h"
# max age for a metric before to be considered stale and to be purged from memory
default[:chef_metric_tank][:metric_max_stale] = "6h"
# Interval to run garbage collection job
default[:chef_metric_tank][:gc_interval] = "1h"

# duration before secondary nodes start serving requests
default[:chef_metric_tank][:warm_up_period] = "1h"

# settings for rollups (aggregation for archives)
# comma-separated of archive specifications.
# archive specification is of the form: aggSpan:chunkSpan:numChunks:TTL[:ready as bool. default true]
# with these aggregation rules: 5min:1h:2:3mon,1h:6h:2:1y:false
# 5 min of data, store in a chunk that lasts 1hour, keep 2 chunks in memory, keep for 3months in cassandra
# 1hr worth of data, in chunks of 6 hours, 2 chunks in mem, keep for 1 year, but this series is not ready yet for querying.
default[:chef_metric_tank][:agg_settings] = ""

default[:chef_metric_tank][:cassandra_consistency] = "one"
default[:chef_metric_tank][:cassandra_write_concurrency] = 10
default[:chef_metric_tank][:cassandra_write_queue_size] = 100000
default[:chef_metric_tank][:cassandra_read_concurrency] = 20
default[:chef_metric_tank][:cassandra_read_queue_size] = 100
default[:chef_metric_tank][:cassandra_timeout] = 1000

default[:chef_metric_tank][:index_name] = "metric"
default[:chef_metric_tank][:elastic_addr] = "localhost:9200"
default[:chef_metric_tank][:elasticsearch_host] = "localhost"


default[:chef_metric_tank][:log_level] = 2
default[:chef_metric_tank][:log_min_dur] = "5min"

default[:chef_metric_tank][:statsd_addr] = "localhost:8125"
default[:chef_metric_tank][:statsd_type] = "standard"


default[:chef_metric_tank][:proftrigger][:heap_thresh] = 10000000
default[:chef_metric_tank][:proftrigger][:freq] = "60s"
default[:chef_metric_tank][:proftrigger][:path] = "/tmp"
default[:chef_metric_tank][:proftrigger][:min_diff] = "1h"
default[:chef_metric_tank][:block_profile_rate] = 0
default[:chef_metric_tank][:mem_profile_rate] = 524288


default[:chef_metric_tank][:nsq_in][:enabled] = false
default[:chef_metric_tank][:carbon_in][:enabled] = false

default[:chef_metric_tank][:kafka][:topics] = "mdm"
default[:chef_metric_tank][:kafka][:kafka_port] = 9092
default[:chef_metric_tank][:kafka][:group] = node["hostname"]

default[:chef_metric_tank][:kafka_mdm_in][:enabled] = true
default[:chef_metric_tank][:kafka_mdam_in][:enabled] = false

default[:chef_metric_tank][:kafka_cluster][:enabled] = true
default[:chef_metric_tank][:kafka_cluster][:topic] = "metricpersist"

default[:chef_metric_tank][:nsq_cluster][:enabled] = false

default[:chef_metric_tank][:kafka_search] = "chef_environment:#{node.chef_environment} AND tags:kafka"
default[:chef_metric_tank][:kafkas] = []
