# other variables
default[:metrictank][:packagecloud_repo] = "raintank/raintank"

# variables that literally translate to the config directly

## misc ##

# instance identifier. must be unique. used in clustering messages, for naming queue consumers and emitted metrics.
default[:metrictank][:instance] = "default"

# accounting period to track per-org usage metrics
default[:metrictank][:accounting_period] = "5min"

## clustering ##

# the primary node writes data to cassandra. There should only be 1 primary node per cluster of nodes
default[:metrictank][:primary_node] = false

## data ##

# see https://github.com/raintank/metrictank/blob/master/docs/data-knobs.md for more details
# duration of raw chunks. e.g. 10min, 30min, 1h, 90min...
default[:metrictank][:chunkspan] = "2h"
# number of raw chunks to keep in memory. should be at least 1 more than what's needed to satisfy aggregation rules
default[:metrictank][:numchunks] = 5
# minimum wait before raw metrics are removed from storage
default[:metrictank][:ttl] = "35d"

# max age for a chunk before to be considered stale and to be persisted to Cassandra
default[:metrictank][:chunk_max_stale] = "1h"
# max age for a metric before to be considered stale and to be purged from memory
default[:metrictank][:metric_max_stale] = "6h"
# Interval to run garbage collection job
default[:metrictank][:gc_interval] = "1h"

# duration before secondary nodes start serving requests
# shorter warmup means metrictank will need to query cassandra more if it doesn't have requested data yet.
# in clusters, best to assure the primary has saved all the data that a newly warmup instance will need to query, to prevent gaps in charts
default[:metrictank][:warm_up_period] = "1h"

# settings for rollups (aggregation for archives)
# comma-separated of archive specifications.
# archive specification is of the form: aggSpan:chunkSpan:numChunks:TTL[:ready as bool. default true]
# with these aggregation rules: 5min:1h:2:3mon,1h:6h:2:1y:false
# 5 min of data, store in a chunk that lasts 1hour, keep 2 chunks in memory, keep for 3months in cassandra
# 1hr worth of data, in chunks of 6 hours, 2 chunks in mem, keep for 1 year, but this series is not ready yet for querying.
default[:metrictank][:agg_settings] = ""

## metric data storage in cassandra ##

# see https://github.com/raintank/metrictank/blob/master/docs/cassandra.md for more details
# comma-separated list of hostnames to connect to
default[:metrictank][:cassandra_addrs] = ""
# keyspace to use for storing the metric data table
default[:metrictank][:cassandra_keyspace] = "raintank"
# desired write consistency (any|one|two|three|quorum|all|local_quorum|each_quorum|local_one
default[:metrictank][:cassandra_consistency] = "one"
# how to select which hosts to query
# roundrobin                : iterate all hosts, spreading queries evenly.
# hostpool-simple           : basic pool that tracks which hosts are up and which are not.
# hostpool-epsilon-greedy   : prefer best hosts, but regularly try other hosts to stay on top of all hosts.
# tokenaware,roundrobin              : prefer host that has the needed data, fallback to roundrobin.
# tokenaware,hostpool-simple         : prefer host that has the needed data, fallback to hostpool-simple.
# tokenaware,hostpool-epsilon-greedy : prefer host that has the needed data, fallback to hostpool-epsilon-greedy.
default[:metrictank][:cassandra_host_selection_policy] = "tokenaware,hostpool-epsilon-greedy"
# cassandra timeout in milliseconds
default[:metrictank][:cassandra_timeout] = 1000
# max number of concurrent reads to cassandra
default[:metrictank][:cassandra_read_concurrency] = 20
# max number of concurrent writes to cassandra
default[:metrictank][:cassandra_write_concurrency] = 10
# max number of outstanding reads before blocking. value doesn't matter much
default[:metrictank][:cassandra_read_queue_size] = 100
# write queue size per cassandra worker. should be large engough to hold all at least the total number of series expected, divided by how many workers you have
default[:metrictank][:cassandra_write_queue_size] = 100000
# how many times to retry a query before failing it
default[:metrictank][:cassandra_retries] = 0
# CQL protocol version. cassandra 3.x needs v3 or 4.
default[:metrictank][:cql_protocol_version] = 4

# enable SSL connection to cassandra
default[:metrictank][:cassandra_ssl] = false
# cassandra CA certficate path when using SSL
default[:metrictank][:cassandra_ca_path] = "/etc/raintank/ca.pem"
# host (hostname and server cert) verification when using SSL
default[:metrictank][:cassandra_host_verification] = true
# enable cassandra user authentication
default[:metrictank][:cassandra_auth] = false
# username for authentication
default[:metrictank][:cassandra_username] = "cassandra"
# password for authentication
default[:metrictank][:cassandra_password] = "cassandra"

## Profiling, instrumentation and logging ##

# see https://golang.org/pkg/runtime/#SetBlockProfileRate
default[:metrictank][:block_profile_rate] = 0
# 0 to disable. 1 for max precision (expensive!) see https://golang.org/pkg/runtime/#pkg-variables")
default[:metrictank][:mem_profile_rate] = 524288 # 512*1024

# enable sending statsd messages for instrumentation
default[:metrictank][:statsd_enabled] = true # TODO was use_statsd ?
# statsd address
default[:metrictank][:statsd_addr] = "localhost:8125"
# standard or datadog
default[:metrictank][:statsd_type] = "standard"

# inspect status frequency. set to 0 to disable
default[:metrictank][:proftrigger_freq] = "60s"
# path to store triggered profiles
default[:metrictank][:proftrigger_path] = "/tmp"
# minimum time between triggered profiles
default[:metrictank][:proftrigger_min_diff] = "1h"
# if process consumes this many bytes (see bytes_sys in dashboard), trigger a heap profile for developer diagnosis
# set it higher than your typical memory usage, but lower than how much RAM the process can take before its get killed
default[:metrictank][:proftrigger_heap_thresh] = 25000000000

# only log log-level and higher. 0=TRACE|1=DEBUG|2=INFO|3=WARN|4=ERROR|5=CRITICAL|6=FATAL
default[:metrictank][:log_level] = 2


## http api ##
[http]
# tcp address for metrictank to bind to for its HTTP interface
default[:metrictank][:http][:listen] = ":6060"
# use HTTPS
default[:metrictank][:http][:ssl] = false
# SSL certificate file
default[:metrictank][:http][:cert_file] = "/etc/ssl/certs/ssl-cert-snakeoil.pem"
# SSL key file
default[:metrictank][:http][:key_file] = "/etc/ssl/private/ssl-cert-snakeoil.key"
# limit on how many points could be requested in one request. 1M allows 500 series at a MaxDataPoints of 2000. (0 disables limit)
default[:metrictank][:http][:max_points_per_req] = 1000000
# limit on what kind of time range can be requested in one request. the default allows 500 series of 2 years. (0 disables limit)
default[:metrictank][:http][:max_days_per_req] = 365000
# only log incoming requests if their timerange is at least this duration. Use 0 to disable
default[:metrictank][:http][:log_min_dur] = "5min"


## metric data inputs ##

### carbon input (optional)
#[carbon-in]
default[:metrictank][:carbon_in][:enabled] = false
# tcp address
default[:metrictank][:carbon_in][:addr] = ":2003"
# needed to know your raw resolution for your metrics. see http://graphite.readthedocs.io/en/latest/config-carbon.html#storage-schemas-conf
# NOTE: does NOT use aggregation and retention settings from this file.  We use agg-settings and ttl for that.
default[:metrictank][:carbon_in][:schemas_file] = "/path/to/your/schemas-file"

### kafka-mdm input (optional, recommended)
#[kafka-mdm-in]
default[:metrictank][:kafka_mdm_in][:enabled] = false
# tcp address (may be given multiple times as a comma-separated list)
default[:metrictank][:kafka_mdm_in][:brokers] = ""
# kafka topic (may be given multiple times as a comma-separated list)
default[:metrictank][:kafka_mdm_in][:topics] = "mdm"
# offset to start consuming from. Can be one of newest, oldest,last or a time duration
# the further back in time you go, the more old data you can load into metrictank, but the longer it takes to catch up to realtime data
default[:metrictank][:kafka_mdm_in][:offset] = "last"
# save interval for offsets
default[:metrictank][:kafka_mdm_in][:offset_commit_interval] = "5s"
# directory to store partition offsets index. supports relative or absolute paths. empty means working dir.
# it will be created (incl parent dirs) if not existing.
default[:metrictank][:kafka_mdm_in][:data_dir] = ""
# The number of metrics to buffer in internal and external channels
defalut[:metrictank][:kafka_mdm_in][:channel_buffer_size] = 1000000
# The minimum number of message bytes to fetch in a request
default[:metrictank][:kafka_mdm_in][:consumer_fetch_min] = 1
# The default number of message bytes to fetch in a request
default[:metrictank][:kafka_mdm_in][:consumer_fetch_default] = 32768
# The maximum amount of time the broker will wait for Consumer.Fetch.Min bytes to become available before it
default[:metrictank][:kafka_mdm_in][:consumer_max_wait_time] = "1s"
#The maximum amount of time the consumer expects a message takes to process
default[:metrictank][:kafka_mdm_in][:consumer_max_processing_time] = "1s"
# How many outstanding requests a connection is allowed to have before sending on it blocks
default[:metrictank][:kafka_mdm_in][:net_max_open_requests] = 100

## clustering transports ##

### kafka as transport for clustering messages (recommended)
#[kafka-cluster]
default[:metrictank][:kafka_cluster][:enabled] = true
# tcp address (may be given multiple times as a comma-separated list)
default[:metrictank][:kafka_cluster][:brokers] = ""
# kafka topic (only one)
default[:metrictank][:kafka_cluster][:topic] = "metricpersist"
# offset to start consuming from. Can be one of newest, oldest,last or a time duration
default[:metrictank][:kafka_cluster][:offset] = "last"
# save interval for offsets
default[:metrictank][:kafka_cluster][:offset_commit_interval] = "5s"
# directory to store partition offsets index. supports relative or absolute paths. empty means working dir.
# it will be created (incl parent dirs) if not existing.
default[:metrictank][:kafka_cluster][:data_dir] = ""


## metric metadata index ##

### in-memory
#[memory-idx]
default[:metrictank][:memory_idx][:enabled] = true

### in memory, elasticsearch-backed
#[elasticsearch-idx]
default[:metrictank][:elasticsearch_idx][:enabled] = false
# elasticsearch index name to use
default[:metrictank][:elasticsearch_idx][:index] = "metric"
# Elasticsearch host addresses (multiple hosts can be specified as comma-separated list)
default[:metrictank][:elasticsearch_idx][:hosts] = "localhost:9200"
# http basic auth
default[:metrictank][:elasticsearch_idx][:user] = ""
default[:metrictank][:elasticsearch_idx][:pass] = ""
# how often the retry buffer should be flushed to ES. Valid units are "s", "m", "h"
default[:metrictank][:elasticsearch_idx][:retry_interval] = "10m"
# max number of concurrent connections to ES
default[:metrictank][:elasticsearch_idx][:max_conns] = 20
# max numver of docs to keep in the BulkIndexer buffer
default[:metrictank][:elasticsearch_idx][:max_buffer_docs] = 1000
# max delay befoer the BulkIndexer flushes its buffer
default[:metrictank][:elasticsearch_idx][:buffer_delay_max] = "10s"

### in memory, cassandra-backed
#[cassandra-idx]
default[:metrictank][:cassandra_idx][:enabled] = false
# Cassandra keyspace to store metricDefinitions in.
default[:metrictank][:cassandra_idx][:keyspace] = "raintank"
# comma separated list of cassandra addresses in host:port form
default[:metrictank][:cassandra_idx][:hosts] = "localhost:9042"
#cql protocol version to use
default[:metrictank][:cassandra_idx][:protocol_version] = 4
# write consistency (any|one|two|three|quorum|all|local_quorum|each_quorum|local_one
default[:metrictank][:cassandra_idx][:consistency] = "one"
# cassandra request timeout
default[:metrictank][:cassandra_idx][:timeout] = "1s"
# number of concurrent connections to cassandra
default[:metrictank][:cassandra_idx][:num_conns] = 10
# Max number of metricDefs allowed to be unwritten to cassandra
default[:metrictank][:cassandra_idx][:write_queue_size] = 100000
#automatically clear series from the index if they have not been seen for this much time.
default[:metrictank][:cassandra_idx][:max_stale] = "0"
#Interval at which the index should be checked for stale series.
default[:metrictank][:cassandra_idx][:prune_interval] = "3h"
#frequency at which we should update the metricDef lastUpdate field.
default[:metrictank][:cassandra_idx][:update_interval] = "4h"
#fuzzyness factor for update-interval. should be in the range 0 > fuzzyness <= 1. With an updateInterval of 4hours and fuzzyness of 0.5, metricDefs will be updated every 4-6hours.
default[:metrictank][:cassandra_idx][:update_fuzzyness] = 0.5
# enable SSL connection to cassandra
default[:metrictank][:cassandra_idx][:ssl] = false
# cassandra CA certficate path when using SSL
default[:metrictank][:cassandra_idx][:ca_path] = "/etc/raintank/ca.pem"
# host (hostname and server cert) verification when using SSL
default[:metrictank][:cassandra_idx][:host_verification] = true
# enable cassandra user authentication
default[:metrictank][:cassandra_idx][:auth] = false
# username for authentication
default[:metrictank][:cassandra_idx][:username] = "cassandra"
# password for authentication
default[:metrictank][:cassandra_idx][:password] = "cassandra"
