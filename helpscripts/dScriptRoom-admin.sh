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
cfghtml='_config.htm'
apihtml='debugapi.htm'
vnic_filter="${vnic_filter}|virbr|docker|hassio"
empty='NONE'

##--default values for parameters
mode="test"
dev_data=""
#verbose="--verbose"
pass="${empty}"
hostname="${empty}"
dscriptserver="${empty}"
lights="${empty}"
lightsmax="${empty}"
shutters="${empty}"
autoio="${empty}"
autoio="${empty}"
shutterrelayct="${empty}"
shutterid="${empty}"
shuttertype="${empty}"
shutterct="${empty}"
IOid="${empty}"
IOtype="${empty}"
IOentity="${empty}"
dev_var="${empty}"

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
	echo -e "\t -m= \t| --mode= \t\t-> configures action mode (valid are \"test\", \"config\", \"shutter\", \"IO\", \"reboot\" & \"dev\" - default is \"$mode\")"
	echo -e "\t -b= \t| --board= \t-> define a specific dScriptBoard hostname or IP for connecting to (if not defined we will search for boards with ${cfghtml} page enabled!)"
	#echo -e "\t -p= \t| --pass= \t-> new/old board password for accessing the board" #unfortunately not woking yet as CURL does not support "local storage" feature of browsers
		#have to rewrite this is python to fix the "issue" with no password support
	echo ""
	echo -e "\t############# parameters special for mode \"config\" ########################"
	echo -e "\t -h= \t| --hostname= \t-> define a new hostname for the board"
	echo -e "\t -ds= \t| --dscriptserver= \t-> define the dScriptServer for python control"
	echo -e "\t -l= \t| --lights= \t-> number of lights connected to board (int only)"
	echo -e "\t -lr= \t| --lightrelaymax= \t-> maximum light relay used - lights are counted backwards! (int only)"
	echo -e "\t -s= \t| --shutters= \t-> number of shutters connected to board (int only)"
	echo -e "\t -ai= \t| --autoio= \t-> enable / disable auto IO (true = enable | false = disable)"
	echo ""
	echo -e "\t############# parameters special for mode \"shutter\" ########################"
	echo -e "\t -si= \t| --shutterid= \t-> shutter to modify (required - valid values are 1-16)"
	echo -e "\t -st= \t| --shuttertype= \t-> type of the shutter (valid values are: \"roller\", \"raffstore\", \"jealousy\")"
	echo -e "\t -sc= \t| --closingtime= \t-> closing time in milliseconds the shutter needs to close"
	echo -e "\t -sr= \t| --relayconnect= \t-> defines how shutters are connected to relays (valid values are: \"row\" & \"parallel\")"
	echo ""	
	echo -e "\t############# parameters special for mode \"IO\" ########################"
	echo -e "\t -ii= \t| --ioid= \t-> IO to modify (required - valid values are 1-8)"
	echo -e "\t -it= \t| --iotype= \t-> type of the IO (valid values are: \"light\", \"shutter\", \"socket\", \"motion\", \"button\" , \"direct\")"
	echo -e "\t -ie= \t| --ioentity= \t-> entity (list of csv possible) to affect with the IO port (only entities of the iotype can be used - motion=light)"
	echo ""
	echo -e "\t############# parameters special for mode \"dev\" ########################"
	echo -e "\t ATTENTION: use this mode only when you exactly know what you are doing - there are no checks on dependencies etc"	
	echo -e "\t -v= \t| --variable= \t-> variable name to be set (required)"
	echo -e "\t -d= \t| --data= \t-> variable data (default \"${dev_data}\")"
	echo ""
	echo "Description:"
	echo "Script that searches for and sets up dScriptBoards with dScriptRoomControl firmware."
	echo "The board needs to provide a special webpage which contains all the values and their dscript.cgi identifier: ${apihtml}"
	echo "!!BE CAREFUL USING THIS SCRIPT - IT MANIPULATES VARAIBLES DIRECTLY AND MIGHT CAUSE DAMAGE TO YOUR BOARD!!"
	echo ""
	echo -e "The available modes are as follows:"
	echo -e "\t test \t\t= just checkes if variables can be manipulated (using App_Message & App_Debug variables)"
	echo -e "\t config \t\t= configures general application / system behaviour"
	echo -e "\t shutter \t\t= configures a specific shutter"
	echo -e "\t IO \t\t= configures a specific IO"
	echo -e "\t reboot \t\t= restarts the module - no other action is performed"
	echo -e "\t dev \t\t= freely configures variables (use only when you exactly know what you are doing!)"
	echo ""
	exit 0;;
	-v|--verbose)
	verbose="-v"
	shift;;
	-m=*|--mode=*)
	mode=$(echo "${i#*=}" | tr [:upper:] [:lower:])
	if [[ ! "$mode" =~ ^test$|^config$|^shutter$|^io$|^dev$|^reboot$ ]];then
		>&2 echo "$scriptName: error: invalid option: $i" 
		>&2 echo "Try '$scriptName --help' for more information."
		exit 22;fi
	shift;;
	-b=*|--board=*)
	board="${i#*=}"
	shift;;
	-p=*|--pass=*)
	pass="${i#*=}"
	shift;;
	-h=*|--hostname=*)
	hostname="${i#*=}"
	shift;;
	-ds=*|--dscriptserver=*)
	dscriptserver="${i#*=}"
	shift;;
	-l=*|--lights=*)
	lights="${i#*=}"
	if [[ ! "${lights}" =~ ^[0-9]*$ ]];then
		>&2 echo "$scriptName: error: invalid value: $i"
		>&2 echo "Try '$scriptName --help' for more information."
		exit 22;fi
	shift;;
	-lr=*|--lightrelaymax=*)
	lightsmax="${i#*=}"
	if [[ ! "${lightsmax}" =~ ^[0-9]*$ ]];then
		>&2 echo "$scriptName: error: invalid value: $i"
		>&2 echo "Try '$scriptName --help' for more information."
		exit 22;fi
	shift;;
	-s=*|--shutters=*)
	shutters="${i#*=}"
	if [[ ! "${shutters}" =~ ^[0-9]*$ ]];then
		>&2 echo "$scriptName: error: invalid value: $i"
		>&2 echo "Try '$scriptName --help' for more information."
		exit 22;fi
	shift;;
	-ai=*|--autoio=*)
	autoio=$(echo "${i#*=}" | tr [:upper:] [:lower:])
	if [[ ! "${autoio}" =~ ^true$|^false$ ]];then
		>&2 echo "$scriptName: error: invalid value: $i"
		>&2 echo "Try '$scriptName --help' for more information."
		exit 22;fi
	shift;;
	-si=*|--shutterid=*)
	shutterid="${i#*=}"
	if [ "${shutterid}" -lt 1 ] || [ "${shutterid}" -gt 16 ] ;then
		>&2 echo "$scriptName: error: invalid option: $i"
		>&2 echo "Try '$scriptName --help' for more information."
		exit 22;fi
	shift;;
	-st=*|--shuttertype=*)
	shuttertype=$(echo "${i#*=}" | tr [:upper:] [:lower:])
	if [[ ! "$shuttertype" =~ ^roller$|^raffstore$|^jealousy$ ]];then
		>&2 echo "$scriptName: error: invalid value: $i"
		>&2 echo "Try '$scriptName --help' for more information."
		exit 22;fi
	shift;;
	-sc=*|--closingtime=*)
	shutterct="${i#*=}"
	if [[ ! "${shutterct}" =~ ^[1-9]+[0-9]+[0-9]*00$ ]];then
		>&2 echo "$scriptName: error: invalid value: $i"
		>&2 echo "Try '$scriptName --help' for more information."
		exit 22;fi
	shift;;
	-sr=*|--relayconnect=*)
	shutterrelayct=$(echo "${i#*=}" | tr [:upper:] [:lower:])
	if [[ ! "$shutterrelayct" =~ ^row$|^parallel$ ]];then
		>&2 echo "$scriptName: error: invalid value: $i"
		>&2 echo "Try '$scriptName --help' for more information."
		exit 22;fi
	shift;;
	-ii=*|--ioid=*)
	IOid="${i#*=}"
	if [ "${IOid}" -lt 1 ] || [ "${IOid}" -gt 8 ] ;then
		>&2 echo "$scriptName: error: invalid value: $i"
		>&2 echo "Try '$scriptName --help' for more information."
		exit 22;fi
	shift;;
	-ia=*|--ioauto=*)
	IOauto=$(echo "${i#*=}" | tr [:upper:] [:lower:])
	if [[ ! "$IOauto" =~ ^true$|^false$ ]];then
		>&2 echo "$scriptName: error: invalid value: $i"
		>&2 echo "Try '$scriptName --help' for more information."
		exit 22;fi
	[ "${IOauto}" == "true" ] && echo "warning: enabling IOAuto/AutoIO will reset all entity types"
	shift;;
	-it=*|--iotype=*)
	IOtype=$(echo "${i#*=}" | tr [:upper:] [:lower:])
	if [[ ! "$IOtype" =~ ^light$|^shutter$|^socket$|^motion$|^button$|^direct$ ]];then
		>&2 echo "$scriptName: error: invalid value: $i"
		>&2 echo "Try '$scriptName --help' for more information."
		exit 22;fi
	echo "warning: Configuring the IOtype will disable the IOAuto/AutoIO functionality."
	shift;;
	-ie=*|--ioentity=*)
	IOentity="${i#*=}"
	#if [ -z "${IOentity}" ];then IOentity="${empty}";fi
	shift;;
	-v=*|--variable=*)
	dev_var="${i#*=}"
	shift;;
	-d=*|--data=*)
	dev_data="${i#*=}"
	shift;;
	*)  # unknown option
	>&2 echo "$scriptName: error: invalid option: $i" 
	>&2 echo "Try '$scriptName --help' for more information."
	exit 22;;
esac;done

###################### script functions #####################

function urlencode() {
    # urlencode <string>
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C

    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done

    LC_COLLATE=$old_lc_collate
}

function setvariable (){
	name="$1";value="$2";url="$3";pass="$4";verbose='true'
	if [ -z "${name}" ];then
		>&2 echo "$0: error: missing required parameter: "'$1 | name'
		return 22;fi
	if [ -z "${value}" ];then
		>&2 echo "$0: error: missing required parameter: "'$2 | value'
		return 22;fi
	if [ -z "${DSCRIPTVARDATA}" ] && [ -z "${url}" ];then
		>&2 echo "$0: error: missing required parameter: "'$3 | url'
		return 22;fi

	if [ "${value}" == 'EMPTY' ];then value='';fi
	if [ -z "${DSCRIPTVARDATA}" ];then 
		[ -n "${verbose}" ] && echo "D: connecting to given url: $url"
		DSCRIPTVARDATA=$(curl --silent "${url}" --fail);r="$?"
		#var_id=$(curl --silent "${url}" --fail | egrep "<tr><td>${name}</td><td><input.*dscript.cgi?" | sed 's#\(^.*dscript.cgi?\)\([^=]\+\)\(=.*$\)#\2#g')
		if [ "${r}" -ne 0 ];then
			>&2 echo "$0: error: unable to get variable matching table: ${url}"
			return 22;fi;fi

	[ -n "${verbose}" ] && echo "D: extracting variable id from variable source data: ${name}"	
	var_id=$(echo "${DSCRIPTVARDATA}" | egrep "<tr><td>${name}</td><td><input.*dscript.cgi?" | sed 's#\(^.*dscript.cgi?\)\([^=]\+\)\(=.*$\)#\2#g')
	if [ -z "${var_id}" ];then
		>&2 echo "$0: error: unable to find identifier for variable: ${name}"
		return 22;fi
	
	url_value=$(urlencode "$value")
	api_url="$(dirname $url)/dscript.cgi?${var_id}=${url_value}"
	[ -n "${verbose}" ] && echo "D: calling api url: $api_url"
	#TO-DO: call curl with authentication password
	curl --silent --output /dev/null "${api_url}" --fail --compressed --insecure;r="$?"
	echo "I: set variable ${name}=${value}"	
	return "${?}"
}

###################### script actions #####################

##--check required parameters for running script
if [ -z "$mode" ];then
	>&2 echo "$scriptName: error: missing parameter: -m= | --mode="
	>&2 echo "Try '$scriptName --help' for more information."
	exit 22;fi
if [ -z "${apihtml}" ];then
	>&2 echo "$scriptName: error: missing parameter: -da= | --debugapi="
	>&2 echo "Try '$scriptName --help' for more information."
	exit 22;fi

##--check required executables
[ -n "${verbose}" ] && echo "D: check required executables to exist"
if [ -z "$(which nmap)" ];then
	>&2 echo "$scriptName: error: no such file or directory: nmap" 
	>&2 echo "Try '$scriptName --help' for more information."
	exit 2;fi
if [ -z "$(which curl)" ];then
	>&2 echo "$scriptName: error: no such file or directory: curl" 
	>&2 echo "Try '$scriptName --help' for more information."
	exit 2;fi

if [ -z "${board}" ];then
	##--find boards which have ${cfghtml} page enabled
	echo "I: find boards on subnet which have ${cfghtml} page enabled"
	
	[ -n "${verbose}" ] && echo "D: get ip address per network interface"
	ipnics=$(ip addr show up | grep -w 'inet' | egrep -v " 127.${vnic_filter}" | sed 's#\(^.*inet \)\(.*\)\( brd\)\(.*\)\( [^\s\]\)#\2\5#' | tr ' ' ',' )

	for ipnic in ${ipnics[@]};do
		[ -n "${board}" ] && continue
		unset iprange nic iplist
		iprange="${ipnic%,*}";nic="${ipnic#*,}"
		[ -n "${verbose}" ] && echo "D: scan iprange $iprange for dScriptBoards"
		iplist=$(nmap -n -e $nic --host-timeout 10 --open -oG - -p 80 $iprange | grep -v '#' | cut -d' ' -f2 | sort -n | uniq)

		for ip in $iplist;do
			[ -n "${board}" ] && continue
			url="http://${ip}/$cfghtml"
			[ -n "${verbose}" ] && echo "D: checking configuration url: ${url}"
			if curl --output /dev/null --silent --fail "${url}";then board="${ip}";fi
		done
	done
	
	if [ -z "${board}" ];then
		>&2 echo "$scriptName: error: no such board found with ${cfghtml} enabled" 
		>&2 echo "Try '$scriptName --board=' to define board manually."
		exit 19;fi
fi

url="http://${board}/${apihtml}"
[ -n "${verbose}" ] && echo "D: checking api url: ${url}"
if curl --output /dev/null --silent --fail "${url}"; then
	echo "I: configure board: ${board}"
else
	>&2 echo "$scriptName: error: device is not compatible for configuration: ${board}"
	>&2 echo "Try '$scriptName --help' for more information."
	exit 19;fi

# perform here and export variable for faster setvariable processing
[ -n "${verbose}" ] && echo "D: getting variable matching table" 
export DSCRIPTVARDATA=$(curl --silent "${url}" --fail);r="$?"
if [ "${r}" -ne 0 ] || [ -z "${DSCRIPTVARDATA}" ];then
	>&2 echo "$0: error: unable to get variable matching table: ${url}"
	exit 22;fi

if [ "$mode" == "reboot" ];then
	echo "I: initiate a system reboot"
	setvariable "SystemReset" "1" "$url" "$pass"
	exit "${error}"
fi

if [ "$mode" == "test" ];then
	[ -n "${verbose}" ] && echo "D: set App_Debug variable for testing"
	setvariable "App_Debug" "11" "$url" "$pass"
	[ -n "${verbose}" ] && echo "D: set App_Message variable for testing"
	setvariable "App_Message" "Set vars via API" "$url" "$pass"
fi

if [ "$mode" == "config" ];then
	if [ ! "${pass}" == "${empty}" ];then
		echo "I: set password to configured one if none is defined"
		setvariable "System_Password" "${pass}" "$url" "" &&
		setvariable "PWChecked" 'checked' "$url" "";fi

	[ ! "${hostname}" == "${empty}" ] && setvariable "System_HostName" "${hostname}" "$url" "$pass"
	[ ! "${dscriptserver}" == "${empty}" ] && setvariable "App_dScriptServer" "${dscriptserver}" "$url" "$pass"
	[ ! "${lights}" == "${empty}" ] && setvariable "App_Lights" "${lights}" "$url" "$pass" && eupdate='true'
	[ ! "${lightsmax}" == "${empty}" ] && setvariable "App_LightsOffset" "${lightsmax}" "$url" "$pass" && eupdate='true'
	[ ! "${shutters}" == "${empty}" ] && setvariable "App_Shutters" "${shutters}" "$url" "$pass" && eupdate='true'
	if [ ! "${autoio}" == "${empty}" ] && [ "${autoio}" == 'true' ];then
		setvariable "App_EnableAutoIO" "1" "$url" "$pass"
		setvariable "AutoIOChecked" 'checked' "$url" "$pass"
	elif [ ! "${autoio}" == "${empty}" ] && [ "${autoio}" == 'false' ];then
		setvariable "App_EnableAutoIO" "0" "$url" "$pass"
		setvariable "AutoIOChecked" ' ' "$url" "$pass";fi
	[ -n "${eupdate}" ] &&  setvariable "App_EntityCountsUpdated" "1" "$url" "$pass" && eupdate=''
fi

if [ "$mode" == "shutter" ];then
	if [ ! "${shutterrelayct}" == "${empty}" ];then
		if [ "${shutterrelayct}" == 'row' ];then shutterrelayct='1'
		elif [ "${shutterrelayct}" == 'parallel' ];then shutterrelayct='2'
		else shutterrelayct='0';fi
		setvariable "App_ShutterRelayCT" "${shutterrelayct}" "$url" "$pass";fi

	if [ "${shutterid}" == "${empty}" ];then
		>&2 echo "$scriptName: error: missing parameter: -si= | --shutterid="
		>&2 echo "Try '$scriptName --help' for more information."
		exit 22;fi

	if [ ! "${shuttertype}" == "${empty}" ];then
		if [ "${shuttertype}" == 'roller' ];then shuttertype='1'
		elif [ "${shuttertype}" == 'raffstore' ];then shuttertype='2'
		elif [ "${shuttertype}" == 'jealousy' ];then shuttertype='3'
		else shuttertype='0';fi
		setvariable "App_ShutterType${shutterid}" "${shuttertype}" "$url" "$pass";fi
	[ ! "${shutterct}" == "${empty}" ] && setvariable "App_ShutterCT${shutterid}" "${shutterct}" "$url" "$pass"
fi

if [ "$mode" == "io" ];then
	if [ "${IOid}" == "${empty}" ];then
		>&2 echo "$scriptName: error: missing parameter: -ii= | --ioid="
		>&2 echo "Try '$scriptName --help' for more information."
		exit 22;fi

	if [ ! "${IOtype}" == "${empty}" ];then
		if [ "${IOtype}" == 'light' ];then IOtype='1'
		elif [ "${IOtype}" == 'shutter' ];then IOtype='2'
		elif [ "${IOtype}" == 'socket' ];then IOtype='3'
		elif [ "${IOtype}" == 'motion' ];then IOtype='4'
		elif [ "${IOtype}" == 'button' ];then IOtype='5'
		elif [ "${IOtype}" == 'direct' ];then IOtype='6'
		else IOtype='0';fi
#		if [ "${IOtype}" -ne 0 ];then # disable AutoIO
#			setvariable "App_EnableAutoIO" "0" "$url" "$pass"
#			setvariable "AutoIOChecked" ' ' "$url" "$pass";fi			
		setvariable "App_IOType${IOid}" "${IOtype}" "$url" "$pass";fi

	if [ ! "${IOentity}" == "${empty}" ];then setvariable "App_IOSet${IOid}" "${IOentity}" "$url" "$pass";fi
fi

if [ "$mode" == "dev" ];then
	if [ "${dev_var}" == "${empty}" ];then
		>&2 echo "$scriptName: error: missing parameter: -v= | --variable="
		>&2 echo "Try '$scriptName --help' for more information."
		exit 22;fi
	setvariable "${dev_var}" "${dev_data}" "$url" "$pass"
fi

exit "$error"
