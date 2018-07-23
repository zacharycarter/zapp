when defined emscripten:
  import
    jsbind

  type
    EventTarget = ref object of JSObj

    # https://developer.mozilla.org/en-US/docs/Web/Events
    DomEvent* {.pure.} = enum
      Abort = "abort",
      BeforeInput = "beforeinput",
      Blur = "blur",
      Click = "click",
      CompositionEnd = "compositionend",
      CompositionStart = "compositionstart",
      CompositionUpdate = "compositionupdate",
      DblClick = "dblclick",
      Error = "error",
      Focus = "focus",
      FocusIn = "focusin",
      FocusOut = "focusout",
      Input = "input",
      KeyDown = "keydown",
      KeyPress = "keypress",
      KeyUp = "keyup",
      Load = "load",
      MouseDown = "mousedown",
      MouseEnter = "mouseenter",
      MouseLeave = "mouseleave",
      MouseMove = "mousemove",
      MouseOut = "mouseout",
      MouseOver = "mouseover",
      MouseUp = "mouseup",
      Resize = "resize",
      Scroll = "scroll",
      Select = "select",
      Unload = "unload",
      Wheel = "wheel"
    
    Window* = ref object of EventTarget

    Frame* = ref object of Window

    ClassList* = ref object of JSObj

    NodeType* = enum
      ElementNode = 1,
      AttributeNode,
      TextNode,
      CDATANode,
      EntityRefNode,
      EntityNode,
      ProcessingInstructionNode,
      CommentNode,
      DocumentNode,
      DocumentTypeNode,
      DocumentFragmentNode,
      NotationNode

    Node* = ref object of EventTarget

    NodeList* = ref object of JSObj

    Document = ref object of Node
  
    Element* = ref object of Node
  
    ValidityState* = ref object of JSObj
  
    Blob* = ref object of JSObj
  
    File* = ref object of Blob
  
    InputElement* = ref object of Element
  
    LinkElement* = ref object of Element
  
    EmbedElement* = ref object of Element
  
    AnchorElement* = ref object of Element
  
    OptionElement* = ref object of Element
  
    FormElement* = ref object of Element
  
    ImageElement* = ref object of Element
  
    Style* = ref object of Element
  
    EventPhase* = enum
      None = 0,
      CapturingPhase,
      AtTarget,
      BubblingPhase
  
    Event* = ref object of JSObj
  
    UIEvent* = ref object of Event
  
    KeyboardEvent* = ref object of UIEvent
      
    KeyboardEventKey* {.pure.} = enum
      # Modifier keys
      Alt,
      AltGraph,
      CapsLock,
      Control,
      Fn,
      FnLock,
      Hyper,
      Meta,
      NumLock,
      ScrollLock,
      Shift,
      Super,
      Symbol,
      SymbolLock,
  
      # Whitespace keys
      ArrowDown,
      ArrowLeft,
      ArrowRight,
      ArrowUp,
      End,
      Home,
      PageDown,
      PageUp,
  
      # Editing keys
      Backspace,
      Clear,
      Copy,
      CrSel,
      Cut,
      Delete,
      EraseEof,
      ExSel,
      Insert,
      Paste,
      Redo,
      Undo,
  
      # UI keys
      Accept,
      Again,
      Attn,
      Cancel,
      ContextMenu,
      Escape,
      Execute,
      Find,
      Finish,
      Help,
      Pause,
      Play,
      Props,
      Select,
      ZoomIn,
      ZoomOut,
  
      # Device keys
      BrigtnessDown,
      BrigtnessUp,
      Eject,
      LogOff,
      Power,
      PowerOff,
      PrintScreen,
      Hibernate,
      Standby,
      WakeUp,
  
      # Common IME keys
      AllCandidates,
      Alphanumeric,
      CodeInput,
      Compose,
      Convert,
      Dead,
      FinalMode,
      GroupFirst,
      GroupLast,
      GroupNext,
      GroupPrevious,
      ModeChange,
      NextCandidate,
      NonConvert,
      PreviousCandidate,
      Process,
      SingleCandidate,
  
      # Korean keyboards only
      HangulMode,
      HanjaMode,
      JunjaMode,
  
      # Japanese keyboards only
      Eisu,
      Hankaku,
      Hiragana,
      HiraganaKatakana,
      KanaMode,
      KanjiMode,
      Katakana,
      Romaji,
      Zenkaku,
      ZenkakuHanaku,
  
      # Function keys
      F1,
      F2,
      F3,
      F4,
      F5,
      F6,
      F7,
      F8,
      F9,
      F10,
      F11,
      F12,
      F13,
      F14,
      F15,
      F16,
      F17,
      F18,
      F19,
      F20,
      Soft1,
      Soft2,
      Soft3,
      Soft4,
  
      # Phone keys
      AppSwitch,
      Call,
      Camera,
      CameraFocus,
      EndCall,
      GoBack,
      GoHome,
      HeadsetHook,
      LastNumberRedial,
      Notification,
      MannerMode,
      VoiceDial,
  
      # Multimedia keys
      ChannelDown,
      ChannelUp,
      MediaFastForward,
      MediaPause,
      MediaPlay,
      MediaPlayPause,
      MediaRecord,
      MediaRewind,
      MediaStop,
      MediaTrackNext,
      MediaTrackPrevious,
  
      # Audio control keys
      AudioBalanceLeft,
      AudioBalanceRight,
      AudioBassDown,
      AudioBassBoostDown,
      AudioBassBoostToggle,
      AudioBassBoostUp,
      AudioBassUp,
      AudioFaderFront,
      AudioFaderRear,
      AudioSurroundModeNext,
      AudioTrebleDown,
      AudioTrebleUp,
      AudioVolumeDown,
      AUdioVolumeMute,
      AudioVolumeUp,
      MicrophoneToggle,
      MicrophoneVolumeDown,
      MicrophoneVolumeMute,
      MicrophoneVolumeUp,
  
      # TV control keys
      TV,
      TV3DMode,
      TVAntennaCable,
      TVAudioDescription,
      TVAudioDescriptionMixDown,
      TVAudioDescriptionMixUp,
      TVContentsMenu,
      TVDataService,
      TVInput,
      TVInputComponent1,
      TVInputComponent2,
      TVInputComposite1,
      TVInputComposite2,
      TVInputHDMI1,
      TVInputHDMI2,
      TVInputHDMI3,
      TVInputHDMI4,
      TVInputVGA1,
      TVMediaContext,
      TVNetwork,
      TVNumberEntry,
      TVPower,
      TVRadioService,
      TVSatellite,
      TVSatelliteBS,
      TVSatelliteCS,
      TVSatelliteToggle,
      TVTerrestrialAnalog,
      TVTerrestrialDigital,
      TVTimer,
  
      # Media controller keys
      AVRInput,
      AVRPower,
      ColorF0Red,
      ColorF1Green,
      ColorF2Yellow,
      ColorF3Blue,
      ColorF4Grey,
      ColorF5Brown,
      ClosedCaptionToggle,
      Dimmer,
      DisplaySwap,
      DVR,
      Exit,
      FavoriteClear0,
      FavoriteClear1,
      FavoriteClear2,
      FavoriteClear3,
      FavoriteRecall0,
      FavoriteRecall1,
      FavoriteRecall2,
      FavoriteRecall3,
      FavoriteStore0,
      FavoriteStore1,
      FavoriteStore2,
      FavoriteStore3,
      Guide,
      GuideNextDay,
      GuidePreviousDay,
      Info,
      InstantReplay,
      Link,
      ListProgram,
      LiveContent,
      Lock,
      MediaApps,
      MediaAudioTrack,
      MediaLast,
      MediaSkipBackward,
      MediaSkipForward,
      MediaStepBackward,
      MediaStepForward,
      MediaTopMenu,
      NavigateIn,
      NavigateNext,
      NavigateOut,
      NavigatePrevious,
      NextFavoriteChannel,
      NextUserProfile,
      OnDemand,
      Pairing,
      PinPDown,
      PinPMove,
      PinPUp,
      PlaySpeedDown,
      PlaySpeedReset,
      PlaySpeedUp,
      RandomToggle,
      RcLowBattery,
      RecordSpeedNext,
      RfBypass,
      ScanChannelsToggle,
      ScreenModeNext,
      Settings,
      SplitScreenToggle,
      STBInput,
      STBPower,
      Subtitle,
      Teletext,
      VideoModeNext,
      Wink,
      ZoomToggle,
  
      # Speech recognition keys
      SpeechCorrectionList,
      SpeechInputToggle,
  
      # Document keys
      Close,
      New,
      Open,
      Print,
      Save,
      SpellCheck,
      MailForward,
      MailReply,
      MailSend,
  
      # Application selector keys
      LaunchCalculator,
      LaunchCalendar,
      LaunchContacts,
      LaunchMail,
      LaunchMediaPlayer,
      LaunchMusicPlayer,
      LaunchMyComputer,
      LaunchPhone,
      LaunchScreenSaver,
      LaunchSpreadsheet,
      LaunchWebBrowser,
      LaunchWebCam,
      LaunchWordProcessor,
      LaunchApplication1,
      LaunchApplication2,
      LaunchApplication3,
      LaunchApplication4,
      LaunchApplication5,
      LaunchApplication6,
      LaunchApplication7,
      LaunchApplication8,
      LaunchApplication9,
      LaunchApplication10,
      LaunchApplication11,
      LaunchApplication12,
      LaunchApplication13,
      LaunchApplication14,
      LaunchApplication15,
      LaunchApplication16,
  
      # Browser control keys
      BrowserBack,
      BrowserFavorites,
      BrowserForward,
      BrowserHome,
      BrowserRefresh,
      BrowserSearch,
      BrowserStop,
  
      # Numeric keypad keys
      Key11,
      Key12,
      Separator
  
    MouseButtons* = enum
      NoButton = 0,
      PrimaryButton = 1,
      SecondaryButton = 2,
      AuxilaryButton = 4,
      FourthButton = 8,
      FifthButton = 16
  
    MouseEvent* = ref object of UIEvent    
  
    DataTransferItemKind* {.pure.} = enum
      File = "file",
      String = "string"
  
    DataTransferItem* = ref object of JSObj
  
    DataTransfer* = ref object of JSObj
  
    DataTransferDropEffect* {.pure.} = enum 
      None = "none",
      Copy = "copy",
      Link = "link",
      Move = "move"
  
    DataTransferEffectAllowed* {.pure.} = enum
      None = "none",
      Copy = "copy",
      CopyLink = "copyLink",
      CopyMove = "copyMove",
      Link = "link",
      LinkMove = "linkMove",
      Move = "move",
      All = "all",
      Uninitialized = "uninitialized"
  
    DragEventTypes* = enum
      Drag = "drag",
      DragEnd = "dragend",
      DragEnter = "dragenter",
      DragExit = "dragexit",
      DragLeave = "dragleave",
      DragOver = "dragover",
      DragStart = "dragstart",
      Drop = "drop"
  
    DragEvent* = ref object of MouseEvent
  
    TouchList* = ref object of JSObj
  
    Touch* = ref object of JSObj
  
    TouchEvent* = ref object of UIEvent
  
    Location* = ref object of JSObj
  
    History* = ref object of JSObj
  
    Navigator* = ref object of JSObj
  
    Plugin* = ref object of JSObj
  
    MimeType* = ref object of JSObj
  
    LocationBar* = ref object of JSObj

    MenuBar* = LocationBar
    PersonalBar* = LocationBar
    ScrollBars* = LocationBar
    ToolBar* = LocationBar
    StatusBar* = LocationBar
  
    Screen = ref object of JSObj
  
    Interval* = ref object of JSObj
  
    AddEventListenerOptions* = ref object of JSObj

  var 
    document*: Document
    window*: Window

  proc init*() =
    document = globalEmbindObject(Document, "document")
    window = globalEmbindObject(Window, "window")

  proc child*(n: NodeList; idx: int): Node {.jsImportWithName: "item".}
  proc childNodes*(n: Node): NodeList {.jsimportProp.}
  proc length*(nl: NodeList): int {.jsimportProp.}
  proc len*(n: Node): int = n.childNodes.length
  proc `[]`*(nl: NodeList; idx: int): Node = nl.child(idx)
  proc `[]`*(n: Node; idx: int): Node = n.childNodes.child(idx)

  proc setTimeout*(action: proc(); ms: int): int {.jsimportg.}
  proc clearTimeout*(t: int) {.jsimportg.}

  proc target*(ev: Event): Element {.jsimportProp.}
  proc keyCode*(ev: KeyboardEvent): int {.jsimportProp.}

  proc addEventListener*(et: EventTarget, ev: string, cb: proc(ev: Event), useCapture: bool = false) {.jsimport.}
  proc addEventListener*(et: EventTarget, ev: string, cb: proc(ev: Event), options: AddEventListenerOptions) {.jsimport.}
  proc removeEventListener*(et: EventTarget; ev: string; cb: proc(ev: Event)) {.jsimport.}

  proc requestAnimationFrame*(w: Window, function: proc(time: float)): int {.jsimport.}

  proc value*(n: Node): string {.jsimportProp.}
  proc `value=`*(n: Node; v: string) {.jsimportProp.}
  proc parentNode*(n: Node): Node {.jsimportProp.}
  proc `innerHTML=`*(n: Node, v: string) {.jsimportProp.}
  proc nodeName*(n: Node): string {.jsimportProp.}
  proc `nodeValue=`*(n: Node, v: string) {.jsimportProp.}

  proc appendChild*(n, child: Node) {.jsimport.}
  proc removeChild*(n, child: Node) {.jsimport.}
  proc replaceChild*(n, newNode, oldNode: Node) {.jsimport.}
  proc insertBefore*(n, newNode, before: Node) {.jsimport.}
  proc getElementById*(d: Document, id: string): Element {.jsimport.}
  proc createElement*(d: Document, identifier: string): Element {.jsimport.}
  proc createTextNode*(d: Document, identifier: string): Node {.jsimport.}

  proc id*(n: Node): string {.jsimportProp.}
  proc `id=`*(n: Node; x: string) {.jsimportProp.}
  proc class*(n: Node): string {.jsimportProp.}
  proc `class=`*(n: Node; v: string) {.jsimportProp.}

  # proc len*(x: Node): int = x.childNodes.len
  # proc `[]`*(x: Node; idx: int): Node = x.childNodes[idx]

  proc setAttr*(n: Node; key, val: string) {.jsimportWithName: "setAttribute".}

  proc appendData*(n: Node, data: string) {.jsimportProp.}
  proc cloneNode*(n: Node, copyContent: bool): Node {.jsimportProp.}
  proc deleteData*(n: Node, start, len: int) {.jsimportProp.}
  proc focus*(e: Node) {.jsimportProp.}
  proc getAttribute*(n: Node, attr: string): string {.jsimportProp.}
  proc getAttributeNode*(n: Node, attr: string): Node {.jsimportProp.}
  proc hasChildNodes*(n: Node): bool {.jsimportProp.}
  proc insertData*(n: Node, position: int, data: string) {.jsimportProp.}
  proc removeAttribute*(n: Node, attr: string) {.jsimportProp.}
  proc removeAttributeNode*(n, attr: Node) {.jsimportProp.}
  proc replaceData*(n: Node, start, len: int, text: string) {.jsimportProp.}
  proc scrollIntoView*(n: Node) {.jsimportProp.}
  proc setAttribute*(n: Node, name, value: string) {.jsimportProp.}
  proc setAttributeNode*(n: Node, attr: Node) {.jsimportProp.}

  proc `onhashchange=`*(w: Window, function: proc()) {.jsimportProp.}