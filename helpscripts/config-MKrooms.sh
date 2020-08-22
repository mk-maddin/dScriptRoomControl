#!/bin/bash
# version: 2019.12.13
# description: ugly script which configures rooms for Martin Kraemers home

##-- save maximum error code
error=0; trap 'error=$(($?>$error?$?:$error))' ERR 

##--meta-information required paramteres
scriptAuthor="Martin Kraemer, mk.maddin@gmail.com"
scriptName=$( basename "$0" )
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

##--default values for parameters
verbose="--verbose"

##--define internal fixed variables
dScriptSH='dScriptRoom-admin.sh'
dScriptServer=""
#dScriptServer='192.168.13.12'

##--help text and script parameter processing
for i in "$@";do
case $i in
	-h|--help) #help parameter for command
	echo ""
	echo "$scriptName" 
	echo "by $scriptAuthor" 
	echo ""
	echo "Usage: $scriptName [parameter]=[value]"
	echo ""
	echo "Parameter:"
	echo -e "\t -h \t| --help \t\t-> shows this help information"
	echo -e "\t -v \t| --verbose \t\t-> enable verbose ouput"
	echo ""
	echo -e "\t -b= \t| --board= \t-> define a specific dScriptBoard hostname or IP for connecting to"
	#echo -e "\t -p= \t| --pass= \t-> new/old board password for accessing the board" #unfortunately not woking yet as CURL does not support "local storage" feature of browsers
		#have to rewrite this is python to fix the "issue" with no password support
	echo -e "\t -r= \t| --room= \t-> room to configure on board"
	echo ""
	echo "Description:"
	echo "Configure a board for a specific room of Martin Kraemers home using dScriptRoom-admin.sh wrapper"
	echo ""
	exit 0;;
	-v|--verbose)
	verbose="-v"
	shift;;
	-b=*|--board=*)
	board="${i#*=}"
	shift;;
	-p=*|--pass=*)
	pass="${i#*=}"
	shift;;
	-r=*|--room=*)
	room=$(echo "${i#*=}" | tr [:upper:] [:lower:])
	shift;;
	*)  # unknown option
	>&2 echo "$scriptName: error: invalid option: $i" 
	>&2 echo "Try '$scriptName --help' for more information."
	exit 22;;
esac;done

##--check required executables
[ -n "${verbose}" ] && echo "D: check required executables to exist"
dScriptRoom=$(which "${dScriptSH}" 2>/dev/null)
if [ -z "${dScriptRoom}" ] && [ -x "${scriptDir}/${dScriptSH}" ];then dScriptRoom="${scriptDir}/${dScriptSH}";fi
if [ -z "${dScriptRoom}" ];then
	>&2 echo "$scriptName: error: no such file or directory: ${dScriptSH}"
	>&2 echo "Try '$scriptName --help' for more information."
	exit 2;fi

[ -n "${verbose}" ] && echo "D: find configuration for room: ${room}"
case $room in
	dev)	#DS3484 test device
		lights=1
		lightsmax=3
		shutters=1
		autoio='true'
		shift;;
	test)	#DS2824 test device
		lights=4
		lightsmax=12
		shutters=2
		autoio='false'
		shift;;	
	kitchen)
		lights=4
		lightsmax=8
		shutters=2
		autoio='true'
		shift;;
	entrance)
		lights=4
		lightsmax=12
		shutters=0
		autoio='true'
		shift;;
	living)
		lights=4
		lightsmax=12
		shutters=4
		autoio='true'
		shift;;
	*)  # unknown option
	>&2 echo "$scriptName: error: invalid room: $room" 
	exit 22;;
esac

[ -n "${verbose}" ] && echo "D: perform a general test for working validation"
"${dScriptRoom}" --board="${board}" --mode='test';r="${?}"
if [ "${r}" -ne 0 ];then
	>&2 echo "$0: error: configuration test for board failed: ${board} -> ${r}"
	exit ${r};fi 

echo "I: configure room: ${room}" 
#add --pass="${pass}" if possible
"${dScriptRoom}" ${verbose} --board="${board}" --mode='config' --hostname="dS-${room}" --dscriptserver="${dScriptServer}" \
	--lights="${lights}" --lightrelaymax="${lightsmax}" --shutters="${shutters}" --autoio="${autoio}"

case $room in
	dev)
		"${dScriptRoom}" ${verbose} --board="${board}" --mode='io' --ioid=8 --ioentity="1" #motion sensor on IO8
		shift;;
	test)
		#configure the 8 IOs
		"${dScriptRoom}" ${verbose} --board="${board}" --mode='io' --ioid=1 --iotype='light' --ioentity="1" 
		"${dScriptRoom}" ${verbose} --board="${board}" --mode='io' --ioid=2 --iotype='shutter' --ioentity="1"
		"${dScriptRoom}" ${verbose} --board="${board}" --mode='io' --ioid=3 --iotype='light' --ioentity="2"
		"${dScriptRoom}" ${verbose} --board="${board}" --mode='io' --ioid=4 --iotype='light' --ioentity="3"
		"${dScriptRoom}" ${verbose} --board="${board}" --mode='io' --ioid=5 --iotype='light' --ioentity="4"
		"${dScriptRoom}" ${verbose} --board="${board}" --mode='io' --ioid=6 --iotype='shutter' --ioentity="2"
		"${dScriptRoom}" ${verbose} --board="${board}" --mode='io' --ioid=7 --iotype='motion' --ioentity="3"   #motion sensor on IO7
		"${dScriptRoom}" ${verbose} --board="${board}" --mode='io' --ioid=8 --iotype='motion' --ioentity="1,3" #motion sensor on IO8

		# shutter 2 is a raffstore with higher (15 seconds) closing time than "normal" (10 seconds) shutter
		"${dScriptRoom}" ${verbose} --board="${board}" --mode='shutter' --shutterid=2 --shuttertype="raffstore" --closingtime="15000"
		shift;;
	kitchen)
		shift;;
	entrance)
		shift;;
	living)
		shift;;
	*)  # unknown option
	>&2 echo "$scriptName: error: invalid room: $room"
	exit 22;;
esac

exit "${error}"
