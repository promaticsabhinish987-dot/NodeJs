## Components

1. Video
2. Server
3. Client
4. Chunk - with slip (header)
5. Stream - convayer belt
6. http verb - to signal action (status code)
7. Nodejs methods that simulate these things.


### 1. Video (mp4 is a structured container)


```
+----------------------------------------------------------------------------------+
|                              VIDEO STORED IN MEMORY                              |
+----------------------------------------------------------------------------------+

Memory Address →
0x0000                                                                     0xFFFF

+-------------------+------------------------+-----------------------------+
| FILE METADATA     | CONTENT METADATA       | ACTUAL CONTENT              |
|-------------------|------------------------|-----------------------------|
| File Type: mp4    | Codec: H.264           | [Binary Video Frames]       |
| Size: 7340032 B   | Resolution: 1920x1080  | 00 00 00 18 66 74 79 70 ... |
| Created: TS       | FPS: 30                | 00 00 02 AF ...             |
| Modified: TS      | Audio Codec: AAC       | 00 00 03 B2 ...             |
+-------------------+------------------------+-----------------------------+
```

mp4 file is divivde into 

```
+----------------+----------------+----------------+
| ftyp           | moov           | mdat           |
| (file type)    | (metadata)     | (media data)   |
+----------------+----------------+----------------+
```

ONE CHUNK fetches 

```
[ftyp + partial moov]
```

Rangeoperates on Byte offset.

```ts
const stream = fs.createReadStream(videoPath, { start, end });
```
returns the raw butes from the disk.


Summary :- video is stored with metadata and raw data and with offset , if we give offset to it, it will give chunk with that offset, a chunk contains the ftype and raw video data. Think it as warhouse, containing self , and each self has data. and we request the range of self like 10000 to 20000 and it will give that , and it has also default chunk size and we can also define our own chunksize. 

Note:-  we handle the edge case , like last chunk. (valid chunk size), if chunk size is greater then file size. return min. 



### 2. server (worker)

Server is a worker that reds client request and thecks their slip(header), it must have things like 

```
Content-Range :bytes 10000-20000/1000000
Content-Type : video/mp4
```

Worker does.

1. Reads request
2. Goes to exact shelf
3. Picks only requiredportion
4. Sends it (chunk,with slip and status code)


Streaming :- ondemand warehouse extraction system.

| Node Feature | Real-world role       |
| ------------ | --------------------- |
| Buffer       | holding a box in hand |
| Stream       | conveyor belt         |
| Range        | precise shelf address |
| Headers      | delivery receipt      |
| 206 status   | partial shipment      |


Summary :- server is a worker working for a warehouse and reads the request of client and fetch the chunk with offset from 
the warehouse and return it with the slip,and status code and raw data.


```ts
const express = require("express");
const fs = require("fs");
const path = require("path");

const app = express();
const PORT = 3000;

const videoPath = path.join(__dirname, "video.mp4");

// control chunk size (1MB)
const CHUNK_SIZE = 1 * 1024 * 1024;

app.get("/video", (req, res) => {
  try {
    const stat = fs.statSync(videoPath);
    const fileSize = stat.size;
    const range = req.headers.range;

    // ==============================
    // 🔹 CASE 1: No Range → send full file (200)
    // ==============================
    if (!range) {
      res.writeHead(200, {
        "Content-Length": fileSize,
        "Content-Type": "video/mp4",
        "Accept-Ranges": "bytes",
      });

      fs.createReadStream(videoPath).pipe(res);
      return;
    }

    // ==============================
    // 🔹 CASE 2: Parse Range
    // ==============================
    const parts = range.replace(/bytes=/, "").split("-");
    const start = parseInt(parts[0], 10);

    // if client doesn't send end → we control chunk size
    const requestedEnd = parts[1]
      ? parseInt(parts[1], 10)
      : fileSize - 1;

    const end = Math.min(
      start + CHUNK_SIZE - 1,
      requestedEnd,
      fileSize - 1
    );

    // ==============================
    // 🔹 CASE 3: Invalid Range → 416
    // ==============================
    if (
      isNaN(start) ||
      start < 0 ||
      start >= fileSize ||
      end >= fileSize
    ) {
      res.status(416).set({
        "Content-Range": `bytes */${fileSize}`,
      });
      return res.end();
    }

    const chunkSize = end - start + 1;

    // ==============================
    // 🔹 CASE 4: Valid Range → 206
    // ==============================
    res.writeHead(206, {
      "Content-Range": `bytes ${start}-${end}/${fileSize}`,
      "Accept-Ranges": "bytes",
      "Content-Length": chunkSize,
      "Content-Type": "video/mp4",
    });

    const stream = fs.createReadStream(videoPath, { start, end });

    stream.pipe(res);

    // ==============================
    // 🔹 ERROR HANDLING (important)
    // ==============================
    stream.on("error", (err) => {
      console.error("Stream error:", err);
      res.end(err);
    });

  } catch (err) {
    console.error("Server error:", err);
    res.status(500).send("Internal Server Error");
  }
});

app.listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
```













