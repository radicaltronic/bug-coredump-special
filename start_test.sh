#!/bin/bash

#------------------------------------------------------------------------------------
# @author       Guillaume Plante <radicaltronic@gmail.com>
# @description  This script is run when the daemon service is registered 
# @notes        Daemon: com/robotiq/urcap/trajectories/daemon/active_drive_service.sh
# @copyright    2018 GNU GENERAL PUBLIC LICENSE v3
#------------------------------------------------------------------------------------

#-------------------------------
# includes: common definitions
source daemon_common.sh

DAEMON="bug-coredump-special"
info ">>>>> running $SCRIPT_NAME"

#-------------------------------
# Enable core dump in case of the daemon crash
# For more information, see https://linux-audit.com/understand-and-configure-core-dumps-work-on-linux/
# No limits for the crash dump size for the daemon process.
ulimit -S -c unlimited $DAEMON
ulimit -S -c unlimited activedrivegui

# run the daemon and capture its pid
${DAEMON_DIR}/${DAEMON} &
PROCESS_ID=$!

info "bug-coredump-special PID is: $PROCESS_ID"
info "waiting on process to start..."

COUNTER=0
while [  $COUNTER -lt $WAIT_TIME ]; do
   sleep 1
   let COUNTER=COUNTER+1 
   if [[ ( ! -d /proc/$PROCESS_ID ) || (`grep zombie /proc/$PROCESS_ID/status` ) ]]; then
      info "$DAEMON: waiting ($COUNTER seconds)..."
   else
   	  info "$DAEMON is started"
      break
   fi
done

while true; do

    sleep 1

    if [[ ( ! -d /proc/$PROCESS_ID ) || (`grep zombie /proc/$PROCESS_ID/status` ) ]]; then
      info "$DAEMON stopped! Restarting..."
      # restart the daemon and capture its pid
      ${DAEMON_DIR}/${DAEMON} &
      PROCESS_ID=$!
      #break
    fi

done

info "killing process: $DAEMON"

_term

info "wait the daemon to terminate..."
wait $PROCESS_ID #wait the daemon to terminate.

info "bug-coredump-special processes stopped"
