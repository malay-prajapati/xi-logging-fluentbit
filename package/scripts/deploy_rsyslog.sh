# !/bin/bash
DIR="/etc/rsyslog.d"
RSYSLOG_PID_DIR="/home/nutanix/RSYSLOG"
PID_FILE="/home/nutanix/RSYSLOG/deploy_rsyslog.sh.pid"

#Handle previously running processes for the curent script
if [[ -e $PID_FILE]]; then
    for pid in $(pidof -x deploy_rsyslog.sh); do
        if [ $pid != $$ ]; then
            echo "killing the already running process with PID $pid"
            `kill $pid`
            if [ "$?" -ne "0" ]; then
                echo "Process is not getting terminated" 1>&2
                exit 1
            fi
    # clean up the contents of the previously existing dir
    `rm -rf $RSYSLOG_PID_DIR`

if [[ ! -e $RSYSLOG_PID_DIR ]]; then
    mkdir $RSYSLOG_PID_DIR
elif [[ -d $RSYSLOG_PID_DIR ]]; then
    echo "$RSYSLOG_PID_DIR already exists already." 1>&2
    exit 1
fi

# Delete pidfile during system exits
trap "rm -f -- '$PID_FILE'" EXIT

# Save the process id in the pid file
echo $$ > "$PID_FILE"

# Touch rsyslog config file
`/usr/bin/touch $DIR/60-fluent-bit.conf`
if [ "$?" -ne "0" ]; then
  echo "Sorry, couldn't perform touch operation on rsyslog conf" 1>&2
  exit 1
fi

cat <<EOF >> $DIR/60-fluent-bit.conf
action(type="omfwd" Target="127.0.0.1" Port="5140" Protocol="tcp")
EOF

systemctl restart rsyslog.service
