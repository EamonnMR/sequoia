import std/strutils
import std/sequtils
import std/parseutils
import std/rdstdin
import std/sugar
import std/tables
import std/macros
import std/envvars

proc puts(str: string) =
  if getEnv("mode") == "debug":
    puts str

type
  NodeType* = enum Int, String, List, Builtin
  
  Node* = ref object
    case node_type*: NodeType:
    of Int:
      i*: int
    of String:
      text*: string
    of List:
      list: seq[Node]
    of Builtin:
      function: proc(args:seq[Node]):Node

  Env* = ref object
    scope: TableRef[string, Node]
    parent: Env

  TokenBuffer = ref object
    position: int
    buffer: seq[string]

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
      return whitespace & "<builtin function>"

proc `$`* (node: Node): string = print(node, 0)

proc expectInt(node: Node): int=
  if node.node_type == Int:
    return node.i
  else:
    puts "Expected Int node, got: " & $(node)
    return 0

proc expectString(node: Node): string=
  if node.node_type == String:
    return node.text
  else:
    puts "Expected Int node, got: " & $(node)
    return ""

let baseScope: TableRef[string, Node] = newTable[string, Node]()

template builtinProc(name: untyped, expected_args: int, body: untyped): untyped =
  let nameStr: string = astToStr(name).replace("`", "")
  proc name(argv {.inject.}: seq[Node]): Node =
    puts "Calling: " & nameStr
    for node in argv:
      puts "arg :" & $(node)
    if expected_args > 0 and len(argv) != expected_args:
      puts "Expected "& $(expected_args) & " args, got: " & $(len(argv))
      return Node(node_type: Int, i: 0)

    body

  baseScope[nameStr] = Node(node_type: BuiltIn, function: name)

builtinProc `+`, 2:
  Node(node_type: Int, i: argv[0].expectInt() + argv[1].expectInt())

builtinProc begin, 0:
  for arg in argv:
    echo($(arg))
  return argv[^1]

builtinProc display, 1:
  puts($(argv[0]))
  return argv[0]


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

proc `[]`(env: Env, key: string): Node =
  if key in env.scope:
    puts "Undefined: " & key
    return env.scope[key]
  return Node(node_type: Int, i: 0)

proc `[]=`(env: Env, key: string, value: Node)=
  env.scope[key] = value

proc tokenize(input: string): seq[string] =
  input.multiReplace(@[
    ("(", " ( "),
    (")", " ) "),
  ]).split_whitespace()

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
      return env[root.text]
    of Builtin:
      return root
    of List:
      let fname = root.list[0].expectString()
      
      if fname == "define":
        env[root.list[1].expectString()] = eval(root.list[2], env)
      let functionNode: Node = env[fname]
      echo(fname)
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
          echo("Builtin call")
          return functionNode.function(
            root.list[1 .. ^1].map( arg => eval(arg, env) )
          )


var line: string
echo "Sequoia"
while true:
  let ok = readLineFromStdin(">>> ", line)
  if not ok: break # ctrl-C or ctrl-D will cause a break
  let env: Env = createBaseEnv()
  if line.len > 0: echo eval(parse(lex(line)), env)
echo "exiting"

