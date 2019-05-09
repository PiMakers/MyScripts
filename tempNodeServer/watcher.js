var sys = require('sys');

var filename = process.argv[2];

console.log("filename= ", filename);

if (!filename)

  return sys.puts("Usage: node watcher.js filename");

// Look at http://nodejs.org/api.html#_ces for detail.
var tail = process.createChildProcess("tail", ["-f", filename]);
sys.puts("start tailing");

tail.addListener("output", function (data) {
  sys.puts(data);
});

// From nodejs.org/jsconf.pdf slide 56
var http = require("http");
http.createServer(function(req,res){
  res.sendHeader(200,{"Content-Type": "text/plain"});
  tail.addListener("output", function (data) {
    res.sendBody(data);
  });
}).listen(8000);s