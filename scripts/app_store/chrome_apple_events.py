#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time


def run_osascript(script: str) -> str:
    completed = subprocess.run(
        ["osascript", "-e", script],
        capture_output=True,
        text=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError((completed.stderr or completed.stdout).strip() or "osascript failed")
    return completed.stdout.rstrip("\n")


def enable_js_apple_events() -> None:
    script = """
tell application "Google Chrome" to activate
tell application "System Events"
  tell process "Google Chrome"
    click menu item "Permitir JavaScript para eventos de Apple" of menu 1 of menu item "Opciones para desarrolladores" of menu 1 of menu bar item "Visualización" of menu bar 1
  end tell
end tell
"""
    run_osascript(script)


def exec_js(js: str) -> str:
    script = (
        'tell application "Google Chrome" to execute active tab of front window javascript '
        + json.dumps(js)
    )
    try:
        return run_osascript(script)
    except RuntimeError as exc:
        if "JavaScript mediante AppleScript est" not in str(exc):
            raise
        enable_js_apple_events()
        return run_osascript(script)


def select_tab_by_url(url_fragment: str) -> str:
    script = f"""
tell application "Google Chrome"
  repeat with w in windows
    repeat with i from 1 to count of tabs of w
      set t to tab i of w
      if URL of t contains {json.dumps(url_fragment)} then
        set active tab index of w to i
        set index of w to 1
        activate
        return URL of active tab of w
      end if
    end repeat
  end repeat
  return ""
end tell
"""
    result = run_osascript(script)
    if not result:
        raise RuntimeError(f"Could not find Chrome tab containing {url_fragment!r}")
    return result


def navigate(url: str) -> None:
    exec_js(f'location.href = {json.dumps(url)}; "OK";')


def sleep_until(check_js: str, timeout: float, interval: float = 0.5) -> str:
    deadline = time.time() + timeout
    last = ""
    while time.time() < deadline:
        last = exec_js(check_js)
        if last not in {"", "false", "null", "undefined", "WAIT"}:
            return last
        time.sleep(interval)
    raise TimeoutError(f"Timed out waiting for browser condition. Last value: {last!r}")


def wait_for_text(text: str, timeout: float = 15.0) -> None:
    check_js = f'(()=> document.body && document.body.innerText.includes({json.dumps(text)}) ? "READY" : "WAIT")()'
    sleep_until(check_js, timeout)


def wait_for_url(url_fragment: str, timeout: float = 15.0) -> None:
    check_js = (
        f'(()=> location.href.includes({json.dumps(url_fragment)}) ? location.href : "WAIT")()'
    )
    sleep_until(check_js, timeout)


def click_regex(pattern: str, selectors: str = 'button,[role="button"],[role="menuitem"],a[href]') -> None:
    js = f"""
(() => {{
  const rx = new RegExp({json.dumps(pattern)}, "i");
  const node = [...document.querySelectorAll({json.dumps(selectors)})]
    .find((el) => rx.test((el.innerText || el.textContent || "") + " " + (el.getAttribute("aria-label") || "")));
  if (!node) return "NOT_FOUND";
  node.click();
  return "CLICKED";
}})()
"""
    result = exec_js(js)
    if result != "CLICKED":
        raise RuntimeError(f"Could not find clickable element for pattern {pattern!r}")


def set_field(field_name: str, value: str) -> None:
    js = f"""
(() => {{
  const value = {json.dumps(value)};
  const escaped = CSS.escape({json.dumps(field_name)});
  const node = document.querySelector(`[name="${{escaped}}"], #${{escaped}}`);
  if (!node) return "NOT_FOUND";
  const setter = Object.getOwnPropertyDescriptor(node.__proto__, "value")?.set;
  if (setter) setter.call(node, value);
  else node.value = value;
  node.dispatchEvent(new Event("input", {{ bubbles: true }}));
  node.dispatchEvent(new Event("change", {{ bubbles: true }}));
  node.blur();
  return node.value;
}})()
"""
    result = exec_js(js)
    if result == "NOT_FOUND":
      raise RuntimeError(f"Field {field_name!r} not found in the current page")


def set_select(field_name: str, value: str) -> None:
    js = f"""
(() => {{
  const escaped = CSS.escape({json.dumps(field_name)});
  const node = document.querySelector(`[name="${{escaped}}"]`);
  if (!node) return "NOT_FOUND";
  node.value = {json.dumps(value)};
  node.dispatchEvent(new Event("input", {{ bubbles: true }}));
  node.dispatchEvent(new Event("change", {{ bubbles: true }}));
  return node.value;
}})()
"""
    result = exec_js(js)
    if result == "NOT_FOUND":
        raise RuntimeError(f"Select {field_name!r} not found in the current page")


def dump_fields() -> None:
    js = r"""
(() => {
  const fields = [...document.querySelectorAll("input, textarea, select")].map((el) => ({
    name: el.name || "",
    id: el.id || "",
    tag: el.tagName,
    type: el.type || "",
    value: (el.value || "").slice(0, 200)
  }));
  return JSON.stringify(fields);
})()
"""
    print(exec_js(js))


def cli() -> int:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="cmd", required=True)

    exec_parser = sub.add_parser("exec-js")
    exec_parser.add_argument("js")

    nav_parser = sub.add_parser("navigate")
    nav_parser.add_argument("url")
    nav_parser.add_argument("--select-tab")
    nav_parser.add_argument("--wait-text")
    nav_parser.add_argument("--wait-url")
    nav_parser.add_argument("--timeout", type=float, default=15.0)

    click_parser = sub.add_parser("click-regex")
    click_parser.add_argument("pattern")
    click_parser.add_argument("--selectors", default='button,[role="button"],[role="menuitem"],a[href]')

    set_parser = sub.add_parser("set-field")
    set_parser.add_argument("field_name")
    set_parser.add_argument("value")

    select_parser = sub.add_parser("set-select")
    select_parser.add_argument("field_name")
    select_parser.add_argument("value")

    sub.add_parser("dump-fields")

    tab_parser = sub.add_parser("select-tab")
    tab_parser.add_argument("url_fragment")

    args = parser.parse_args()

    if args.cmd == "exec-js":
        print(exec_js(args.js))
        return 0
    if args.cmd == "navigate":
        if args.select_tab:
            select_tab_by_url(args.select_tab)
        navigate(args.url)
        if args.wait_url:
            wait_for_url(args.wait_url, timeout=args.timeout)
        if args.wait_text:
            wait_for_text(args.wait_text, timeout=args.timeout)
        return 0
    if args.cmd == "select-tab":
        print(select_tab_by_url(args.url_fragment))
        return 0
    if args.cmd == "click-regex":
        click_regex(args.pattern, selectors=args.selectors)
        return 0
    if args.cmd == "set-field":
        set_field(args.field_name, args.value)
        return 0
    if args.cmd == "set-select":
        set_select(args.field_name, args.value)
        return 0
    if args.cmd == "dump-fields":
        dump_fields()
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(cli())
