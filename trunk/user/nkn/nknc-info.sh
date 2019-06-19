#!/bin/sh

func_cpu()
{
	if [ -n "`pidof nknd`" ]; then
		cpu=$(top -n1 | grep nknd | head -1 | awk '{print $(NF-1)}')
		echo $cpu
		exit $(echo $cpu | cut -d . -f 1)
	else
		echo 0
		exit 0
	fi
}

func_memory()
{
	pid_nknd=$(pidof nknd)
	if [ -n "$pid_nknd" ]; then
		VmRSS=$(awk '{print $2}' "/proc/${pid_nknd}/statm")
		echo $(( $VmRSS/256 ))
		exit $(( $VmRSS/256 ))
	else
		echo 0
		exit 0
	fi
}

func_state()
{
	if [ -z "$1" ]; then
		curl -s -d '{"id":0,"method":"getnodestate","params":{}}' -H "Content-Type: application/json" -X POST http://127.0.0.1:30003 | jq -M --tab
	else
		curl -s -d '{"id":0,"method":"getnodestate","params":{}}' -H "Content-Type: application/json" -X POST http://"$1":30003 | jq -M --tab
	fi
}

func_neighbor()
{
	echo -e "RemoteAddress\t\tHeight\t\tRTT\tSyncState"
	if [ -z "$1" ]; then
		curl -s -d '{"id":0,"method":"getneighbor","params":{}}' -H "Content-Type: application/json" -X POST http://127.0.0.1:30003 | jq -r '.result[] | "\(.addr)\t\t\(.height)\t\t\(.roundTripTime)\t\(.syncState)"' | sed 's/tcp:\/\///g;s/:30001//g'

	else
		curl -s -d '{"id":0,"method":"getneighbor","params":{}}' -H "Content-Type: application/json" -X POST http://"$1":30003 | jq -r '.result[] | "\(.addr)\t\t\(.height)\t\t\(.roundTripTime)\t\(.syncState)"' | sed 's/tcp:\/\///g;s/:30001//g'
	fi
}

func_connections()
{
	if [ -n "`pidof nknd`" ]; then
		if [ -z "$1" ]; then
			connections=$(curl -s -d '{"id":0,"method":"getconnectioncount","params":{}}' -H "Content-Type: application/json" -X POST http://127.0.0.1:30003 | sed -e 's/^.*"result"[:" ]*\([0-9.]*\).*$/\1/')
		else
			connections=$(curl -s -d '{"id":0,"method":"getconnectioncount","params":{}}' -H "Content-Type: application/json" -X POST http://"$1":30003 | sed -e 's/^.*"result"[:" ]*\([0-9.]*\).*$/\1/')
		fi
		echo $connections
		exit $connections
	else
		echo 0
		exit 0
	fi
}

func_blockcount()
{
	if [ -z "$1" ]; then
		curl -s -d '{"id":0,"method":"getblockcount","params":{}}' -H "Content-Type: application/json" -X POST http://127.0.0.1:30003 | sed -e 's/^.*"result"[:" ]*\([0-9.]*\).*$/\1/'
	else
		curl -s -d '{"id":0,"method":"getblockcount","params":{}}' -H "Content-Type: application/json" -X POST http://"$1":30003 | sed -e 's/^.*"result"[:" ]*\([0-9.]*\).*$/\1/'
	fi
}

func_balance()
{
	curl -s -d '{"id":0,"method":"getbalancebyaddr","params":{"address": "'$1'"}}' -H "Content-Type: application/json" -X POST http://127.0.0.1:30003 | sed -e 's/^.*"amount"[:" ]*\([0-9.]*\).*$/\1/'
}

func_nonce()
{
	curl -s -d '{"id":0,"method":"getnoncebyaddr","params":{"address": "'$1'"}}' -H "Content-Type: application/json" -X POST http://127.0.0.1:30003 | sed -e 's/^.*"nonce"[:" ]*\([0-9.]*\).*$/\1/'
}

func_nonceInTxPool()
{
	curl -s -d '{"id":0,"method":"getnoncebyaddr","params":{"address": "'$1'"}}' -H "Content-Type: application/json" -X POST http://127.0.0.1:30003 | sed -e 's/^.*"nonceInTxPool"[:" ]*\([0-9.]*\).*$/\1/'
}

case "$1" in
cpu)
	func_cpu
	;;
memory)
	func_memory
	;;
state)
	func_state "$2"
	;;
neighbor)
	func_neighbor "$2"
	;;
connections)
	func_connections "$2"
	;;
blockcount)
	func_blockcount "$2"
	;;
balance)
	func_balance "$2"
	;;
nonce)
	func_nonce "$2"
	;;
nonceInTxPool)
	func_nonceInTxPool "$2"
	;;
*)
	echo "Usage: $0 {cpu|memory|state|neighbor|connections|blockcount|balance|nonce|nonceInTxPool}"
	exit 1
	;;
esac

exit 0
