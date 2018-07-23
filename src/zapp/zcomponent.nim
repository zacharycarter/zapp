when defined emscripten:
  import 
    macros,
    strutils,
    tables,
    vdom,
    zdom

  type
    ComponentKind* {.pure.} = enum
      None,
      Tag,
      VNode,
      Node
    
  var
    vcomponents* = newTable[string, proc(args: seq[VNode]): VNode]()
    dcomponents* = newTable[string, proc(args: seq[VNode]): Node]()
    allcomponents {.compileTime.} = initTable[string, ComponentKind]()

  proc isComponent*(x: string): ComponentKind {.compileTime.} =
    allcomponents.getOrDefault(x)
  
  proc addTags() {.compileTime.} =
    let x = (bindSym"VNodeKind").getTypeImpl
    expectKind(x, nnkEnumTy)
    for i in ord(VNodeKind.html)..ord(VNodeKind.high):
      # +1 because of empty node at the start of the enum AST:
      let tag = $x[i+1]
      allcomponents[tag] = ComponentKind.Tag
  
  static:
    addTags()