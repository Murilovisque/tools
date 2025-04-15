#!/bin/bash

OUTPUT_FOLDER=/tmp/golang/dist
OUTPUT_EXE=${OUTPUT_FOLDER}/go-app

# functions

function run_go() {
	if [[ -f ${OUTPUT_EXE} ]]; then
		rm -v ${OUTPUT_EXE}
	fi
	go build -race -o ${OUTPUT_EXE} ${MAIN_FILE}
	if [[ $? -ne 0 ]]; then
		echo 'go build failed'
		return 1
	fi
	echo "running '${OUTPUT_EXE} $*'"
	${OUTPUT_EXE} $* &
	PID_GO=$!
	echo "golang app pid ${PID_GO}"
	sleep 2
}

# main

which inotifywait > /dev/null
if [[ $? -ne 0 ]]; then
	echo "run 'sudo apt install -y inotify-tools'"
	exit 1
fi

PROJECT_FOLDER=$(pwd)
if [[ ! -d ${PROJECT_FOLDER} ]]; then
	echo "invalid project folder"
	exit 1
fi

MAIN_FILE=$(find ${PROJECT_FOLDER} -type f -name main.go | head -n 1)
if [[ ! -f ${MAIN_FILE} ]]; then
	echo "main.go not found"
	exit 1
fi

mkdir -p ${OUTPUT_FOLDER}
run_go $*
inotifywait -e 'modify,move,create,delete' -m -r ${PROJECT_FOLDER} | while read evento; do
	if kill -0 "${PID_GO}" 2> /dev/null; then
		echo "event '${evento}', PID ${PID_GO} is going to be stopped and the project is going to be updated"
		kill ${PID_GO}
		wait ${PID_GO}
	fi
	run_go $*
done
