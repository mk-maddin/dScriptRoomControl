#! /bin/bash

ipnet='192.168.28.'

for i in {10..100};do
	ip="${ipnet}${i}"
	if curl --fail "http://${ip}/debugapi.htm" &>/dev/null;then
		/home/onkraemer.de/kraemermar/Documents/Scripts/git/dScriptRoomControl/helpscripts/dScriptRoom-admin.sh -v -m='config' -ds="EMPTY" -b="${ip}"
	fi
done
