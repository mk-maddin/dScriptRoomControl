"""Tests for tools/dscript_lint.py and the firmware sources."""
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import dscript_lint  # noqa: E402


def lint(tmp_path, source, web=None):
    (tmp_path / "main.dsi").write_text(source)
    if web is not None:
        (tmp_path / "web").mkdir()
        (tmp_path / "web" / "index.htm").write_text(web)
    return dscript_lint.lint_project(str(tmp_path))


def test_firmware_is_clean():
    assert dscript_lint.lint_project(os.path.join(ROOT, "dScriptRoomControl")) == []


def test_if_forms_are_balanced(tmp_path):
    src = """
int32 g
function F(int32 a)
    int32 i
    if a == 1 then
        g = 1
    elseif a == 2 then g = 2
    else g = 3
    endif
    if a > 0 then g = 1
    else g = 2 endif
    if a == 3 then g = 1 else g = 2 endif
    if a < 0 a = 0
    if a == 9 return
    if a == 8 F(1)
    if(a) tcpip.Write(g, a)
    if (a + (g*2)) > 4
        g = 0
    endif
    for i = 1 to 3
        do while g < 3
            g += 1
        loop
    next
    select a
        case 1 g = 1
    endselect
    return
endfunction
"""
    assert lint(tmp_path, src) == []


def test_extra_and_missing_endif(tmp_path):
    extra = "function F(int32 a)\n    if a == 1 then\n        a = 2\n    endif\n    endif\nendfunction\n"
    assert any("'endif' without 'if'" in e for e in lint(tmp_path, extra))
    missing = "function F(int32 a)\n    if a == 1 then\n        a = 2\nendfunction\n"
    assert any("'if' is not closed" in e for e in lint(tmp_path, missing))


def test_mismatched_blocks(tmp_path):
    src = "function F(int32 a)\n    do\n        a = 1\n    next\nendfunction\n"
    errors = lint(tmp_path, src)
    assert any("'next' closes 'do'" in e for e in errors)


def test_threads(tmp_path):
    src = """
int32 g
thread Good(1000)
    g = 1
    threadsuspend
endthread
thread Endless(const)
    do
        threadsleep 10
    loop
endthread
thread Bad(1000)
    g = 2
endthread
function Start()
    threadstart Good
    threadstart Missing
endfunction
"""
    errors = lint(tmp_path, src)
    assert len(errors) == 2, errors
    assert any("thread 'Bad' does not end with threadsuspend" in e for e in errors)
    assert any("unknown thread 'Missing'" in e for e in errors)


def test_global_loop_variable(tmp_path):
    src = "int32 x\nfunction F(int32 a)\n    int32 i\n    for i = 1 to 2\n    next\n    for a = 1 to 2\n    next\n    for x = 1 to 2\n    next\nendfunction\n"
    errors = lint(tmp_path, src)
    assert len(errors) == 1 and "loop variable 'x'" in errors[0]


def test_web_variables(tmp_path):
    src = "int32 Known\nconst Limit 3\n"
    errors = lint(tmp_path, src, web="<p>~Known~ ~Limit~ ~Unknown~</p>")
    assert len(errors) == 1 and "'Unknown'" in errors[0]


def test_timer_intervals(tmp_path):
    src = """
const TICK 10
int32 g
thread Ok(30)
    g = 1
    threadsuspend
endthread
thread TooFast(10)
    g = 1
    threadsuspend
endthread
thread FromConst(TICK)
    g = 1
    threadsuspend
endthread
thread OnVar(g)
    g = 0
    threadsuspend
endthread
thread Always(const)
    do
        threadsleep 10
    loop
endthread
"""
    errors = lint(tmp_path, src)
    assert len(errors) == 2, errors
    assert any("'TooFast' interval 10ms is below 20ms" in e for e in errors)
    assert any("'FromConst' interval must be a numeric literal" in e for e in errors)


def test_web_getvalue(tmp_path):
    src = "int32 Known\n"
    errors = lint(tmp_path, src, web="<script>getValue('Known'); getValue(\"Missing\")\n// getValue('Commented')</script>")
    assert len(errors) == 1 and "'Missing'" in errors[0]
