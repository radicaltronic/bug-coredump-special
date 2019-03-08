#!/bin/bash

#------------------------------------------------------------------------------------
# @author       Control Team <control@robotiq.com>
# @description  Common functions and variables definitions for daemon sctips.
# @copyright    2018 Robotiq.inc
#------------------------------------------------------------------------------------

#-------------------------------
# includes: logging utility 
source logging.sh

#-------------------------------
# Log level used for all scripts
# [DEBUG][INFO][NOTICE][WARNING][ERROR][CRITICAL][ALERT][EMERGENCY]
LOG_LEVEL=${LOG_LEVELS[DEBUG]}

#-------------------------------
# common variables
SCRIPT_DIR=$(cd "$(dirname ${BASH_SOURCE[0]})" && pwd)
DAEMON_DIR="${SCRIPT_DIR}"
SCRIPT_NAME=${0##*/}

export LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH
export DISPLAY=:0

PROCESS_ID=0
WAIT_TIME=15 # seconds to wait for process

#-------------------------------
# Crash dump directory and filename 
# core.%e.%p.%s.%i.%t : executable.pid.signal number.ThreadID.UNIX time of dump

CRASHDUMP_FOLDER=cores
mkdir -p ${CRASHDUMP_FOLDER}
sysctl -w kernel.core_pattern=${CRASHDUMP_FOLDER}/core.%e.%p.%s.%i.%t >nul


#-------------------------------
# kill the daemon
_term() {
  info "_term() called: killing process $PROCESS_ID"
  kill -TERM $PROCESS_ID

  sleep 1s

  kill -0 $PROCESS_ID
  if [ "$?" -eq "0" ]; then
    warn "pid $PROCESS_ID still running"
    warn "will hard kill $PROCESS_ID"

    kill -9 $PROCESS_ID
  fi
}

#-------------------------------
# signal traps
_sigint() {
  info "_sigint(): trapped SIGINT signal"
  _term
}

_sigterm() {
  info "_sigterm(): trapped SIGTERM signal"
  _term
}

# trap sigint and sigterm signals independently
trap _sigint SIGINT
trap _sigterm SIGTERM