"""Adds the WaCaQA install (bundle folder 9) to an all-features bundle's install-all.bat, before its :end label.
usage: python add_qa_to_installall.py <bundle>/install-all.bat"""
import sys

p = sys.argv[1]
t = open(p, newline="").read()
add = ('echo.\r\npowershell -NoProfile -ExecutionPolicy Bypass -File "%~dp09-WaCaQA\\install.ps1" %*\r\n'
       'if errorlevel 1 goto end\r\n')
if "9-WaCaQA" not in t:
    t = t.replace(":end", add + ":end", 1)
open(p, "w", newline="").write(t)
print("install-all.bat: WaCaQA added")
