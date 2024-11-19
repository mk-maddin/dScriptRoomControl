$IPNet='192.168.180.'

$Timeout = 100
$Ping = New-Object System.Net.NetworkInformation.Ping
$ErrorActionPreference='SilentlyContinue'

clear

foreach( $ip in @(1..254)){$s='false'
    $h = $($IPNet + $ip)
    $Response = $Ping.Send($h)
    if($Response.Status -eq 'Success'){
        $w=''
        $w = Invoke-WebRequest -Uri "http://$h/index.htm" -ErrorAction SilentlyContinue
        $s = $($w | Select-Object -ExpandProperty StatusCode -ErrorAction SilentlyContinue)}
    "$h -> $($Response.Status) -> $s"
}