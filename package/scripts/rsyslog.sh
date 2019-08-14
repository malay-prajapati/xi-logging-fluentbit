# !/bin/bash
DIR="/etc/rsyslog.d"

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
