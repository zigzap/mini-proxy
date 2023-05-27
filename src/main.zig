const std = @import("std");
const zap = @import("zap");

fn on_request(r: zap.SimpleRequest) void {
    on_request_internal(r) catch |err| {
        std.debug.print("\n\nERROR: {any}\n", .{err});
    };
}

fn on_request_internal(r: zap.SimpleRequest) !void {
    var path: []const u8 = "/";
    if (r.path) |p| {
        path = p;
    }

    // url
    const url = try std.fmt.allocPrint(allocator, "http://localhost:8000{s}", .{path});

    const uri = try std.Uri.parse(url);

    // http headers
    var h = std.http.Headers{ .allocator = allocator };
    defer h.deinit();
    try h.append("accept", "*/*");
    try h.append("Content-Type", "application/json");

    // client
    var http_client: std.http.Client = .{ .allocator = allocator };
    defer http_client.deinit();

    // request
    var req = try http_client.request(.GET, uri, h, .{});
    defer req.deinit();

    req.transfer_encoding = .chunked;

    // connect, send request
    try req.start();

    // // send POST payload
    // try req.writer().writeAll(message_json);
    // try req.finish();

    // wait for response
    try req.wait();
    var buffer: [1024]u8 = undefined;
    const len = try req.readAll(&buffer);
    std.debug.print("returned response: {s}\n", .{buffer[0..len]});
    r.sendBody(buffer[0..len]) catch return;
}

fn on_request_minimal(r: zap.SimpleRequest) void {
    r.sendBody("<html><body><h1>Hello from ZAP!!!</h1></body></html>") catch return;
}
var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = general_purpose_allocator.allocator();

pub fn main() !void {
    var listener = zap.SimpleHttpListener.init(.{
        .port = 3000,
        .on_request = on_request,
        .log = true,
        .max_clients = 100000,
    });
    try listener.listen();

    std.debug.print(
        \\
        \\ Start a server in a separate shell: 
        \\ 
        \\ python -m http.server
        \\ 
        \\ Then browse http://localhost:3000/...
        \\ 
        \\ Example: http://localhost:3000/src/main.zig
        \\
        \\ It will return whatever the python server returns.
        \\
    , .{});

    // start worker threads
    zap.start(.{
        .threads = 2,
        .workers = 1,
    });
}
