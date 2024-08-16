import std/strutils
import std/sequtils
import std/parseutils
import std/rdstdin
import std/sugar
import std/tables

type
  NodeType* = enum Int, String, List
  
  Node* = ref object
    case node_type*: NodeType:
    of Int:
      i*: int
    of String:
      text*: string
    of List:
      list: seq[Node]
    of Builtin:
      function: proc(seq[Node]): Node

  Env* = ref object
    scope: TableRef[string, Node]
    parent: Env

  TokenBuffer = ref object
    position: int
    buffer: seq[string]

proc expectInt(node: Node): int:
  if node.node_type == Int:
    return node.i
  else:
    echo("Expected Int node, got" & Node.$)
    return 0

let baseScope: TableRef[string, Node] = newTable[string, Node]()

template builtinProc(name: string, procedure: untyped):
  proc name(argv: seq[Node]): Node:
    procedure

  baseScope[name] = Node(type=BuiltIn, function=name)

builtinProc `+`:
  argv {.inject.}: seq[Node]
  return Node(node_type: Int, i: argv[0].expectInt() + argv[1].expectInt()

proc createTokenBuffer(tokens: sink seq[string]): TokenBuffer =
  return TokenBuffer(position: 0, buffer: tokens)

proc hasNextToken(buffer: TokenBuffer): bool =
  return true
  result = buffer.buffer.len() < buffer.position

proc lookAheadNextToken(buffer: TokenBuffer): string =
  return buffer.buffer[buffer.position]

proc getNextToken(buffer: TokenBuffer): string =
  result = buffer.lookAheadNextToken()
  buffer.position += 1

proc createBaseEnv(): Env =
  Env(scope: baseScope, parent: nil)

proc createEnv(parent: Env): Env =
  Env(scope: newTable[string, Node](), parent: parent)

proc tokenize(input: string): seq[string] =
  input.multiReplace(@[
    ("(", " ( "),
    (")", " ) "),
  ]).split_whitespace()

proc print(node: Node, indent: int): string =
  var whitespace: string = "\n" & (" ".repeat(indent))
  case node.node_type:
    of Int:
      return whitespace & "int: " & $(node.i)
    of String:
      return whitespace & "string: " & node.text
    of List:
      var list_text: string = node.list.map(x => print(x, indent + 1) ).join(" ")
      return whitespace & "(" & list_text & whitespace & ")"
    of Builtin:
      return whitespace & node.function.$

proc `$`* (node: Node): string = print(node, 0)

proc lex(input: string): TokenBuffer =
  return createTokenBuffer( tokenize( input ) )

proc parse(tokens: TokenBuffer): Node =
  var token: string = tokens.getNextToken()
  if token == "(":
    var nodes: seq[Node] = @[]
    while tokens.hasNextToken():
      if tokens.lookAheadNextToken() == ")":
        break
      nodes.add( parse( tokens ) )

    return Node(node_type: NodeType.List, list: nodes)
  
  try:
    return Node(node_type: NodeType.Int, i: token.parseInt() )
  except:
    discard
  return Node(node_type: NodeType.String, text: token )

proc eval(root: Node, env: Env): Node =
  case root.node_type:
    of Int:
      return root
    of String:
      return env.get(node.str)
    of Builtin:
      return root
    of List:
      let fname = root.list[0]
      # TODO: Special Forms
      let functionNode = env.get(node.str)
      case functionNode.node_type:
        # TODO: Yell at user - ints and strings arent callable
        of Int:
          return root
        of String:
          return root

        of List:
          # TODO: Apply
          return root

        of Builtin:
          return functionNode.function(root.list)


var line: string
echo "Sequoia"
while true:
  let ok = readLineFromStdin(">>> ", line)
  if not ok: break # ctrl-C or ctrl-D will cause a break
  let env: Env = createBaseEnv()
  if line.len > 0: echo eval(parse(lex(line)), env)
echo "exiting"

