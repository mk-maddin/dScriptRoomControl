# dScriptRoomControl
Custom app firmware for dScript boards (by Robot-Electronics / Devantech Ltd.) for Home Assistant RoomControl

For detailed documentation please check README.docx

## Checks
There is no command line compiler for dScript, so `tools/dscript_lint.py` runs static checks on every push
(balanced if/do/for/select/function/thread blocks, threadstart targets, threads ending with threadsuspend,
local loop variables, variables used in the web pages are declared):

    python3 tools/dscript_lint.py dScriptRoomControl
