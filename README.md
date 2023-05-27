# Mini Proxy Example

This is just an example to demonstrate that you can make HTTP requests inside
your request handlers, although I strongly advise against it. It blocks your
valuable worker thread for a time you have no control over.

## Running the demo

1. Have some other server running on port 8000

```console
$ python -m http.server
```

2. Start this server

```console
$ zig build run
```
3. Browse the directory indirectly

```console
$ curl http://localhost:3000/
$ curl http://localhost:3000/src/main.zig

# etc
```

## Why is this dangerouse

The reasons I advise against depending on HTTP requests directly from within your
request handler, are briefly:

- you make a 3rd party server's latency your own.
- if for some (malicious) reason the remote server sends its response really,
  really slowly, you might find yourself in a slow loris situation, eventually
  starving ALL your worker threads, rendering your server "dead" or
  unresponsive.

## What would be a better approach?

- use the worker threads (request handlers) to dispatch the work to some other
  thread (pool) that executes potentially long-running tasks, and immediately
  return a handle or an ID that identifies the request.
- have your clients poll your server to query whether the potentially long-running
  task with the provided handle has yielded a result yet.
- if the long-running task has completed, return the result upon the next poll.

Essentially, make potentially long-running tasks execute asynchronously and
you'll "never" risk having your entire server blocked by slow external
resources.

### If you're brave

There is SOME support for pausing and resuming request handlers in facil.io. So,
basically, you can `http_pause()` your request, have some other thread
`http_resume()` it, check if a response can be sent, and decide whether to
`http_pause()` it again or use `http_send_...()` / `http_finish()` on it.

There's no zap wrapping of this functionality yet, but if you're fine with using
facil.io's data structures directly, you can already use it via
`zap.http_pause()`, etc.

