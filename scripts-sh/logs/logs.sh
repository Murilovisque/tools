#!/bin/bash

### private functions

function _get_log_by_day() {
    local dt_log=$(date '+%Y%m%d')
    echo "${LOG_PATH}-${dt_log}.log"
}

function _get_log_by_hour() {
    local dt_log=$(date '+%Y%m%d-%H')
    echo "${LOG_PATH}-${dt_log}.log"
}

function _get_log_stdout() {
    echo '/dev/stdout'
}

function _write_log() {
    local level=$1
    local msg=$2
    local trace_id=$3
    local dt=$(date '+%Y/%m/%d %H:%M:%S')
    local log_target=$(${_func_get_log_path})
    if [[ -z "${trace_id}" ]]; then
        printf "%s %s %s\n" "${dt}" "${level}" "${msg}" >> ${log_target}
    else
        printf "%s %s %s traceid=%s\n" "${dt}" "${level}" "${msg}" "${trace_id}" >> ${log_target}
    fi
}

### public functions

function generate_trace_id() {
    shuf -n 8 -r -e $(echo {a..z} {A..Z} {0..9} | tr ' ' '\n') | tr -d '\n'
}

function log_info() {
    local msg=$1
    local trace_id=$2
    _write_log 'INFO' "${msg}" "${trace_id}"
}

function log_error() {
    local msg=$1
    local trace_id=$2
    _write_log 'ERROR' "${msg}" "${trace_id}"
}

function is_ok_code_logs()  {
    local code=$1
    local msg=$2
    local trace_id=$3
    if [[ ${code} -eq 0 ]]; then
        log_info "${msg}" "${trace_id}"
    fi
    return ${code}
}

function is_fail_code_logs()  {
    local code=$1
    local msg=$2
    local trace_id=$3
    if [[ ${code} -ne 0 ]]; then
        log_error "${msg}" "${trace_id}"
        return 0
    fi
    return 1
}

function is_ok_else_fail_logs_both() {
    local code=$1
    local msg_ok=$2
    local msg_fail=$3
    local trace_id=$4
    if [[ ${code} -eq 0 ]]; then
        log_info "${msg_ok}" "${trace_id}"
    else
        log_error "${msg_fail}" "${trace_id}"
    fi
    return ${code}
}

function start_log_rotation() {
    local days_retation=$1
    if [[ ! "${days_retation}" =~ ^[0-9]+$ ]] || [[ "${days_retation}" -le 0 ]]; then
        echo "invalid retation days parameter: ${days_retation}"
        return 1
    fi
    if [[ ! -d "${LOGS_LIB_LOG_FOLDER}" ]] || [[ -z "${LOGS_LIB_LOG_NAME}" ]]; then
        echo 'invalid LOGS_LIB_LOG_FOLDER and LOGS_LIB_LOG_NAME variables'
        return 1
    fi
    while true; do
        find ${LOGS_LIB_LOG_FOLDER} -type f -mtime +${days_retation} -delete
        sleep 60
    done
    return 0
}

## call 'setup' before use the another public functions

function setup_logger() {
    if [[ -d "${LOGS_LIB_LOG_FOLDER}" ]] && [[ -n "${LOGS_LIB_LOG_NAME}" ]]; then
        LOG_PATH="${LOGS_LIB_LOG_FOLDER}/${LOGS_LIB_LOG_NAME}"
        echo 'test log permission' > ${LOG_PATH}
        if [[ $? -ne 0 ]]; then
            echo "writing log failed: ${LOG_PATH}"
            return 1
        else
            rm -f ${LOG_PATH}
        fi
        if [[ "${LOGS_ROTATION}" == "hour" ]]; then
            echo 'logger setup to file by hour'
            _func_get_log_path='_get_log_by_hour'
        else
            echo 'logger setup to file by day'
            _func_get_log_path='_get_log_by_day'
        fi
    else
        echo 'logger setup to stdout'
        _func_get_log_path='_get_log_stdout'
    fi
    return 0
}

