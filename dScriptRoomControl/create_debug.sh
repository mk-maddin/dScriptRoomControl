#! /bin/bash
# ugly bash script to create a debug web view of all variables

proj_d='/home/onkraemer.de/kraemermar/Documents/Scripts/git/dScriptRoomControl/dScriptRoomControl'
var_f="${proj_d}/common_vars.dsi"
htm_f="${proj_d}/web/_debug.htm"

##  fixed html part1
cat > "${htm_f}" <<-EOF
<!DOCTYPE HTML>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DebugView</title>
    <link rel="stylesheet" type="text/css" href="dscript.css">
</head>

<!-- <body onload="startAJAX()"> -->
<body onload="JavaScript:AutoRefresh(1000);">
    <p align="left">
EOF

## dynamically create an ouput line per variable defined in "$var_f"
#cat "${var_f}" | egrep "int|string" | sed 's#^\s*##g' | sed 's#\s*;.*$##g' | egrep -v '|\(.*\)' | sed 's#\(^[^\s]\+\s\+\)\([A-Za-z0-9_]\+\)\(.*$\)#\2=~\2~<br>#g' | grep -v " " | sort -u >> "${htm_f}"
cat "${var_f}" | egrep "int|string" | sed 's#^\s*##g' | sed 's#\s*;.*$##g' | sed 's#\(^[^ ]\+\s\+\)\([A-Za-z0-9_]\+\)\(.*$\)#\2=~\2~<br>#g' | sort -u >> "${htm_f}"

## fixed html part2
cat >> "${htm_f}" <<-EOF
    </p>
<script type='text/javascript' src='globalfunctions.js'></script>

</body>
</html>
EOF

