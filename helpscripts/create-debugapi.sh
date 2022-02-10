#!/bin/bash
# version: 2019.12.13
# description: ugly script to create a html containing all "usual" variables
#	not listed are array & const variables	

##-- save maximum error code
error=0; trap 'error=$(($?>$error?$?:$error))' ERR 

##--meta-information required paramteres
scriptAuthor="Martin Kraemer, mk.maddin@gmail.com"
scriptName=$( basename "$0" )
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

##--define internal fixed variables
proj_d="$(dirname ${scriptDir})/dScriptRoomControl"
var_f="${proj_d}/common_vars.dsi"
htm_f="${proj_d}/web/debugapi.htm"
disabled='disabled'

##  fixed html part1
cat > "${htm_f}" <<-EOF
<!DOCTYPE HTML>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DebugView</title>
    <link rel="stylesheet" type="text/css" href="dscript.css">
</head>

<body onload="startAJAX()">
    <h2 style="text-align:center" >Debug Page<h3>
    <br>
    <table>
EOF

##create a list of variables defined within "$var_v" file
variables=$(cat "${var_f}" | egrep "int|string" | sed 's#^\s*##g' | sed 's#\s*;.*$##g' | egrep -v "^.*int.*\[.*\].*$" | sed 's#\(^[^ ]\+\s\+\)\([A-Za-z0-9_]\+\)\(.*$\)#\2#g' | sort -u)

##create a labeled input box for each variable
for var in ${variables};do
#if [ "$var" == 'App_Debug' ] || [ "$var" == "App_Message" ];then disabled=''
#else disabled='disabled';fi
cat >> "${htm_f}" <<-EOF
     <tr><td>$var</td><td><input type="text" $disabled size="50" value="~$var~" id="Inp$var" onkeyup="newAJAXCommand('dscript.cgi?$var='+encodeURIComponent(this.value));"></td></tr>
EOF
done

## fixed html part2
cat >> "${htm_f}" <<-EOF
    </table>

<script type="text/javascript">

function ajaxUpdate() {
EOF

##update the input box of each variable
for var in ${variables};do
cat >> "${htm_f}" <<-EOF
    document.getElementById('Inp$var').value = getValue('$var');
EOF
done

##fixed html part3
cat >> "${htm_f}" <<-EOF
}
</script>
</body>
</html>
EOF

echo "I: created: ${htm_f}"
exit "${error}"
