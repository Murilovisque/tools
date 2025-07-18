#!/bin/bash

_LOGS_LIB_LOG_PATH=""
_LOGS_LIB_LOG_FOLDER=""
_LOGS_LIB_LOG_NAME=""
_LOGS_LIB_GET_LOG_PATH_FUNC=""

### private functions

function _get_log_by_day() {
    local dt_log=$(date '+%Y%m%d')
    printf "${_LOGS_LIB_LOG_PATH}-${dt_log}.log"
}

function _get_log_by_hour() {
    local dt_log=$(date '+%Y%m%d-%H')
    printf "${_LOGS_LIB_LOG_PATH}-${dt_log}.log"
}

function _get_log_stdout() {
    printf '/dev/stdout'
}

function _write_log() {
    local level="$1"
    local msg="$2"
    local trace_id="$3"
    local dt=$(date '+%Y/%m/%d %H:%M:%S')
    local log_target=$(${_LOGS_LIB_GET_LOG_PATH_FUNC})
    if [[ -z "${trace_id}" ]]; then
        printf "%s %s %s\n" "${dt}" "${level}" "${msg}" >> ${log_target}
    else
        printf "%s %s [traceid: %s] %s\n" "${dt}" "${level}" "${trace_id}" "${msg}" >> ${log_target}
    fi
}

### public functions

function generate_trace_id() {
    shuf -n 8 -r -e {a..z} {A..Z} {0..9} | tr -d '\n'
}

function log_info() {
    local msg="$1"
    local trace_id="$2"
    _write_log 'INFO' "${msg}" "${trace_id}"
    return 0
}

function log_error() {
    local msg="$1"
    local trace_id="$2"
    _write_log 'ERROR' "${msg}" "${trace_id}"
    return 1
}

function log_error_and_exit() {
    local msg="$1"
    local trace_id="$2"
    log_error "${msg}" "${trace_id}"
    exit "$?"
}

function is_code_ok_logs() {
    local code="$1"
    local msg="$2"
    local trace_id="$3"
    if [[ "${code}" -eq 0 ]]; then
        log_info "${msg}" "${trace_id}"
    fi
    return "${code}"
}

function is_code_failed_logs() {
    local code="$1"
    local msg="$2"
    local trace_id="$3"
    if [[ "${code}" -ne 0 ]]; then
        log_error "${msg}" "${trace_id}"
        return 0
    fi
    return 1
}

function is_code_ok_or_failed_logs() {
    local code="$1"
    local msg_ok="$2"
    local msg_fail="$3"
    local trace_id="$4"
    if [[ "${code}" -eq 0 ]]; then
        log_info "${msg_ok}" "${trace_id}"
    else
        log_error "${msg_fail}" "${trace_id}"
    fi
    return "${code}"
}

function if_code_failed_logs_and_exit() {
    local code="$1"
    local msg="$2"
    local trace_id="$3"
    if [[ "${code}" -ne 0 ]]; then
        log_error "${msg}" "${trace_id}"
        exit "${code}"
    fi
    return "${code}"
}

function if_code_ok_logs_else_logs_and_exit() {
    local code="$1"
    local msg_ok="$2"
    local msg_fail="$3"
    local trace_id="$4"
    if [[ "${code}" -eq 0 ]]; then
        log_info "${msg_ok}" "${trace_id}"
        return 0
    else
        log_error "${msg_fail}" "${trace_id}"
        exit "${code}"
    fi    
}

function start_log_rotation() {
    local log_retention_days="$1"
    if [[ ! "${log_retention_days}" =~ ^[0-9]+$ ]] || [[ "${log_retention_days}" -le 0 ]]; then
        printf "invalid retation days parameter: ${log_retention_days}\n"
        return 1
    fi
    if [[ ! -d "${_LOGS_LIB_LOG_FOLDER}" ]] || [[ -z "${_LOGS_LIB_LOG_NAME}" ]]; then
        printf 'invalid args for 'setup_logger' or invalid "LOGS_LIB_LOG_FOLDER" and "LOGS_LIB_LOG_NAME" variables\n'
        return 1
    fi
    while true; do
        find "${_LOGS_LIB_LOG_FOLDER}" -type f -mtime "+${log_retention_days}" -name "${_LOGS_LIB_LOG_NAME}*" -delete
        sleep 60
    done
    return 0
}

## call 'setup' before use the another public functions

function setup_logger() {
    local log_folder="${1:-${LOGS_LIB_LOG_FOLDER:-}}"
    local log_name="${2:-${LOGS_LIB_LOG_NAME:-}}"
    local log_rotation="${3:-${LOGS_ROTATION:-day}}"
    if [[ -d "${log_folder}" ]] && [[ -n "${log_name}" ]]; then
        _LOGS_LIB_LOG_FOLDER="${log_folder}"
        _LOGS_LIB_LOG_NAME="${log_name}"
        _LOGS_LIB_LOG_PATH="${_LOGS_LIB_LOG_FOLDER}/${_LOGS_LIB_LOG_NAME}"
        touch "${_LOGS_LIB_LOG_PATH}.test"
        if [[ "$?" -ne 0 ]]; then
            printf "writing log failed: ${_LOGS_LIB_LOG_PATH}\n"
            return 1
        else
            rm -f "${_LOGS_LIB_LOG_PATH}.test"
        fi        
        if [[ "${log_rotation}" == "hour" ]]; then
            printf 'logger setup to file by hour\n'
            _LOGS_LIB_GET_LOG_PATH_FUNC='_get_log_by_hour'
        else
            printf 'logger setup to file by day\n'
            _LOGS_LIB_GET_LOG_PATH_FUNC='_get_log_by_day'
        fi
    else
        printf 'logger setup to stdout\n'
        _LOGS_LIB_GET_LOG_PATH_FUNC='_get_log_stdout'
    fi
    return 0
}

