import jester, asyncdispatch

routes:
  get "/":
    redirect(uri("index.html"))

runForever()