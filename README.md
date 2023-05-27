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
