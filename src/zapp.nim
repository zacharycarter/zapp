# zapp
# Copyright zacharycarter
# Web apps with Nim and Wasm.
when defined emscripten:
  {.experimental: "notnil".}

  import
    jsbind,
    jsbind / [emscripten],
    sugar,
    strutils,
    tables,
    times,
    zapp / [dsl, zconsole, zcomponent, zdom, vdom]

  const 
    fullCollectThreshold = 128 * 1024 * 1024 # 128 Megabytes

  type
    PatchKind = enum
      pkReplace, pkRemove, pkAppend, pkInsertBefore, pkDetach

    EqResult = enum
      componentsIdentical, different, similar, identical, useNewNode

    Patch = object
      kind: PatchKind
      parent, current: Node
      n: VNode

    VPatch = object
      parent, newChild: VNode
      pos: int

    ZappContext* = ref object ## Underlying zapp context. Usually you can ignore this.
      rootId: string not nil
      renderer: proc (): VNode {.closure.}
      currentTree: VNode
      toFocus: Node
      toFocusV: VNode
      renderId: int
      patches: seq[Patch] # we reuse this to save allocations
      patchLen: int
      vPatches: seq[VPatch]
      vPatchLen: int
      runCount: int
      surpressRedraws*: bool
      byId: Table[string, VNode]
      when defined(stats):
        recursion: int
      orphans: Table[string, bool]

  var
    zctx*: ZappContext
    initDone = false 
    mainLoopRunning = true
    gcRequested = false
    lastFullCollectTime = 0.0
    root = "ROOT" 
    initProc: proc()
    renderProc: proc(): VNode

  # zapp internal API

  # ----------------- event wrapping ---------------------------------------

  template nativeValue(ev): string = cast[Event](ev).target.value
  template setNativeValue(ev, val) = cast[Event](ev).target.value = val

  template keyeventBody() =
    let v = nativeValue(ev)
    n.value = v
    assert action != nil
    action(ev, n)
    if n.value != v:
      setNativeValue(ev, n.value)
    # Do not call redraw() here! That is already done
    # by ``zctx.addEventHandler``.

  proc wrapEvent(d: Node; n: VNode; k: EventKind;
                 action: EventHandler): NativeEventHandler =
    proc stdWrapper(): NativeEventHandler =
      let action = action
      let n = n
      result = proc (ev: Event) =
        if n.kind == VNodeKind.textarea or n.kind == VNodeKind.input or n.kind == VNodeKind.select:
          keyeventBody()
        else: action(ev, n)

    proc enterWrapper(): NativeEventHandler =
      let action = action
      let n = n
      result = proc (ev: Event) =
        if cast[KeyboardEvent](ev).keyCode == 13: keyeventBody()

    proc laterWrapper(): NativeEventHandler =
      let action = action
      let n = n
      var timer = -1
      result = proc (ev: Event) =
        proc wrapper() = keyeventBody()
        if timer != -1: clearTimeout(timer)
        timer = setTimeout(wrapper, 400)

    case k
    of EventKind.onkeyuplater:
      result = laterWrapper()
      d.addEventListener("keyup", result)
    of EventKind.onkeyupenter:
      result = enterWrapper()
      d.addEventListener("keyup", result)
    else:
      result = stdWrapper()
      d.addEventListener(toEventName[k], result)

  # --------------------- DOM diff -----------------------------------------

  template detach(n: VNode) =
    addPatch(zctx, pkDetach, nil, nil, n)

  template attach(n: VNode) =
    n.dom = result
    if n.id != nil: zctx.byId[n.id] = n

  proc applyEvents(n: VNode; zctx: ZappContext) =
    let dest = n.dom
    for i in 0..<len(n.events):
      n.events[i][2] = wrapEvent(dest, n, n.events[i][0], n.events[i][1])

  proc getVNodeById*(id: string; zctx: ZappContext = zctx): VNode =
    ## Get the VNode that was marked with ``id``. Returns ``nil``
    ## if no node exists.
    if zctx.byId.contains(id):
      result = zctx.byId[id]

  proc vnodeToDom*(n: VNode; zctx: ZappContext): Node =
    if n.kind == VNodeKind.text:
      result = document.createTextNode(n.text)
      attach n
    elif n.kind == VNodeKind.verbatim:
      result = document.createElement("div")
      result.innerHTML = n.text
      attach n
      return result
    elif n.kind == VNodeKind.vthunk:
      let x = callThunk(vcomponents[n.text], n)
      result = vnodeToDom(x, zctx)
      #n.key = result.key
      attach n
      return result
    elif n.kind == VNodeKind.dthunk:
      result = callThunk(dcomponents[n.text], n)
      #n.key = result.key
      attach n
      return result
    # # elif n.kind == VNodeKind.component:
    # #   let x = VComponent(n)
    # #   if x.onAttachImpl != nil: x.onAttachImpl(x)
    # #   assert x.renderImpl != nil
    # #   if x.expanded == nil:
    # #     x.expanded = x.renderImpl(x)
    # #     #  x.updatedImpl(x, nil)
    # #   assert x.expanded != nil
    # #   result = vnodeToDom(x.expanded, zctx)
    # #   attach n
    # #   return result
    else:
      result = document.createElement(toTag[n.kind])
      attach n
      for k in n:
        appendChild(result, vnodeToDom(k, zctx))
      # text is mapped to 'value':
      if n.text != nil:
        result.value = n.text
    if n.id != nil:
      result.id = n.id
    if n.class != nil:
      result.class = n.class
    #if n.key >= 0:
    #  result.key = n.key
    for k, v in attrs(n):
      if v != nil:
        result.setAttr(k, v)
    applyEvents(n, zctx)
    if n == zctx.toFocusV and zctx.toFocus.isNil:
      zctx.toFocus = result
    # if not n.style.isNil: applyStyle(result, n.style)

  proc same(n: VNode, e: Node; nesting = 0): bool =
    if zctx.orphans.contains(n.id): return true
    if n.kind == VNodeKind.component:
      discard
      # result = same(VComponent(n).expanded, e, nesting+1)
    elif n.kind == VNodeKind.verbatim:
      result = true
    elif n.kind == VNodeKind.vthunk or n.kind == VNodeKind.dthunk:
      # we don't check these for now:
      result = true
    elif toTag[n.kind] == e.nodeName:
      result = true
      if n.kind != VNodeKind.text:
        # BUGFIX: Microsoft's Edge gives the textarea a child containing the text node!
        if e.len != n.len and n.kind != VNodeKind.textarea:
          echo "expected ", n.len, " real ", e.len, " ", toTag[n.kind], " nesting ", nesting
          return false
        for i in 0 ..< n.len:
          # console.log(n)
          console.log(e.childNodes)
          console.log(e.childNodes.child(0))
          if not same(n[i], e[i], nesting+1): return false
    else:
      echo "VDOM: ", toTag[n.kind], " DOM: ", e.nodename

  proc replaceById(id: string; newTree: Node) =
    let x = document.getElementById(id)
    x.parentNode.replaceChild(newTree, x)
    newTree.id = id

  when defined(profileKarax):
    type
      DifferEnum = enum
        deKind, deId, deIndex, deText, deComponent, deClass,
        deSimilar
  
    var
      reasons: array[DifferEnum, int]
  
    proc echa(a: array[DifferEnum, int]) =
      for i in low(DifferEnum)..high(DifferEnum):
        echo i, " value: ", a[i]
  
  proc eq(a, b: VNode): EqResult =
    if a.kind != b.kind:
      when defined(profileKarax): inc reasons[deKind]
      return different
    if a.id != b.id:
      when defined(profileKarax): inc reasons[deId]
      return different
    result = identical
    if a.index != b.index:
      when defined(profileKarax): inc reasons[deIndex]
      return different
    if a.kind == VNodeKind.text:
      if a.text != b.text:
        when defined(profileKarax): inc reasons[deText]
        return different # similar
    elif a.kind == VNodeKind.vthunk or a.kind == VNodeKind.dthunk:
      if a.text != b.text: return different
      if a.len != b.len: return different
      for i in 0..<a.len:
        if eq(a[i], b[i]) == different: return different
    elif a.kind == VNodeKind.verbatim:
      if a.text != b.text:
        return different
    elif b.kind == VNodeKind.component:
      # different component names mean different components:
      if a.text != b.text:
        when defined(profileKarax): inc reasons[deComponent]
        return different
      #if VComponent(a).key.isNil and VComponent(b).key.isNil:
      #  when defined(profileKarax): inc reasons[deComponent]
      #  return different
      # if VComponent(a).key != VComponent(b).key:
      #   when defined(profileKarax): inc reasons[deComponent]
      #   return different
      return componentsIdentical
    #if:
    #  when defined(profileKarax): inc reasons[deClass]
    #  return different
    # if a.class != b.class or not eq(a.style, b.style) or not sameAttrs(a, b):
    #   when defined(profileKarax): inc reasons[deSimilar]
    #   return similar
    # Do not test event listeners here!
    return result
  
  # proc updateStyles(newNode, oldNode: VNode) =
  #   # we keep the oldNode, but take over the style from the new node:
  #   if oldNode.dom != nil:
  #     if newNode.style != nil: applyStyle(oldNode.dom, newNode.style)
  #     else: oldNode.dom.style = Style()
  #     oldNode.dom.class = newNode.class
  #   oldNode.style = newNode.style
  #   oldNode.class = newNode.class
  
  proc updateAttributes(newNode, oldNode: VNode) =
    # we keep the oldNode, but take over the attributes from the new node:
    if oldNode.dom != nil:
      for k, _ in attrs(oldNode):
        oldNode.dom.removeAttribute(k)
      for k, v in attrs(newNode):
        if v != nil:
          oldNode.dom.setAttr(k, v)
    takeOverAttr(newNode, oldNode)
  
  proc mergeEvents(newNode, oldNode: VNode; zctx: ZappContext) =
    let d = oldNode.dom
    for i in 0..<oldNode.events.len:
      let k = oldNode.events[i][0]
      let name = case k
                  of EventKind.onkeyuplater, EventKind.onkeyupenter: "keyup"
                  else: toEventName[k]
      d.removeEventListener(name, oldNode.events[i][2])
    shallowCopy(oldNode.events, newNode.events)
    applyEvents(oldNode, zctx)
  
  when false:
    proc printV(n: VNode; depth: string = "") =
      # kout depth, string($n.kind), string"key ", n.index
      #for k, v in pairs(n.style):
      #  kout depth, "style: ", k, v
      if n.kind == VNodeKind.component:
        let nn = VComponent(n)
        if nn.expanded != nil: printV(nn.expanded, ">>" & depth)
      elif n.kind == VNodeKind.text:
        kout depth, n.text
      for i in 0 ..< n.len:
        printV(n[i], depth & "  ")
  
  proc addPatch(zctx: ZappContext; ka: PatchKind; parenta, currenta: Node;
                na: VNode) =
    let L = zctx.patchLen
    if L >= zctx.patches.len:
      # allocate more space:
      zctx.patches.add(Patch(kind: ka, parent: parenta, current: currenta, n: na))
    else:
      zctx.patches[L].kind = ka
      zctx.patches[L].parent = parenta
      zctx.patches[L].current = currenta
      zctx.patches[L].n = na
    inc zctx.patchLen
  
  proc addvPatch(zctx: ZappContext; parent: VNode; pos: int; newChild: VNode) =
    let L = zctx.vPatchLen
    if L >= zctx.vPatches.len:
      # allocate more space:
      zctx.vPatches.add(VPatch(parent: parent, newChild: newChild, pos: pos))
    else:
      zctx.vPatches[L].parent = parent
      zctx.vPatches[L].newChild = newChild
      zctx.vPatches[L].pos = pos
    inc zctx.vPatchLen
  
  proc applyPatch(zctx: ZappContext) =
    for i in 0..<zctx.patchLen:
      let p = zctx.patches[i]
      case p.kind
      of pkReplace:
        let nn = vnodeToDom(p.n, zctx)
        if p.parent == nil:
          replaceById(zctx.rootId, nn)
        else:
          p.parent.replaceChild(nn, p.current)
      of pkRemove:
        p.parent.removeChild(p.current)
      of pkAppend:
        let nn = vnodeToDom(p.n, zctx)
        p.parent.appendChild(nn)
      of pkInsertBefore:
        let nn = vnodeToDom(p.n, zctx)
        p.parent.insertBefore(nn, p.current)
      of pkDetach:
        let n = p.n
        if n.id != nil: zctx.byId.del(n.id)
        # if n.kind == VNodeKind.component:
        #   let x = VComponent(n)
        #   if x.onDetachImpl != nil: x.onDetachImpl(x)
        # XXX for some reason this causes assertion errors otherwise:
        if not zctx.surpressRedraws: n.dom = nil
    zctx.patchLen = 0
    for i in 0..<zctx.vPatchLen:
      let p = zctx.vPatches[i]
      p.parent[p.pos] = p.newChild
      assert p.newChild.dom != nil
    zctx.vPatchLen = 0
  
  proc diff(newNode, oldNode: VNode; parent, current: Node; zctx: ZappContext): EqResult =
    when defined(stats):
      if zctx.recursion > 100:
        echo "newNode ", newNode.kind, " oldNode ", oldNode.kind, " eq ", eq(newNode, oldNode)
        if oldNode.kind == VNodeKind.text:
          echo oldNode.text
        #return
        #doAssert false, "overflow!"
      inc zctx.recursion
    result = eq(newNode, oldNode)
    case result
    of componentsIdentical:
      discard
    #   zctx.components.add ComponentPair(oldNode: VComponent(oldNode),
    #                                     newNode: VComponent(newNode),
    #                                     parent: parent,
    #                                     current: current)
    of identical, similar:
      newNode.dom = oldNode.dom
      if result == similar:
        # updateStyles(newNode, oldNode)
        updateAttributes(newNode, oldNode)
        if oldNode.kind == VNodeKind.text:
          oldNode.text = newNode.text
          oldNode.dom.nodeValue = newNode.text
  
      if newNode.events.len != 0 or oldNode.events.len != 0:
        mergeEvents(newNode, oldNode, zctx)
      when false:
        if oldNode.kind == VNodeKind.input or oldNode.kind == VNodeKind.textarea:
          if oldNode.text != newNode.text:
            oldNode.text = newNode.text
            oldNode.dom.value = newNode.text
  
      let newLength = newNode.len
      let oldLength = oldNode.len
      if newLength == 0 and oldLength == 0: return result
      let minLength = min(newLength, oldLength)
  
      assert oldNode.kind == newNode.kind
      var commonPrefix = 0
      let isSpecial = oldNode.kind == VNodeKind.component or
                      oldNode.kind == VNodeKind.vthunk or
                      oldNode.kind == VNodeKind.dthunk
  
      template eqAndUpdate(a: VNode; i: int; b: VNode; j: int; info, action: untyped) =
        let oldLen = zctx.patchLen
        let oldLenV = zctx.vPatchLen
        assert i < a.len
        assert j < b.len
        let r = if isSpecial:
                  diff(a[i], b[j], parent, current, zctx)
                else:
                  diff(a[i], b[j], current, current.childNodes[j], zctx)
        case r
        of identical, componentsIdentical, similar:
          a[i] = b[j]
          action
        of useNewNode:
          zctx.addvPatch(b, j, a[i])
          action
          # unfortunately, we need to propagate the changes upwards:
          result = useNewNode
        of different:
          # undo what 'diff' would have done:
          zctx.patchLen = oldLen
          zctx.vPatchLen = oldLenV
          if result != different: result = r
          break
      # compute common prefix:
      while commonPrefix < minLength:
        eqAndUpdate(newNode, commonPrefix, oldNode, commonPrefix, string"prefix"):
          inc commonPrefix
  
      # compute common suffix:
      var oldPos = oldLength - 1
      var newPos = newLength - 1
      while oldPos >= commonPrefix and newPos >= commonPrefix:
        eqAndUpdate(newNode, newPos, oldNode, oldPos, string"suffix"):
          dec oldPos
          dec newPos
  
      let pos = min(oldPos, newPos) + 1
      # now the different children are in commonPrefix .. pos - 1:
      for i in commonPrefix..pos-1:
        let r = diff(newNode[i], oldNode[i], current, current.childNodes[i], zctx)
        if r == useNewNode:
          #oldNode[i] = newNode[i]
          zctx.addvPatch(oldNode, i, newNode[i])
        elif r != different:
          newNode[i] = oldNode[i]
        #else:
        #  result = useNewNode
  
      if oldPos + 1 == oldLength:
        for i in pos..newPos:
          zctx.addPatch(pkAppend, current, nil, newNode[i])
          result = useNewNode
      else:
        let before = current.childNodes[oldPos + 1]
        for i in pos..newPos:
          zctx.addPatch(pkInsertBefore, current, before, newNode[i])
          result = useNewNode
      # XXX call 'attach' here?
      for i in pos..oldPos:
        detach(oldNode[i])
        #doAssert i < current.childNodes.len
        zctx.addPatch(pkRemove, current, current.childNodes[i], nil)
        result = useNewNode
    of different:
      detach(oldNode)
      zctx.addPatch(pkReplace, parent, current, newNode)
    of useNewNode: doAssert(false, "eq returned useNewNode")
    when defined(stats):
      dec zctx.recursion
  
  proc applyComponents(zctx: ZappContext) =
    discard
    # the first 'diff' pass detects components in the VDOM. The
    # 'applyComponents' expands components and so on until no
    # components are left to check.
    # var i = 0
    # # beware: 'diff' appends to zctx.components!
    # # So this is actually a fixpoint iteration:
    # while i < zctx.components.len:
    #   let x = zctx.components[i].oldNode
    #   let newNode = zctx.components[i].newNode
    #   when defined(karaxDebug):
    #     echo "Processing component ", newNode.text, " changed impl set ", x.changedImpl != nil
    #   if x.changedImpl != nil and x.changedImpl(x, newNode):
    #     when defined(karaxDebug):
    #       echo "Component ", newNode.text, " did change"
    #     let current = zctx.components[i].current
    #     let parent = zctx.components[i].parent
    #     x.updatedImpl(x, newNode)
    #     let oldExpanded = x.expanded
    #     x.expanded = x.renderImpl(x)
    #     when defined(karaxDebug):
    #       echo "Component ", newNode.text, " re-rendered"
    #     x.renderedVersion = x.version
    #     if oldExpanded == nil:
    #       detach(x)
    #       zctx.addPatch(pkReplace, parent, current, x.expanded)
    #       when defined(karaxDebug):
    #         echo "Component ", newNode.text, ": old expansion didn't exist"
    #     else:
    #       let res = diff(x.expanded, oldExpanded, parent, current, zctx)
    #       if res == useNewNode:
    #         when defined(karaxDebug):
    #           echo "Component ", newNode.text, ": re-render triggered a DOM change (case A)"
    #         discard "diff created a patchset for us, so this is fine"
    #       elif res != different:
    #         when defined(karaxDebug):
    #           echo "Component ", newNode.text, ": re-render triggered no DOM change whatsoever"
    #         x.expanded = oldExpanded
    #         assert oldExpanded.dom != nil, "old expanded.dom is nil"
    #       else:
    #         when defined(karaxDebug):
    #           echo "Component ", newNode.text, ": re-render triggered a DOM change (case B)"
    #         assert x.expanded.dom != nil, "expanded.dom is nil"
    #   inc i
    # setLen(zctx.components, 0)
  
  when defined(stats):
    proc depth(n: VNode; total: var int): int =
      var m = 0
      for i in 0..<n.len:
        m = max(m, depth(n[i], total))
      result = m + 1
      inc total
  
  proc runDel*(zctx: ZappContext; parent: VNode; position: int) =
    detach(parent[position])
    let current = parent.dom
    zctx.addPatch(pkRemove, current, current.childNodes[position], nil)
    parent.delete(position)
    applyPatch(zctx)
    doAssert same(zctx.currentTree, document.getElementById(zctx.rootId))
  
  proc runIns*(zctx: ZappContext; parent, kid: VNode; position: int) =
    let current = parent.dom
    if position >= parent.len:
      zctx.addPatch(pkAppend, current, nil, kid)
      parent.add(kid)
    else:
      let before = current.childNodes[position]
      zctx.addPatch(pkInsertBefore, current, before, kid)
      parent.insert(kid, position)
    applyPatch(zctx)
    doAssert same(zctx.currentTree, document.getElementById(zctx.rootId))
  
  proc runDiff*(zctx: ZappContext; oldNode, newNode: VNode) =
    let olddom = oldNode.dom
    doAssert olddom != nil
    discard diff(newNode, oldNode, nil, olddom, zctx)
    # this is a bit nasty: Since we cannot patch the 'parent' of
    # the current VNode (because we don't store it at all!), we
    # need to override the fields individually:
    takeOverFields(newNode, oldNode)
    applyComponents(zctx)
    applyPatch(zctx)
    if zctx.currentTree == oldNode:
      zctx.currentTree = newNode
    doAssert same(zctx.currentTree, document.getElementById(zctx.rootId))

  proc dodraw(zctx: ZappContext) =
    if zctx.renderer.isNil: return
    let newtree = zctx.renderer()
    inc zctx.runCount
    newtree.id = zctx.rootId
    zctx.toFocus = nil
    if zctx.currentTree == nil:
      let asdom = vnodeToDom(newtree, zctx)
      replaceById(zctx.rootId, asdom)
    else:
      doAssert same(zctx.currentTree, document.getElementById(zctx.rootId))
      let olddom = document.getElementById(zctx.rootId)
      discard diff(newtree, zctx.currentTree, nil, olddom, zctx)
      #kout string"patch len ", patches.len
    when defined(profileZapp):
      echo "<<<<<<<<<<<<<<"
      echa reasons
    applyComponents(zctx)
    when defined(profileZapp):
      echo "--------------"
      echa reasons
      echo ">>>>>>>>>>>>>>"
    applyPatch(zctx)
    zctx.currentTree = newtree
    doAssert same(zctx.currentTree, document.getElementById(zctx.rootId))
  
    # now that it's part of the DOM, give it the focus:
    if zctx.toFocus != nil:
      zctx.toFocus.focus()
    zctx.renderId = 0
    when defined(stats):
      zctx.recursion = 0
      var total = 0
      echo "depth ", depth(zctx.currentTree, total), " total ", total

  proc redraw*(zctx: ZappContext = zctx) =
    # we buffer redraw requests:
    when false:
      if drawTimeout != nil:
        clearTimeout(drawTimeout)
      drawTimeout = setTimeout(dodraw, 30)
    elif true:
      if zctx.renderId == 0:
        var raf: proc(time: float)
        raf = proc(time: float) =
          jsUnref(raf)
          zctx.doDraw()
        jsRef(raf)
        zctx.renderId = window.requestAnimationFrame(raf)
    else:
      dodraw(zctx)
    
  # entry

  template requestGCFullCollect*() =
    gcRequested = true

  proc runGC() =
    let t = epochTime()
    if gcRequested or (t > lastFullCollectTime + 10 and getOccupiedMem() > fullCollectThreshold):
        GC_enable()
        when defined(useRealtimeGC):
          GC_setMaxPause(0)
        GC_fullCollect()
        GC_disable()
        lastFullCollectTime = t
        gcRequested = false
    else:
        when defined(useRealtimeGC):
          GC_step(1000, true)
        else:
          {.hint: "It is recommended to compile your project with -d:useRealtimeGC for emscripten".}

  proc init() =
    zconsole.init()
    zdom.init()

    if document.getElementById(root).isNil:
      raise newException(Exception, " Could not find a <div> with id: " & root &
        ". Zapp requires a <div> for its rendering target. You can pass an id as " & 
        "a string to the setRenderer procedure as the second parameter.")
    zctx = ZappContext(
      rootId: root, renderer: renderProc,
      patches: newSeq[Patch](60),
      vPatches: newSeq[VPatch](30),
      surpressRedraws: false,
      byId: initTable[string, VNode](),
      orphans: initTable[string, bool]()
    )

    var raf: proc()
    zctx.renderId = window.requestAnimationFrame(
      proc(time: float) =
        jsUnref(raf)
        zctx.doDraw()
    )
    jsRef(raf)

    var ohc: proc()
    ohc = proc() =
      jsUnref(ohc)
      redraw()
    
    jsRef(ohc)
    window.onhashchange = ohc
      

  proc innerMain() =
    runGC()

  proc loop() {.cdecl.} =
    initProc = proc() =
      init()

    if initDone:
      if mainLoopRunning:
        innerMain()
    else:
      let r = EM_ASM_INT "return (document.readyState === 'complete') ? 1 : 0;"
      if r == 1:
        GC_disable() # GC Should only be called close to the bottom of the stack on emscripten.
        initProc()
        initProc = nil
        initDone = true

  proc setRenderer*(renderer: proc (): VNode, r: string = root) =
    root = r
    renderProc = renderer

    setupUnhandledExceptionHandler()
      
    emscripten_set_main_loop(loop, 0, 1)


  when isMainModule:

    proc render(): VNode =
      result = buildHtml(tdiv):
        tdiv(class="test"):
          text "Hello World!"

    setRenderer(render)
