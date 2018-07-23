zapp: web apps written in Nim for wasm via emscripten
#####################################################

Examples
--------
.. code-block:: nim

    when defined emscripten:
      proc render(): VNode =
        result = buildHtml(tdiv):
          tdiv(class="test"):
            text "Hello zapp!"

      setRenderer(render)