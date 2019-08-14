# !/bin/bash
if [ "$1" == "" ]; then
    echo "Please provide VM_TYPE(cvm|pcvm) as argument. Ex. fluent-bit cvm OR fluent-bit pcvm"
    exit 1
fi

USER="nutanix"
DIR="/home/nutanix/fluentbit"
BINARY="/home/nutanix/ncc/bin/nusights/fluent-bit"

FLUENTD_HOST="abfb4518bbb0011e984e802c19fbe058-2098409646.us-west-2.elb.amazonaws.com"
FLUENTD_PORT="24224"
DB_FILE="/home/nutanix/tmp/xi_logging.db"
TIMEZONE_OFFSET="-0800"
VM_TYPE=$1
XIC_CELL=`zeus_config_printer | grep "cell_fqdn_list" | awk {'print $2'} |  sed 's/"//g' | cut -d. -f1`
XIC_DC=`zeus_config_printer | grep "cell_fqdn_list" | awk {'print $2'} |  sed 's/"//g' | cut -d. -f2`
XIC_AZ=`zeus_config_printer | grep "cell_fqdn_list" | awk {'print $2'} |  sed 's/"//g' | cut -d. -f3`
XIC_NAME=`zeus_config_printer | grep "cluster_name" | awk {'print $2'} |  sed 's/"//g'`
XIC_ID=`zeus_config_printer | grep "cluster_uuid" | awk {'print $2'} |  sed 's/"//g' | uniq`

# Create a secondary fluent-bit instance directory if not exist 
if [[ ! -e $DIR ]]; then
    mkdir $DIR
elif [[ -d $DIR ]]; then
    echo "$DIR already exists already." 1>&2
    exit 1
fi

# Copy fluentbit to the secondary fluent-bit instance directory
`/bin/cp -r $BINARY $DIR/`
if [ "$?" -ne "0" ]; then
  echo "Sorry, couldn't perform copy operation on this vm" 1>&2
  exit 1
fi

# Touch fluentbit config file
`/usr/bin/touch $DIR/fluentbit.conf`
if [ "$?" -ne "0" ]; then
  echo "Sorry, couldn't perform touch operation on this vm" 1>&2
  exit 1
fi

cat <<EOF >> $DIR/fluentbit.conf
[SERVICE]
    HTTP_Server     On
    HTTP_Listen     0.0.0.0
    HTTP_PORT       2046
    Flush           5
    Daemon          on
    Log_Level       info
    Parsers_File    /home/nutanix/fluentbit/parsers.conf

[INPUT]
    Name     syslog
    Tag      xi.system
    Parser   syslog-rfc3164
    Listen   0.0.0.0
    Port     5140
    Mode     tcp

[FILTER]
    Name record_modifier
    Match xi.system*
    RECORD component system

[INPUT]
    Name tail
    Tag  xi.acropolis
    # Monitor the symlink files instead of the original files otherwise mem
    # usage and cpu usage for fluent-bit bloats up.
    Path /home/nutanix/data/logs/acropolis.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.acropolis_fatal
    Path /home/nutanix/data/logs/acropolis.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.acropolis*
    RECORD component acropolis

[INPUT]
    Name tail
    Tag  xi.arithmos
    Path /home/nutanix/data/logs/arithmos.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_out_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.arithmos_fatal
    Path /home/nutanix/data/logs/arithmos.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.arithmos*
    RECORD component arithmos

[INPUT]
    Name tail
    Tag  xi.curator
    Path /home/nutanix/data/logs/curator.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_out_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.curator_fatal
    Path /home/nutanix/data/logs/curator.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.curator_fatal
    Path /home/nutanix/data/logs/curator_cli.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.curator*
    RECORD component curator

[INPUT]
    Name tail
    Tag  xi.uhura
    Path /home/nutanix/data/logs/uhura.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.uhura_fatal
    Path /home/nutanix/data/logs/uhura.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.uhura*
    RECORD component uhura

[INPUT]
    Name tail
    Tag  xi.ergon
    Path /home/nutanix/data/logs/ergon.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.ergon_fatal
    Path /home/nutanix/data/logs/ergon.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.ergon*
    RECORD component ergon

[INPUT]
    Name tail
    Tag  xi.aplos
    Path /home/nutanix/data/logs/aplos.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.aplos_fatal
    Path /home/nutanix/data/logs/aplos.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.aplos_engine
    Path /home/nutanix/data/logs/aplos_engine.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.aplos_engine_fatal
    Path /home/nutanix/data/logs/aplos_engine.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.aplos*
    RECORD component aplos

[INPUT]
    Name tail
    Tag  xi.genesis
    Path /home/nutanix/data/logs/genesis.log
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.genesis
    RECORD component genesis

[INPUT]
    Name tail
    Tag  xi.health_server
    Path /home/nutanix/data/logs/health_server.log
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    # Buffer only 0.1M of logs to detect a multiline message correctly.
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.health_server
    RECORD component health_server

[INPUT]
    Name tail
    Tag  xi.insights_fatal
    Path /home/nutanix/data/logs/insights_server.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.insights
    Path /home/nutanix/data/logs/insights_server.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_out_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.insights
    Path /home/nutanix/data/logs/insights_receiver.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_out_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.insights_fatal
    Path /home/nutanix/data/logs/insights_receiver.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.insights
    Path /home/nutanix/data/logs/insights_uploader.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_out_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.insights_fatal
    Path /home/nutanix/data/logs/insights_uploader.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.insights_fatal
    Path /home/nutanix/data/logs/insights_monitor.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    # Send 0.1M of logs to CFS at any point. This field limits the amount of
    # data sent to CFS in one chunk. It also determines the memory usage for
    # fluent-bit process. This field should be tweaked accordingly if a lot
    # of components are added.
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.insights*
    RECORD component insights

[INPUT]
    Name tail
    Tag  xi.scavenger
    Path /home/nutanix/data/logs/scavenger.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.scavenger_fatal
    Path /home/nutanix/data/logs/scavenger.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.scavenger*
    RECORD component scavenger

[INPUT]
    Name tail
    Tag  xi.zookeeper_fatal
    Path /home/nutanix/data/logs/zookeeper_monitor.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.zookeeper
    Path /home/nutanix/data/logs/zookeeper.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline c_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.zookeeper*
    RECORD component zookeeper

[INPUT]
    Name tail
    Tag  xi.pithos
    Path /home/nutanix/data/logs/pithos.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_out_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.pithos_fatal
    Path /home/nutanix/data/logs/pithos.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.pithos
    RECORD component pithos

[INPUT]
    Name tail
    Tag  xi.stargate
    Path /home/nutanix/data/logs/stargate.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_out_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.stargate_fatal
    Path /home/nutanix/data/logs/stargate.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.stargate*
    RECORD component stargate

[INPUT]
    Name tail
    Tag  xi.cassandra
    Path /home/nutanix/data/logs/cassandra.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_out_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.cassandra_fatal
    Path /home/nutanix/data/logs/cassandra_monitor.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.cassandra_fatal
    Path /home/nutanix/data/logs/dynamic_ring_changer.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.cassandra*
    RECORD component cassandra

[INPUT]
    Name tail
    Tag  xi.cerebro_fatal
    Path /home/nutanix/data/logs/cerebro.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.cerebro
    Path /home/nutanix/data/logs/cerebro.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_out_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.cerebro_fatal
    Path /home/nutanix/data/logs/cerebro_cli.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.cerebro*
    RECORD component cerebro

[INPUT]
    Name tail
    Tag  xi.prism
    Path /home/nutanix/data/logs/prism.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[INPUT]
    Name tail
    Tag  xi.prism_fatal
    Path /home/nutanix/data/logs/prism_monitor.FATAL
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline cpp_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.prism*
    RECORD component prism

[INPUT]
    Name tail
    Tag  xi.prism_gateway
    Path /home/nutanix/data/logs/prism_gateway.log
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline prism_gateway_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.prism_gateway
    RECORD component prism_gateway

# Log files for which all logs are streamed.
[INPUT]
    Name tail
    Tag  xi.foundation
    Path /home/nutanix/data/logs/foundation/20*/debug.log
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline foundation_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.foundation*
    RECORD component foundation

[INPUT]
    Name tail
    Tag  xi.hades
    Path /home/nutanix/data/logs/hades.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.hades
    RECORD component hades

[INPUT]
    Name tail
    Tag  xi.genesis_out
    Path /home/nutanix/data/logs/genesis.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.genesis_out
    RECORD component genesis_out

[INPUT]
    Name tail
    Tag  xi.upgrade_finish
    Path /home/nutanix/data/logs/finish.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.upgrade_finish
    RECORD component upgrade_finish

[INPUT]
    Name tail
    Tag  xi.upgrade_install
    Path /home/nutanix/data/logs/install.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.upgrade_install
    RECORD component upgrade_install

[INPUT]
    Name tail
    Tag  xi.preupgrade
    Path /home/nutanix/data/logs/preupgrade.out
    Path_Key source_filename
    Exclude_Path *.gz
    Multiline On
    Multiline_Flush 5
    Parser_Firstline python_regex
    Buffer_Chunk_Size 4K
    Buffer_Max_Size 16K
    Skip_Long_Lines On
    Key message
    db  ${DB_FILE}
    Mem_Buf_Limit 32K
    Refresh_Interval 30

[FILTER]
    Name record_modifier
    Match xi.preupgrade
    RECORD component preupgrade

[FILTER]
    Name record_modifier
    Match xi.*
    Record xih_n ${HOSTNAME}
    Record xih_s ${VM_TYPE}
    Record xic_cell ${XIC_CELL}
    Record xic_dc ${XIC_DC}
    Record xic_az ${XIC_AZ}
    Record xic_name ${XIC_NAME}
    Record xic_id ${XIC_ID}

[OUTPUT]
    Name          forward
    Match         *
    Host          ${FLUENTD_HOST}
    Port          ${FLUENTD_PORT}
EOF

# Touch parsers config file
`/usr/bin/touch $DIR/parsers.conf`
if [ "$?" -ne "0" ]; then
  echo "Sorry, couldn't perform touch operation on this vm" 1>&2
  exit 1
fi

cat <<EOF >> $DIR/parsers.conf
[PARSER]
    Name   hermes_regex
    Format regex
    Regex  ^(?<time>[^(,)]*),[\d]+ (?<logType>[^ ]*) *(?<fileName>[^ ]+) *(?<message>.*)
    Time_Key time
    Time_Format %Y-%m-%d %H:%M:%S
    Time_Offset ${TIMEZONE_OFFSET}
    Time_Keep On

[PARSER]
    Name   python_regex
    Format regex
    Regex  ^(?<time>[^(INFO|CRITICAL|WARNING|ERROR|DEBUG)]+){1} (?=(CRITICAL|WARNING|ERROR|DEBUG|INFO)+)(?<logType>[^ ]*) *(?<fileName>[^:]+):(?<lineNumber>[^ ]+) *(?<message>.*)
    Time_Key time
    Time_Format %Y-%m-%d %H:%M:%S
    Time_Offset ${TIMEZONE_OFFSET}
    Time_Keep On

[PARSER]
    Name   cpp_regex
    Format regex
    Regex  ^(?=(I|W|E|F)+)(?<logType>[^\d]+)(?<time>[^\.]+)[^\s]*\s*(?<threadId>[^ ]+) (?<fileName>[^\:]+):(?<lineNumber>[^\]]+)] *(?<message>.*)
    Time_Key time
    Time_Format %m%d %H:%M:%S
    Time_Format %Y-%m-%d %H:%M:%S
    Time_Keep On
    Time_Offset ${TIMEZONE_OFFSET}

[PARSER]
    Name   cpp_out_regex
    Format regex
    Regex ((^(?=(I|W|E|F)+)(?<logType>[^\d]+)(?<time>[^\.]+)[^\s]*\s*(?<threadId>[^ ]+) (?<fileName>[^\:]+):(?<lineNumber>[^\]]+)] *(?<message>.*))|(^(?<time1>[^(,)]*),[\d]+[^_]+_(?<logType1>[^@]+)*(?<message1>.*))|(^(?<time3>[^(,)]*),[\d]+ (?<message3>.*)))
    Time_Key time
    Time_Format %m%d %H:%M:%S
    Time_Format %Y-%m-%d %H:%M:%S
    Time_Keep On
    Time_Offset ${TIMEZONE_OFFSET}

[PARSER]
    Name c_regex
    Format regex
    Regex ^(?<time>[^(,)]*),[\d]+ [-]+ (?<logType>[^ ]*) *(?<message>.*)
    Time_Key time
    Time_Format %Y-%m-%d %H:%M:%S
    Time_Offset ${TIMEZONE_OFFSET}
    Time_Keep On

[PARSER]
    Name prism_gateway_regex
    Format regex
    Regex ^(?<logType>[^\d]+)(?<time>[^\,]+)[,](?<threadId>[^ ]+) (?<fileName>[^\:]+):(?<lineNumber>[^ ]+) *(?<message>.*)
    Time_Offset ${TIMEZONE_OFFSET}
    Time_Key time
    Time_Format %Y-%m-%d %H:%M:%S
    Time_Keep On

[PARSER]
    Name         docker
    Format       json
    Time_Key     time
    Time_Offset ${TIMEZONE_OFFSET}
    Time_Format  %Y-%m-%dT%H:%M:%S.%L
    Time_Keep    On
    Decode_Field json log

[PARSER]
    Name        docker-daemon
    Format      regex
    Regex       time="(?<time>[^ ]*)" level=(?<level>[^ ]*) msg="(?<msg>[^ ].*)"
    Time_Key    time
    Time_Offset ${TIMEZONE_OFFSET}
    Time_Format %Y-%m-%dT%H:%M:%S.%L
    Time_Keep   On

[PARSER]
    Name        syslog-rfc3164
    Format      regex
    Regex       /^\<(?<pri>[0-9]+)\>(?<time>[^ ]* {1,2}[^ ]* [^ ]*) (?<host>[^ ]*) (?<ident>[a-zA-Z0-9_\/\.\-]*)(?:\[(?<pid>[0-9]+)\])?(?:[^\:]*\:)? *(?<message>.*)$/
    Time_Key    time
    Time_Format %b %d %H:%M:%S
    Time_Format %Y-%m-%dT%H:%M:%S.%L
    Time_Keep   On

[PARSER]
    Name        syslog-rfc5424
    Format      regex
    Regex       ^\<(?<pri>[0-9]{1,5})\>1 (?<time>[^ ]+) (?<host>[^ ]+) (?<ident>[^ ]+) (?<pid>[-0-9]+) (?<msgid>[^ ]+) (?<extradata>(\[(.*)\]|-)) (?<message>.+)$
    Time_Key    time
    Time_Offset ${TIMEZONE_OFFSET}
    Time_Format %Y-%m-%dT%H:%M:%S.%L
    Time_Keep   On

[PARSER]
    Name   foundation_regex
    Format regex
    Regex  ^(?<time>[^(INFO|CRITICAL|WARNING|ERROR|DEBUG)]+){1} (?=(CRITICAL|WARNING|ERROR|DEBUG|INFO)+)(?<logType>[^ ]*) *(?<message>.*)
    Time_Key time
    Time_Offset ${TIMEZONE_OFFSET}
    Time_Format %Y%m%d %H:%M:%S
    Time_Keep On
EOF

# Change the directory/file permissions
`/bin/chmod a+x -R $DIR`
if [ "$?" -ne "0" ]; then
  echo "Sorry, couldn't perform chmod operation on this vm" 1>&2
  exit 1
fi

`/bin/chown -R $USER:$USER $DIR`
if [ "$?" -ne "0" ]; then
  echo "Sorry, couldn't perform chown operation on this vm" 1>&2
  exit 1
fi

# Start the secondary fluent-bit instance
`$DIR/fluent-bit -c $DIR/fluentbit.conf &`
if [ "$?" -ne "0" ]; then
  echo "Sorry, couldn't perform start the process on this vm" 1>&2
  exit 1
fi
