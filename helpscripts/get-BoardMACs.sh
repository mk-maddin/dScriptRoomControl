#!/bin/bash
# version: 2019.12.29
# description: script to administrate and configure dScriptBoards with dScriptRoomControl firmware

##-- save maximum error code
error=0; trap 'error=$(($?>$error?$?:$error))' ERR

##--meta-information required paramteres
scriptAuthor="Martin Kraemer, mk.maddin@gmail.com"
scriptName=$( basename "$0" )
#scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

##--define internal fixed variables
verbose='true'
IPNet='192.168.28'

for ip in {1..254};do
	[ -n "${verbose}" ] && echo "D: testing: ${IPNet}.${ip}"
	curl -s http://${IPNet}.${ip}/debugapi.htm | egrep "System_MACString|System_HostName" | grep "value=" | sed 's#\(^.*value="\)\([^"]*\)\(".*$\)#\2#g'
done

exit "$error"
