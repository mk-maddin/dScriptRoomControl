#!/usr/bin/env python3
"""Static checks for dScript sources (there is no command line compiler for dScript).

Checks:
  blocks       if/endif, do/loop, for/next, select/endselect, function/endfunction, thread/endthread are balanced
  threadstart  every 'threadstart X' refers to a defined thread
  suspend      every thread ends with 'threadsuspend' (or an endless do ... loop) before 'endthread'
  forvar       'for' loop variables are local variables / parameters of the enclosing function or thread
               (globals are shared by all threads - see the former use of the global 'x')
  webvars      every ~variable~ and getValue('variable') used in the web pages is declared
  timer        timer thread intervals are numeric literals >= MIN_TIMER_MS (a constant does not compile,
               10ms was never triggered on the board - see IODebounceTimer)

Usage: dscript_lint.py <project dir containing *.dsj>   (exit code 1 on errors)
"""
import json
import os
import re
import sys

WORD = re.compile(r"[A-Za-z_][A-Za-z_0-9]*")
DECL = re.compile(r"^\s*(?:fl|ee)?(?:int8|int16|int32|string)\s+([A-Za-z_]\w*)", re.I)
CONST = re.compile(r"^\s*const\s+([A-Za-z_]\w*)", re.I)
PORT = re.compile(r"^\s*(?:digitalport|analogport|flexport|clientport)\s+([A-Za-z_]\w*)", re.I)
BLOCK_START = re.compile(r"^\s*(function|thread)\b\s*(.*)$", re.I)
STATEMENT_WORDS = {"return", "threadstart", "threadsleep", "threadsuspend"}
MIN_TIMER_MS = 20
PAIRS = {"do": "loop", "for": "next", "select": "endselect"}


def strip_line(line):
    """Remove comments and string contents (keeps the quotes)."""
    out, in_str = [], False
    for ch in line:
        if ch == '"':
            in_str = not in_str
            out.append(ch)
        elif in_str:
            continue
        elif ch == ";":
            break
        else:
            out.append(ch)
    return "".join(out).rstrip()


def if_opens_block(code, pos):
    """Decide if the 'if' at code[pos] opens a multi line block.

    dScript allows: 'if cond then', 'if cond then stmt', 'if cond then stmt else stmt endif' (one line),
    'if cond stmt' (one line, no then) and 'if cond' (block, no then).
    """
    rest = code[pos + 2:]
    words = [w.lower() for w in WORD.findall(rest)]
    if "then" in words:
        return True  # an endif on the same line is counted separately
    if "endif" in words:
        return True
    if STATEMENT_WORDS & set(words):
        return False
    # a bare assignment (=, +=, -=) means 'if cond stmt'
    if re.search(r"(?<![=!<>+\-])=(?!=)", rest) or re.search(r"[+\-]=", rest):
        return False
    # a call as last element ('if cond Init()' / 'if(cond) tcpip.Write(...)')
    m = re.search(r"([A-Za-z_][\w.]*)\s*\([^()]*(?:\([^()]*\)[^()]*)*\)\s*$", rest)
    if m and m.group(1).lower() != "if" and not re.search(r"(==|!=|<=|>=|<|>|\band\b|\bor\b)\s*[A-Za-z_][\w.]*\s*\([^)]*\)\s*$", rest, re.I):
        prefix = rest[:m.start()].strip()
        if prefix and not prefix.endswith(("(", "==", "!=", "<", ">", "and", "or")):
            return False
    return True


class Linter:
    def __init__(self):
        self.errors = []
        self.globals = set()
        self.consts = set()
        self.threads = set()
        self.threadstarts = []  # (file, line, name)

    def error(self, path, lineno, msg):
        self.errors.append("%s:%s: %s" % (path, lineno, msg))

    def collect_globals(self, path, lines):
        depth = 0
        for line in lines:
            code = strip_line(line)
            m = BLOCK_START.match(code)
            if m:
                depth += 1
            elif re.match(r"^\s*end(function|thread)\b", code, re.I):
                depth -= 1
            elif depth == 0:
                for rx in (DECL, CONST, PORT):
                    d = rx.match(code)
                    if d:
                        self.globals.add(d.group(1))
                        if rx is CONST:
                            self.consts.add(d.group(1))
                # tcpip.ip System_IP etc. are bindings, not declarations

    def check_file(self, path, lines):
        stack = []          # (keyword, lineno)
        block = None        # current function/thread: dict
        for lineno, raw in enumerate(lines, 1):
            code = strip_line(raw)
            if not code.strip():
                continue
            low = code.lower()
            m = BLOCK_START.match(code)
            if m:
                kind, sig = m.group(1).lower(), m.group(2)
                if block is not None:
                    self.error(path, lineno, "%s starts inside %s '%s' (line %s) - missing end%s?" % (kind, block["kind"], block["name"], block["line"], block["kind"]))
                name_m = re.match(r"(?:(?:int8|int16|int32|string)\s+)?([A-Za-z_]\w*)", sig.strip(), re.I)
                name = name_m.group(1) if name_m else "?"
                params = set(re.findall(r"(?:int8|int16|int32|string)\s+([A-Za-z_]\w*)", sig, re.I))
                block = {"kind": kind, "name": name, "line": lineno, "locals": params, "last": None, "forvars": []}
                if kind == "thread":
                    self.threads.add(name)
                    self.check_timer(path, lineno, name, sig)
                stack = []
                continue
            end = re.match(r"^\s*end(function|thread)\b", code, re.I)
            if end:
                kind = end.group(1).lower()
                if block is None or block["kind"] != kind:
                    self.error(path, lineno, "end%s without %s" % (kind, kind))
                else:
                    for kw, ln in stack:
                        self.error(path, ln, "'%s' is not closed in %s '%s'" % (kw, kind, block["name"]))
                    if kind == "thread" and block["last"] not in ("threadsuspend", "loop"):
                        self.error(path, lineno, "thread '%s' does not end with threadsuspend (or an endless loop)" % block["name"])
                    for var, ln in block["forvars"]:
                        if var not in block["locals"]:
                            self.error(path, ln, "loop variable '%s' is not local in %s '%s' (globals are shared by all threads)" % (var, kind, block["name"]))
                block, stack = None, []
                continue
            if block is None:
                continue

            d = DECL.match(code)
            if d:
                block["locals"].add(d.group(1))
            for v in re.findall(r"\bfor\s+([A-Za-z_]\w*)\s*=", code, re.I):
                block["forvars"].append((v, lineno))
            for t in re.findall(r"\bthreadstart\s+([A-Za-z_]\w*)", code, re.I):
                self.threadstarts.append((path, lineno, t))

            # walk the tokens of the line in order
            for tm in WORD.finditer(code):
                w = tm.group(0).lower()
                if w == "if":
                    if if_opens_block(code, tm.start()):
                        stack.append(("if", lineno))
                elif w == "endif":
                    self.close(path, lineno, stack, "if", "endif", block)
                elif w in PAIRS:
                    stack.append((w, lineno))
                elif w in PAIRS.values():
                    opener = [k for k, v in PAIRS.items() if v == w][0]
                    self.close(path, lineno, stack, opener, w, block)
            words = [w.lower() for w in WORD.findall(code)]
            block["last"] = "threadsuspend" if words and words[-1] == "threadsuspend" else ("loop" if words and words[0] == "loop" and len(words) == 1 else words[0] if words else None)
        if block is not None:
            self.error(path, block["line"], "%s '%s' is not closed" % (block["kind"], block["name"]))

    def check_timer(self, path, lineno, name, sig):
        trigger = re.match(r"[A-Za-z_]\w*\s*\(\s*([^)]*?)\s*\)", sig.strip())
        if not trigger:
            return
        value = trigger.group(1)
        if re.fullmatch(r"\d+", value):
            if int(value) < MIN_TIMER_MS:
                self.error(path, lineno, "timer thread '%s' interval %sms is below %sms (not triggered on the board)" % (name, value, MIN_TIMER_MS))
        elif value in self.consts:
            self.error(path, lineno, "timer thread '%s' interval must be a numeric literal, not the constant '%s'" % (name, value))

    def close(self, path, lineno, stack, opener, closer, block):
        if not stack:
            self.error(path, lineno, "'%s' without '%s' in %s '%s'" % (closer, opener, block["kind"], block["name"]))
            return
        kw, ln = stack.pop()
        if kw != opener:
            self.error(path, lineno, "'%s' closes '%s' opened in line %s" % (closer, kw, ln))

    def check_threadstarts(self):
        for path, lineno, name in self.threadstarts:
            if name not in self.threads:
                self.error(path, lineno, "threadstart of unknown thread '%s'" % name)

    def check_web(self, webdir):
        if not os.path.isdir(webdir):
            return
        for fn in sorted(os.listdir(webdir)):
            if not fn.endswith((".htm", ".html", ".js")) or fn.startswith("."):
                continue
            path = os.path.join(webdir, fn)
            with open(path, encoding="latin-1") as fh:
                for lineno, line in enumerate(fh, 1):
                    getvalues = [] if line.lstrip().startswith("//") else re.findall(r"getValue\(\s*['\"]([A-Za-z_]\w*)['\"]\s*\)", line)  # skip commented out JavaScript
                    for var in re.findall(r"~([A-Za-z_]\w*)~", line) + getvalues:
                        if var not in self.globals:
                            self.error(path, lineno, "web page uses undeclared variable '%s'" % var)


def lint_project(project_dir):
    dsj = [f for f in os.listdir(project_dir) if f.endswith(".dsj")]
    if dsj:
        with open(os.path.join(project_dir, dsj[0])) as fh:
            files = [f["file"] for f in json.load(fh)["files"] if f.get("compile", True)]
    else:
        files = sorted(f for f in os.listdir(project_dir) if f.endswith(".dsi") and not f.startswith("."))
    linter = Linter()
    sources = []
    for fn in files:
        path = os.path.join(project_dir, fn)
        with open(path, encoding="latin-1") as fh:
            sources.append((path, fh.read().splitlines()))
    for path, lines in sources:
        linter.collect_globals(path, lines)
    for path, lines in sources:
        linter.check_file(path, lines)
    linter.check_threadstarts()
    linter.check_web(os.path.join(project_dir, "web"))
    return linter.errors


def main(argv):
    project = argv[1] if len(argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "dScriptRoomControl")
    errors = lint_project(project)
    for e in errors:
        print(e)
    print("%d error(s)" % len(errors))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
