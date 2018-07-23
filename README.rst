zapp: web apps written in Nim for wasm via emscripten
#####################################################

Warning
-------
This project is still very much in an alpha state. It is being actively worked on by me. Please don't bug me about / file issues about features you expect to work that don't.

If you don't see an example for something - you can expectx that it hasn't been implemented yet.

Examples
--------
.. code-block:: nim

    when defined emscripten:
      proc render(): VNode =
        result = buildHtml(tdiv):
          tdiv(class="test"):
            text "Hello zapp!"

      setRenderer(render)
