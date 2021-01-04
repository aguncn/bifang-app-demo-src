const http = require('http');

http.createServer(function(request, response) {
  // 设置响应头
  response.writeHeader(200, {
    "Content-Type" : "text/plain"
  });
  // 响应主体为 "Hello world!"
  response.write("Hello Node.js!");
  response.end();
})
// 设置监听端口为9000
.listen(9000);