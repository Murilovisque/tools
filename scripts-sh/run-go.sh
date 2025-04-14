#!/bin/bash

which inotifywait > /dev/null
if [[ $? != 0 ]]; then
	echo "run 'sudo apt install -y inotify-tools'"
	exit 1
fi

DIRETORIO_PROJETO=$(pwd)
if [[ ! -d ${DIRETORIO_PROJETO} ]]; then
	echo "Pasta inválida"
	exit 1
fi

ARQUIVO_MAIN=$(find ${DIRETORIO_PROJETO} -type f -name main.go | head -n 1)
if [[ ! -f ${ARQUIVO_MAIN} ]]; then
	echo "Arquivo go inválido"
	exit 1
fi

go run -race ${ARQUIVO_MAIN} $* &
PID_GO=$!
echo "PID GO ${PID_GO}"
echo $(jobs)
sleep 2

inotifywait -e 'modify,move,create,delete' -m -r ${DIRETORIO_PROJETO} | while read evento; do
	echo "Evento '${evento}' será atualizado"
	kill -SIGINT ${PID_GO}
	PID_GO=$(ps au | grep -E '/tmp/go-build.+main' | grep -v 'grep ' | head -n 1 | awk '{print $2}')
	if [[ ! -z "${PID_GO}" ]]; then
		kill ${PID_GO}
	fi
	sleep 2
	go run -race ${ARQUIVO_MAIN} $* &
	PID_GO=$!
	echo "PID GO ${PID_GO}"
	sleep 2
done
