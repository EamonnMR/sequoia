import std/strutils
import std/rdstdin

type
  NodeType* = enum Int, String, List
  
  Node* = ref object
    case node_type*: NodeType:
    of Int:
      i*: int
    of String:
      text*: string
    of List:
      liet: seq[Node]

proc tokenIter(tokens: sink seq[string]): iterator(): string =
  return iterator(): string =
    for i in tokens:
      yield i

proc tokenize(input: string): seq[string] =
  input.multiReplace(@[
    ("(", " ( "),
    (")", " ) "),
  ]).split_whitespace()


proc parseList(getNextToken: iterator(): string): seq[string] =
  var tokens: seq[string] = @[]
  while true:
    if finished( getNextToken):
      return tokens
    else:
      tokens.add( getNextToken() )

proc parse(input: string): seq[string] =
  let nextToken = tokenIter( tokenize( input ) )
  return parseList( nextToken )


var line: string
echo "Sequoia"
while true:
  let ok = readLineFromStdin(">>>", line)
  if not ok: break # ctrl-C or ctrl-D will cause a break
  if line.len > 0: echo parse(line)
echo "exiting"

