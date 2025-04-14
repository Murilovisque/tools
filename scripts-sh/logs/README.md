# Bash logs utils

A small lib with some functions to facilitate the logging process. Bellow an example


```bash
#!/bin/bash


# import log lib
. /home/vareta/projects/repos/github/tools/scripts-sh/logs/logs.sh

# variables
background_jobs=()

# cleanup resources
cleanup() {
    if [[ ${#background_jobs[@]} -gt 0 ]]; then
        echo "Cleaning up before termination..."
        for pid in "${background_jobs[@]}"; do
            if kill -0 "${pid}" 2> /dev/null; then
                kill "${pid}"
                wait "${pid}"
            fi        
        done
        background_jobs=()
        echo "done"
    fi
}
trap cleanup SIGINT SIGTERM EXIT

# setup logger
export LOGS_DIR=/tmp/testes/logs
export LOG_NAME='testador'
mkdir -p ${LOGS_DIR}
setup_logs
start_log_rotation 30 &
background_jobs+=("$!")

# using log lib
log_info 'testando logs'
log_error 'errou'
trace_id=$(generate_trace_id)
log_info 'trace' "${trace_id}"


## log and echo
ls /tmp &> /dev/null
if is_ok_code_logs $? "Success with status $? - test case 1"; then
    echo 'confirm ok, must show - test case 1'
fi

ls /cf034fvfgj234uLjDjcFdf &> /dev/null
if is_fail_code_logs $? "Failed with status $? - test case 1"; then
    echo 'confirm failed, must show - test case 1'
fi

## not log and not echo
ls /cf034fvfgj234uLjDjcFdf &> /dev/null
if is_ok_code_logs $? "Not log success $? - test case 2"; then
    echo 'should fail, not show - test case 2'
fi

ls /tmp &> /dev/null
if is_fail_code_logs $? "Not log fail $? - test case 2"; then
    echo 'should works, not show - test case 2'
fi

## test both
ls /tmp &> /dev/null
if is_ok_else_fail_logs_both $? "Success with $? - test case 3" "Not log fail $? - test case 3"; then
    echo 'should works, must show - test case 3'
else
    echo 'should not failed, not show - test case 3'
fi

ls /cf034fvfgj234uLjDjcFdf &> /dev/null
if is_ok_else_fail_logs_both $? "Success with $? - test case 4" "Not log fail $? - test case 4"; then
    echo 'should not works, not show - test case 4'
else
    echo 'should failed, must show - test case 4'
fi

sleep 10 # make um Ctrl+C to test trap function

```