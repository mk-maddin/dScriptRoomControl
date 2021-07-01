/**
helptext.js

these are all help and explanation texts
*/

function AESkeyText(x) {
    document.getElementById('help').innerHTML = "<br>AES Encryption key<br><br>Only required when AES Binary mode is selected.<br><br>This key MUST be 32 characters long.<br> Use ASCII characters in the range 0x20-0x7E excluding \" (0x22).<br><br>Use a random mix of upper & lower case, numbers and symbols: you don't need to memorise it! The identical key must be used in your encryption program.<br><br>It is necessary to restart for correct encryption after changing this value!";
}
function AESText(x) {
    document.getElementById('help').innerHTML = "<br>Enable AES Encryption<br><br>This uses the same commands as the binary command set, but uses AES256 encryption for the commands and the response.";
}
function AppCfgText(x) {
    document.getElementById('help').innerHTML = "<br>App Config<br><br>Define configuration values for current application.";
}
function AppdScriptServerText(x){
    document.getElementById('help').innerHTML = "<br>dScriptServer hostname/ip<br><br>The dScriptServer is a server provided via python modul. This server can receive consolidated information about multiple dScirpt modules to allow integration e.g. into home automation systems.<br>If this input is set to '' there are no status updates sent to the server.";
}
function AppText(x) {
    document.getElementById('help').innerHTML = "<br>Application<br><br>Jumps to the application webpage.";
}
function ASCIIText(x) {
    document.getElementById('help').innerHTML = "<br>Enable ASCII command set.<br><br>The ASCII command set allows you to control the module by typing plain text commands into a TCP/IP terminal program, such as PuTTY.";
}
function AttachedTypeText(x) {
    document.getElementById('help').innerHTML = "<br>Attached Relay Number<br><br>Digital I/O can optionally be attached to a relay. Normally use relays 5-32 for this as they are not physical relays. <br><br>This gives digital outputs the same control features as relays.";
}
function BinaryText(x) {
    document.getElementById('help').innerHTML = "<br>Enable Binary command set.<br><br>The Binary command set is the simplest if you are programming an application to control the module.<br><br>The commands are a subset of those used on our ETHxxx series.";
}
function ButtonText(x) {
    document.getElementById('help').innerHTML = "<br>Count of click / touch Buttons<br><br>Number of general buttons managed via the DSBoard. Buttons are connected to I/O ports and can be configured there.<br>(This value is ready only.)";
}
function ClickSleepText(x) {
    document.getElementById('help').innerHTML = "<br>Time for clicking / delay<br><br>Time (in milliseconds) to provide for multi click/IO-input commands.Be careful with high numbers here - this will increase the time until command is executed.";
}
function CounterText(x) {
    document.getElementById('help').innerHTML = "<br>Counter/Timers<br><br>Eight Counter/Timers.<br> Used as Counters when the count input is connected to an Input <br><br>Used as Timers when connected to the internal 1Hz clock, T1.<br><br>The 32-bit counter counts up from zero to a maximum of 2,147,483,647.";
}
function DebugText(x){
    document.getElementById('help').innerHTML = "<br>Values Debug Page<br><br>Shows all variables configured and updates itself every 1 second.";
}
function DHCPText(x){
    document.getElementById('help').innerHTML = "<br>Static IP is disabled because DHCP is enabled.<br><br>Uncheck DHCP to allow static IP addresses.";
}
function DNS1Text(x) {
    if(document.getElementById('SystemIP').disabled == true) DHCPText();
    else document.getElementById('help').innerHTML = "<br>Primary DNS Address<br><br>This can be the address of your router if your ISP has provided DNS addresses.<br>It can also be the address of the DNS server itself.<br><br> Google provides a free server at 8.8.8.8<br>This is a good choice for the secondary DNS";
}
function DNS2Text(x) {
    if(document.getElementById('SystemIP').disabled == true) DHCPText();
    else document.getElementById('help').innerHTML = "<br>Secondary DNS Address<br><br>This can be the address of your router if your ISP has provided DNS addresses.<br>It can also be the address of the DNS server itself.<br><br> Google provides a free server at 8.8.8.8<br>This is a good choice for the secondary DNS";
}
function DoorShutterCTText(x) {
    document.getElementById('help').innerHTML = "<br>Time for door shutting<br><br>Time (in milliseconds) it takes until a door shutter is fully closed from fully open.";
}
function EasyMailText(x) {
    document.getElementById('help').innerHTML = "<br>Easy Mail<br><br>Send secure emails in response to selected events.";
}
function EnPassText(x) {
    document.getElementById('help').innerHTML = "<br>Enable password setup on your browser.<br><br>This enables the _pw.htm file.<br> The _pw.htm file contains your password and the javascript needed to load it into your browser. <br><br>After loading the _pw.htm page, make sure you uncheck this to prevent others gaining access to your pages.";
}
function GateText(x) {
    if(document.getElementById('SystemIP').disabled == true) DHCPText();
    else document.getElementById('help').innerHTML = "<br>Gateway Address<br><br>This is normally the address of your router. It is the way out of your local network to the wider internet.";
}
function HostText(x) {
    document.getElementById('help').innerHTML = "<br>Host Name<br><br>A unique name for the device on your network. Use plain text such as:<br>MYMODULE";
}
function HttpText(x) {
    document.getElementById('help').innerHTML = "<br>The HTTP port number.<br><br>This the port number used for the webpages. The default is 80.<br>If you change it from 80, you will need to include the port number in the address.<br><br>Example if you change to port 1234:<br>168.192.0.145:1234/index.htm";
}
function IOAutoText(x) {
    document.getElementById('help').innerHTML = "<br>Auto I/O Configuration<br><br>Automatically define the IO types and entity IDs based on the number of lights and shutters configured within Entities config page.";
}
function IOConfigText(x) {
   document.getElementById('help').innerHTML = "<br>I/O Configuration<br><br>For every I/O you can define which type of entity (lights, shutters, sockets etc.) it should handle. You addiionally can define a comma separated list of entity IDs which should be handled by this IO.<br><br>Please note that the entity type 'Motion' always handles lights - so you have to enter light entity Ids there.";
}
function IOText(x) {
    document.getElementById('help').innerHTML = "<br>Input/Output<br><br>Configure the IO types on input and which entity ID they control.<br><br>The entity ID lists are maximum 20 characters.";
}
function IOType(x) {
    document.getElementById('help').innerHTML = "<br>I/O Types<br><br>Configure Digital I/O with or without pull-up resistors, or analogue inputs with 4.096v or 5v reference.";
}
function IPText(x) {
    if(document.getElementById('SystemIP').disabled == true) DHCPText();
    else document.getElementById('help').innerHTML = "<br>IP Address<br><br>Enter a static IP address for the device, for example:<br>192.168.0.123<br><br>Changes will come into effect after this device is re-booted. ";
}
function LightsOffsetText(x) {
    document.getElementById('help').innerHTML = "<br>Relay ID of first light<br><br>Lights are counted backwards. From highest relay to lowest. This number must be >= lights + shutters*2 to ensure enought relays are reserved.<br>This is the highes relady ID used for a light but at the same time the first light ID.";
}
function LightsText(x) {
    document.getElementById('help').innerHTML = "<br>Count of Lights<br><br>Number of lights managed via the DSBoard. Light connections start at relay ~App_LightsOffset~ of board and count downwards.";
}
function ModbusParamsText(x){
    document.getElementById('help').innerHTML = "<br>Modbus Parameters<br><br>Modbus UID is the UID (address) for this unit. Normally leave this set to 1.<br>All other UID's are forwarded to other Modbus modules on the RS485 Modbus RTU port.<br><br>Modbus Baudrate & Parity<br>These are for the RS485 port only. <br>If you are not connecting another Modbus module, they can be ignored.<br><br>Changes take effect after next re-boot.";
}
function ModBusText(x) {
    document.getElementById('help').innerHTML = "<br>Enable ModBus over TCP/IP.<br><br>This alows the module to be controlled by a PLC or similar device that can issue ModBbus over TCP/IP commands.<br><br>Supported functions are 1, 4, 5 & 15.<br><br>TCP/IP port should be set to 502, the port assigned for Modbus over TCP/IP.";
}
function MotionText(x) {
    document.getElementById('help').innerHTML = "<br>Count of Motion Sensors<br><br>Number of motion sensors managed via the DSBoard. Motion sensors are connected to I/O ports and can be configured there.<br>(This value is ready only.)";
}
function NetworkText(x) {
    document.getElementById('help').innerHTML = "<br>Network<br><br>Configure network IP address and associated parameters.";
}
function P2PText(x) {
    document.getElementById('help').innerHTML = "<br>Peer to Peer<br><br>Use inputs on this module to control relays on other dSxxxx modules which can be on your local LAN or across the internet.<br>";
}
function PasswordText(x) {
    document.getElementById('help').innerHTML = "<br>Webpages security password.<br><br>This is the password that is stored on your browser when you load _pw.htm. When non-blank, only authorised browsers may access your webpages. The password may be up to 200 ASCII characters in the range 0x20-0x7E excluding \" (0x22).<br><br>Leave blank to disable webpage security.";
}
function PortText(x) {
    document.getElementById('help').innerHTML = "<br>The TCP/IP port number.<br><br>This the port number used for the ASCII, Binary or ModBus commands.<br>(default=17123; default modbus=502)";
}
function RelayText(x) {
    document.getElementById('help').innerHTML = "<br>Relay Names<br><br>These are the labels on the relay buttons on the aplication page to give each relay a unique and descriptive name. <br><br>Maximum 20 characters.";
}
function Relay1Text(x) {
    document.getElementById('help').innerHTML = "<br>Relay 1-8 Names<br><br>These are the labels on the relay buttons on the aplication page to give each relay a unique and descriptive name. <br><br>Maximum 20 characters.";
}
function ResetText(x) {
    document.getElementById('help').innerHTML = "<br>STOP<br><br>Use with extreme caution!<br><br>Resets the device configuration to default.<br>It is recommended to restart after this action!";
}
function RebootText(x) {
    document.getElementById('help').innerHTML = "<br>STOP<br><br>Use with extreme caution!<br><br>Rebooting after changes to the network parameters can result in an unreachable module and a site visit to fix it.";
}
function ScheduleText(x) {
    document.getElementById('help').innerHTML = "<br>Scheduler<br><br>Schedule daily events with 8 schedules, 2 events per schedule and a week day mask.";
}
function SecurityText(x) {
    document.getElementById('help').innerHTML = "<br>Webpage Security<br><br>Configure the password for webpage security.";
}
function ShuttersConfigText(x) {
    document.getElementById('help').innerHTML = "<br>Shutter Configuration<br><br>Defines the shutter type for correct functions and maximum closing time (fully open to fully closed) per shutter.";
}
function ShuttersConnectText(x) {
    document.getElementById('help').innerHTML = "<br>Shutter Relay Connection<br><br>Defines how shutters are connected to the relays.<br> Recommended is a connection in row (which means one shutter defines if the shutter is moving or not, while the other one defines if it is moving up or down).This way of connecting shutters is fail save.<br><br>Alternatively shutters can be connected in parallel - one relay moves the shutter up, the other one moves the shutter down. While this is more eays there is a risk of both relays on at the same time and due to this cause damage to the shutter.";
}
function ShuttersText(x) {
    document.getElementById('help').innerHTML = "<br>Count of Shutters<br><br>Number of shutters managed via the DSBoard. Shutter connections start at relay 0 of board and count upwards +2.";
}
function SocketsText(x) {
    document.getElementById('help').innerHTML = "<br>Count of Sockets<br><br>Number of sockets managed via the DSBoard. Socket connections start at relay ~App_PhysRelays~ of board and count downwards.<br>(This value is ready only.)";
}
function StatusText(x) {
    document.getElementById('help').innerHTML = "<br>Status<br><br>Shows the current status of the module.";
}
function SubText(x) {
    if(document.getElementById('SystemIP').disabled == true) DHCPText();
    else document.getElementById('help').innerHTML = "<br>SubNet Mask<br><br>Normally set to:<br>255.255.255.0<br><br>This must be identical to your networks subnet.";
}
function TCPIPText(x) {
    document.getElementById('help').innerHTML = "<br>TCP/IP<br><br>Configure the TCP/IP port and command set.";
}
function WindowShutterCTText(x) {
    document.getElementById('help').innerHTML = "<br>Time for window shutting<br><br>Time (in milliseconds) it takes until a window shutter is fully closed from fully open.";
}