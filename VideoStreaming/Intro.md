# Video ?

Many still images shows very fast, its a collection of images.

### How we represent it in memory

a video is divided into 3 section (in node we treat it as buffer)
1. file type metadata
2. content metadata - to interpret content
3. content

```ts
//read entire data into memory(return a Buffer)
const fs = require("fs");

fs.readFile("video.mp4", (err, data) => {
  console.log(data); // Buffer
});


//stream video , read chunk by chunk default chunk size if 64KB

const stream = fs.createReadStream("video.mp4");
stream.pipe(res);

// we can also provide the rande of chunk to read
fs.createReadStream("video.mp4", { start, end }); // start from this byte till end byte



// if you want to read the metadata of file not video
fs.stat("video.mp4", (err, stats) => {
  console.log(stats.size); // gives the information about a file , creation date , modiication date and file size and more
});

// pipe create a pipe , to send chunk as response , but we have to set the header
res.writeHead(206, headers); //206 status code  means partial data
stream.pipe(res);
```


### 206 

The 206 Partial Content HTTP status code indicates that the server has successfully fulfilled a client's request for only a portion (or range) of a resource. This response is used when the client sends a Range header in its request, specifying the specific byte ranges it needs. 

1. Trigger: A 206 status is returned only when the client includes a Range header in its HTTP GET request and the server supports range requests (indicated by the Accept-Ranges: bytes header in a prior or current response).

2. Required Headers: A 206 response must include a Content-Range header, which specifies the exact range of bytes being delivered and the total size of the resource (e.g., Content-Range: bytes 21010-47021/47022).




```ts
MP4 is nothing but a container that of data, this container contains data (streams)

1. audio stream
2. video stream
3. subtitle
4. metadata to play these  (how to decode )
5. chapters


codec - compression algoithm


```


## Browser receives 
HTTP/1.1 206 Partial Content
Content-Range: bytes 0-1048575/7340032
Content-Type: video/mp4
Content-Length: 1048576


it receives 

[HTTP HEADERS AS TEXT]
\r\n
[BINARY BYTES]


The browser first parses HTTP headers using its network stack.

Only after that does it treat the body as a byte stream.



Content-Type: video/mp4

tells the browser
“Interpret these bytes using the MP4 container parser.”

Without it, the browser wouldn’t know how to decode the binary.


browser receives 00 00 00 18 66 74 79 70 ...

First 4 bytes → box size

Next 4 bytes → box type (ftyp)

moov = content header

browser do adeptive reading , when change or slide video, it notes that range and request to the src to get that data from that chunk , it sends the data header

browser

Network
 ↓
HTTP parser
 ↓
MP4 demuxer (separates audio/video)
 ↓
Decoder (hardware accelerated if available)
 ↓
GPU
 ↓
Screen





❌ Missing Content-Type

Browser may treat it as download.

❌ Wrong Content-Range

Video seeking breaks.

❌ No Accept-Ranges

Seeking disabled.

❌ Corrupted MP4 structure

Parser fails → video won’t play.

1. Browser Requests Bytes (Not “Video”)

<video src="/video" controls></video>

GET /video
Range: bytes=0-1048575

server send 

GET /video
Range: bytes=0-1048575


2. Content-Type Selects the Parser
 without content type browser doesnt know how to parse the current data body


```ts
const express = require("express");
const fs = require("fs");
const path = require("path");
const CHUNK_SIZE = 1 * 1024 * 1024;

const app = express();
const PORT = 3000;

const videoPath = path.join(__dirname, "video.mp4");

app.get("/video", (req, res) => {
  const stat = fs.statSync(videoPath);
  const fileSize = stat.size;// get the total file size
  const range = req.headers.range;//range: bytes=114622464-

  if (!range) {
    return res.status(400).send("Requires Range header");
  }

  const parts = range.replace(/bytes=/, "").split("-");
  const start = parseInt(parts[0], 10);//Interpret "100" as a base-10 (decimal) number.Radix = numbering system base.
  /***
| Base | Name        | Example |
| ---- | ----------- | ------- |
| 2    | Binary      | 1010    |
| 8    | Octal       | 12      |
| 10   | Decimal     | 10      |
| 16   | Hexadecimal | 0xA     |

   */

// if browser provide end , give video till there else give all the data from given point till end
//   const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;//send entire remaining file
  /**
   * note :- dont blindly trust the client , to send the end 
   * specify the chunk size at server 
   * const CHUNK_SIZE = 1 * 1024 * 1024; // 1MB
   */

  const requestedEnd = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;

const end = Math.min(
  start + CHUNK_SIZE - 1, // if the start + chunk size is smaller choose this
  requestedEnd, //if client give range and its small choose this 
  fileSize - 1 //if we have remaining only 2kb choose this
);
  if (start >= fileSize || end >= fileSize) { // if any exceed the limit the size of the file
    return res.status(416).set({
      "Content-Range": `bytes */${fileSize}`
    }).end();
  }

  const chunkSize = end - start + 1;

  res.status(206).set({
    "Content-Range": `bytes ${start}-${end}/${fileSize}`,
    "Accept-Ranges": "bytes",
    "Content-Length": chunkSize, // current chunk size
    "Content-Type": "video/mp4"
  });

  const stream = fs.createReadStream(videoPath, { start, end });
  stream.pipe(res);
});

app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
```



```html
<!DOCTYPE html>
<html>
<head>
  <title>Express Video Stream</title>
</head>
<body>

  <h2>Streaming with Express</h2>

  <video width="720" controls>
    <source src="http://localhost:3000/video" type="video/mp4">
    Your browser does not support video.
  </video>

</body>
</html>
```

