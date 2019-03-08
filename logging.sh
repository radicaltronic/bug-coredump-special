#!/bin/bash

#------------------------------------------------------------------------------------
# @author 		Guillaume Plante <radicaltronic@gmail.com>
# @description	Logging Utility used by the different deamon scripts.
# @copyright    2018 GNU GENERAL PUBLIC LICENSE v3
#------------------------------------------------------------------------------------

#-------------------------------
# Log levels
declare -A LOG_LEVELS
LOG_LEVELS=([DEBUG]=7 [INFO]=6 [NOTICE]=5 [WARNING]=4 [ERROR]=3 [CRITICAL]=2 [ALERT]=1 [EMERGENCY]=0)

#--------------------------------------------------------------
# Current (default) filter level
LOG_LEVEL=${LOG_LEVELS[WARNING]}
LOG_DIRECTORY=.
LOG_FILE="$LOG_DIRECTORY/daemons.log"

if [ ! -d "$LOG_DIRECTORY" ]; then
  # Create log directory if $LOG_DIRECTORY doesn't exist.
  mkdir $LOG_DIRECTORY
fi

#--------------------------------------------------------------
# get_level_value <DEBUG | INFO | ...>
#
#   Get the level value from level name
#
get_level_value() {
    local level="${1}" value=""
    [ -z "${LOG_LEVELS[$level]+isset}" ] && return 1
    echo "${LOG_LEVELS[$level]}"
}

#--------------------------------------------------------------
# get_level_name <0..7>
#
#   Get log level name from numeric value.
#
get_level_name() {
    local level="" value="${1}"
    for level in "${!LOG_LEVELS[@]}"; do
       [ "${LOG_LEVELS[$level]}" -eq "${value}" ] && echo "${level}" && return 0
    done
    return 1
}


#--------------------------------------------------------------
# log <level> <msg> [msg...]
#
#   Format log line and write to stderr.
#
log() {
    _logging_log "${@}";
}


#--------------------------------------------------------------
# _logging_fmt <level> <msg> [msg...]
#
#   Print formatted message.  Redefine for custom formatting.
#
#   This implementation formats lines as:
#     YYYY-mm-dd HH:MM:SS+ZZ:ZZ LEVEL (func_name) Message
#
#   Message args are concatenated with $IFS
#
_logging_fmt() {
    # caller is three stackframes back (_logging_fmt, _logging_log, log, <caller>)
    local level="$1" cmd="${FUNCNAME[3]}"
    shift
    printf "%s %s (%s) %s\n" "$(date +%Y-%m-%dT%H:%M:%S%z)" \
            "$level" "$cmd" "$*"
}

#--------------------------------------------------------------
# _logging_out <msg> [msg...]
#
#   Write log line to stderr. Redefine for custom output.
#	NOTE: Not all robots have the proper logger version. 
#   Therefore; for now, we use only output to stdout/stderr
#
_logging_out() {

	# Only to STDERR
    >&2 echo "$@"

    # Log to file
    echo $(date -u) "$@" >> $LOG_FILE
  
    # Log the message to standard error (screen), as well as the system log using the logger tool
    # logger -s "$@"    ### disable for now
}

#--------------------------------------------------------------
# _log <level> <msg> [msg...]
#
#   Validates and filters records according to <level>, reads record from stdin,
#   formats and outputs a log record.
#
_logging_log() {
    local level="$1" lvl="" line=""
    local -a args
    shift
    lvl="$(get_level_value "$level")"
    [ -z "$lvl" ] && return 1
    [ "${lvl}" -gt "$LOG_LEVEL" ] && return 0
    if [ -t 0 ]; then
        _logging_out "$(_logging_fmt "$level" "$@")"
    else
        while read -r line; do
            # TODO: Reset IFS here so that $@ is split correctly?
            args=()
            if [ -n "$*" ]; then
                args+=( "$@" )
            fi
            args+=( "${line}" );
            _logging_out "$(_logging_fmt "$level" "${args[@]}")"
        done
    fi
}

#--------------------------------------------------------------
# helper functions for each level
die()    { _logging_log EMERGENCY "${@}"; exit 1; }
alert()  { _logging_log ALERT "${@}"; }
crit()   { _logging_log CRITICAL "${@}"; }
error()  { _logging_log ERROR "${@}"; }
warn()   { _logging_log WARNING "${@}"; }
notice() { _logging_log NOTICE "${@}"; }
info()   { _logging_log INFO "${@}"; }
debug()  { _logging_log DEBUG "${@}"; }