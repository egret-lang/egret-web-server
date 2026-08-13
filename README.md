# egret-web-server

`egret-web-server` is a powerful and high-performance web server using egret-lang. Powered by https://egret-lang.org.

It supports the common configuration shape:

- `worker_processes`
- `events { worker_connections }`
- `http { client_max_body_size keepalive_timeout gzip gzip_min_length server { ... } }`
- `server { listen server_name root index ssl_certificate ssl_certificate_key rewrite location }`
- `location { root alias index try_files proxy_pass proxy_set_header }`
- common nginx directives such as `user`, `error_log`, `pid`, `include`, `sendfile`, `tcp_nopush`, `tcp_nodelay`, `types_hash_max_size`, `default_type`, `access_log`, `log_format`, `error_page`, and TLS session/cipher directives are parsed and safely skipped when they do not affect this example server.
- `proxy_pass https://...` for HTTPS upstreams via `aio::tls`

Runtime model:

- The parent process creates the listening socket first.
- On Unix-like systems it forks worker processes, and each worker accepts from the inherited listening socket.
- On Windows, where `fork` is not available, it falls back to one AIO worker in the current process.
- Per-connection work is handled with AIO tasks.
- Static text/json/js responses can be sent with `Content-Encoding: gzip` when the client advertises `Accept-Encoding: gzip`.
- Multiple `server` blocks and multiple `listen` directives per `http` config can be parsed. Distinct HTTP/HTTPS sockets are started and duplicate listen sockets are skipped.
- Simple nginx-style rewrites like `rewrite ^/p/(.*)$ /page.html?cid=$1 last;` are applied before location matching.
- Server-side HTTPS uses runtime `aio::tls::listen`/`aio::tls::accept`, loads PEM certificate/key files, and performs the TLS handshake asynchronously. HTTPS upstream proxying works through `aio::tls::connect`.

Commands:

If you haven't installed egret-lang yet, please install it first.
```sh
curl -fsSL https://egret-lang.org/install.sh | sh
```

Then build the server.
```sh
cd egret-web-server_source_directory
egret build
```

After building, you can run the server with:

```sh
./build/egret-web-server -c ./conf/web.conf
```
