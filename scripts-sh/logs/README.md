# Bash logs utils

A small lib with some functions to facilitate the logging process. Bellow an example


```bash
#!/bin/bash


# import log lib
. ${HOME}/projects/repos/github/tools/scripts-sh/logs/logs.sh

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

sleep 10 # make um Ctrl+C to test trap function
cleanup

```