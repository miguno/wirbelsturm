#!/bin/bash
#
# File:         provision-node.sh
# Description:  This script provisions a single guest, with logging.

MY_DIR=`echo $(cd $(dirname $0); pwd)`
. $MY_DIR/common.sh
EFFECTIVE_LOG_DIR=$MY_DIR/../$LOG_DIR

if [ $# -ne 1 ]; then
  echo "ERROR: You must specify the name of the node to be provisioned."
  echo "Usage: `basename $0` <node-name>"
  exit 1
fi

NODE="$1"

LOG_FILE=$EFFECTIVE_LOG_DIR/${NODE}.log
echo -n "[$NODE] Provisioning. Log: $LOG_FILE, Result: "
vagrant provision $NODE 2>&1 > $LOG_FILE
RETVAL=$?

if [ $RETVAL -ne 0 ]; then
  echo " FAILURE"
  echo "[$NODE] Last 12 entries in log file:"
  tail -12 $LOG_FILE | sed -e "s/^/[$NODE]  /g"
  echo "[$NODE] ---------------------------------------------------------------------------"
  echo "FAILURE $NODE ec=$RETVAL" >> $LOG_FILE
else
  echo " SUCCESS"
  echo "[$NODE] Last 5 entries in log file:"
  tail -5 $LOG_FILE | sed -e "s/^/[$NODE]  /g"
  echo "[$NODE] ---------------------------------------------------------------------------"
  echo "SUCCESS $NODE" >> $LOG_FILE
fi

exit $RETVAL
