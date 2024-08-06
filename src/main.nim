import std/strutils
import std/rdstdin

proc parse(input: string): seq[string] =
  input.multiReplace(@[
    ("(", " ( "),
    (")", " ) "),
  ]).split_whitespace()

var line: string
echo "Sequoia"
while true:
  let ok = readLineFromStdin(">>>", line)
  if not ok: break # ctrl-C or ctrl-D will cause a break
  if line.len > 0: echo parse(line)
echo "exiting"

