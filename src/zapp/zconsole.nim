when defined emscripten:
  import
    jsbind,
    jsbind / [emscripten]

  type
    Console* = ref object of JSObj

  var
    console*: Console

  proc init*() =
    console = globalEmbindObject(Console, "console")

  proc log*(c: Console, obj: any) {.jsimport.}
  proc log*(c: Console, obj: JSObj) {.jsimport.}
  proc log*(c: Console, msg: string) {.jsimport.}