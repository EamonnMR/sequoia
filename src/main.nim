import std/strutils
import std/rdstdin

import std/rdstdin
var line: string
echo "Sequoia"
while true:
  let ok = readLineFromStdin(">>>", line)
  if not ok: break # ctrl-C or ctrl-D will cause a break
  if line.len > 0: echo line
echo "exiting"

