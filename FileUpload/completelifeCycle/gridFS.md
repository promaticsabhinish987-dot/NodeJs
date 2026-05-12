we have no access to GRIDFS with mongoose.

```ts
//server.js
const express = require("express");
const multer = require("multer");
const { MongoClient, GridFSBucket, ObjectId } = require("mongodb");
const cors = require("cors");

const app = express();

app.use(cors());
app.use(express.json());

const upload = multer({
  storage: multer.memoryStorage()
});

const MONGO_URL = "mongodb://127.0.0.1:27017";
const DB_NAME = "gridfs_demo";

let db;
let bucket;

MongoClient.connect(MONGO_URL)
  .then(client => {

    db = client.db(DB_NAME);

    bucket = new GridFSBucket(db, {
      bucketName: "videos"
    });

    console.log("MongoDB Connected");

  })
  .catch(console.error);





/*
====================================
UPLOAD
====================================
*/

app.post("/upload", upload.single("video"), async (req, res) => {

  try {

    const file = req.file;

    if (!file) {
      return res.status(400).json({
        error: "No file uploaded"
      });
    }

    const uploadStream = bucket.openUploadStream(file.originalname, {
      contentType: file.mimetype
    });

    uploadStream.end(file.buffer);

    uploadStream.on("finish", () => {

      res.json({
        message: "Uploaded",
        fileId: uploadStream.id
      });

    });

  } catch (err) {

    console.log(err);

    res.status(500).json({
      error: "Upload failed"
    });

  }

});





/*
====================================
GET VIDEO STREAM
====================================
*/

app.get("/video/:id", async (req, res) => {

  try {

    const fileId = new ObjectId(req.params.id);

    const files = await db.collection("videos.files").findOne({
      _id: fileId
    });

    if (!files) {
      return res.status(404).send("File not found");
    }

    res.set("Content-Type", files.contentType);

    const downloadStream = bucket.openDownloadStream(fileId);

    downloadStream.pipe(res);

  } catch (err) {

    console.log(err);

    res.status(500).send("Error streaming video");

  }

});





/*
====================================
LIST FILES
====================================
*/

app.get("/files", async (req, res) => {

  try {

    const files = await db.collection("videos.files")
      .find({})
      .toArray();

    res.json(files);

  } catch (err) {

    console.log(err);

    res.status(500).send("Error fetching files");

  }

});





/*
====================================
DELETE FILE
====================================
*/

app.delete("/delete/:id", async (req, res) => {

  try {

    const fileId = new ObjectId(req.params.id);

    await bucket.delete(fileId);

    res.json({
      message: "Deleted"
    });

  } catch (err) {

    console.log(err);

    res.status(500).send("Delete failed");

  }

});





/*
====================================
SERVE FRONTEND
====================================
*/

app.get("/", (req, res) => {

  res.sendFile(__dirname + "/index.html");

});





app.listen(3000, () => {

  console.log("Server running on http://localhost:3000");

});
```



```html
<!DOCTYPE html>
<html>

<head>

  <title>GridFS Demo</title>

</head>

<body>

  <h1>GridFS Video Upload</h1>

  <input type="file" id="fileInput">

  <button onclick="uploadVideo()">
    Upload
  </button>

  <hr>

  <h2>Uploaded Videos</h2>

  <div id="videos"></div>





<script>

async function uploadVideo() {

  const fileInput = document.getElementById("fileInput");

  const file = fileInput.files[0];

  if (!file) {
    return alert("Select file");
  }

  const formData = new FormData();

  formData.append("video", file);

  const response = await fetch("/upload", {
    method: "POST",
    body: formData
  });

  const data = await response.json();

  console.log(data);

  loadVideos();

}





async function loadVideos() {

  const response = await fetch("/files");

  const files = await response.json();

  const container = document.getElementById("videos");

  container.innerHTML = "";

  files.forEach(file => {

    const div = document.createElement("div");

    div.style.marginBottom = "40px";

    div.innerHTML = `
    
      <h3>${file.filename}</h3>

      <video
        width="500"
        controls
        src="/video/${file._id}">
      </video>

      <br><br>

      <button onclick="deleteVideo('${file._id}')">
        Delete
      </button>

      <hr>
    
    `;

    container.appendChild(div);

  });

}





async function deleteVideo(id) {

  await fetch("/delete/" + id, {
    method: "DELETE"
  });

  loadVideos();

}





loadVideos();

</script>

</body>
</html>
```

### Outpur 

will create a database

```
1. gridfs_demo

Two collection

1.1 videos.chunks --> videos is a bucket name
1.2 videos.files --> store metadata of file

```
if we call file with id, it internally fetches all the related chunks and the sort it.



Example

```ts
//videos.files
{
  "_id": {
    "$oid": "6a02b2bbcd717ab48fcc1a9c"
  },
  "length": 15700553,
  "chunkSize": 261120,
  "uploadDate": {
    "$date": "2026-05-12T04:55:23.301Z"
  },
  "filename": "iPhone-13-PRO-www.studentkare.com-5d3wy2zo-ucmt4.webm"
}

```

```ts
//videos.chunks

{
  "_id": {
    "$oid": "6a02b2bbcd717ab48fcc1a9d"
  },
  "files_id": {
    "$oid": "6a02b2bbcd717ab48fcc1a9c"
  },
  "n": 0,
  "data": {
    "$binary": {
      "base64": "GkXfo6NChoEBQveBAULFPcAH7hZEKBywc8t/vdye9BDgQtcwCtIlMAGOEKOoBIOrfgC80SRIwABAJDgIMC7nOQ",
     "subType": "00"
    }
  }
}


//  n is here for serialization

```





# GridFS in MongoDB — First Principles

Think about the core problem first.

---

# 1. The Fundamental Problem

MongoDB stores data as **documents**.

Example:

```json
{
  "name": "abhinish",
  "age": 24
}
```

But documents have a limit:

> Maximum BSON document size = 16 MB

So:

* profile image → okay
* small PDF → okay
* 2GB video → impossible in one document

Now the question becomes:

> How can MongoDB store files larger than 16MB?

That is the birth of **GridFS**.

---

# 2. First Principle Idea

Instead of storing:

```txt
1 huge file
```

MongoDB stores:

```txt
many small chunks
```

Exactly like:

---

## Real World Analogy

Imagine sending a huge movie through postal mail.

You cannot send:

```txt
1 gigantic box
```

because shipping rules reject it.

So you:

1. split movie into many small boxes
2. label them:

   * part 1
   * part 2
   * part 3
3. receiver reassembles them

GridFS does the same thing.

---

# 3. Core Architecture

GridFS uses **two collections**.

---

## Collection 1: `fs.files`

Stores:

> File metadata

Example:

```json
{
  "_id": ObjectId("abc"),
  "filename": "movie.mp4",
  "length": 2000000000,
  "chunkSize": 261120,
  "uploadDate": ISODate(...)
}
```

This is like:

```txt
table of contents
```

It describes the file.

NOT the actual binary data.

---

## Collection 2: `fs.chunks`

Stores:

> Actual binary pieces

Example:

```json
{
  "_id": ObjectId(...),
  "files_id": ObjectId("abc"),
  "n": 0,
  "data": BinData(...)
}
```

Another chunk:

```json
{
  "files_id": ObjectId("abc"),
  "n": 1,
  "data": BinData(...)
}
```

Another:

```json
{
  "files_id": ObjectId("abc"),
  "n": 2,
  "data": BinData(...)
}
```

---

# 4. Understanding the Important Fields

---

## `files_id`

This connects chunk → original file.

Like:

```txt
all chunks belonging to movie.mp4
```

---

## `n`

This is chunk order.

Example:

```txt
n=0 → first chunk
n=1 → second chunk
n=2 → third chunk
```

Without this:

MongoDB cannot rebuild file correctly.

---

## `data`

Actual binary bytes.

This is the raw file data.

---

# 5. What Happens During Upload

Let’s say:

```txt
video.mp4 = 100 MB
```

Default chunk size:

```txt
255 KB
```

MongoDB does:

```txt
100MB
   ↓
split into ~400 chunks
```

Then:

---

## Step 1

Insert metadata into:

```txt
fs.files
```

---

## Step 2

Insert each chunk into:

```txt
fs.chunks
```

Like:

```txt
chunk 0
chunk 1
chunk 2
...
chunk 399
```

---

# 6. What Happens During Download

MongoDB:

---

## Step 1

Reads metadata from:

```txt
fs.files
```

---

## Step 2

Finds all chunks:

```txt
where files_id = file._id
```

---

## Step 3

Sorts by:

```txt
n ascending
```

because order matters.

---

## Step 4

Concatenates bytes:

```txt
chunk0 + chunk1 + chunk2
```

Now original file recreated.

---

# 7. Why GridFS Exists Instead of File System

Excellent first-principle question.

Why not just store file on disk?

Because GridFS gives database-level features.

---

## Benefit 1 — Replication

MongoDB replica sets automatically replicate files.

So file storage becomes:

```txt
fault tolerant
```

---

## Benefit 2 — Sharding

Huge files distributed across machines.

Very useful for:

* video platforms
* media systems
* backups

---

## Benefit 3 — Atomic Metadata

Metadata + file connected in database ecosystem.

Example:

```json
{
  "userId": 123,
  "avatarFileId": "abc"
}
```

Easy querying.

---

## Benefit 4 — Streaming

GridFS streams chunks.

Meaning:

You do NOT load full 5GB file into RAM.

Instead:

```txt
read chunk
send chunk
read next chunk
send next chunk
```

Very memory efficient.

---

# 8. Knowledge Gap — Why Chunking Matters

This is VERY important.

Without chunking:

```txt
large file
   ↓
must fully load into RAM
```

Bad.

Example:

```txt
5GB file
```

Your server may crash.

With GridFS:

```txt
small chunk at a time
```

Memory stays stable.

This is related to:

* streams
* backpressure
* buffering

all connected concepts.

---

# 9. Internal Flow Visualization

```txt
                Upload
                   │
                   ▼
          Split file into chunks
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
   fs.files              fs.chunks
(metadata)            (binary pieces)
```

Download:

```txt
fs.files
   │
find chunk references
   │
fetch fs.chunks
   │
sort by n
   │
merge bytes
   │
stream to client
```

---

# 10. Why Default Chunk Size ≈ 255KB

Tradeoff.

---

## Smaller chunks

Pros:

* lower RAM usage
* easier retry
* better streaming

Cons:

* too many documents
* more database overhead

---

## Larger chunks

Pros:

* fewer documents
* better throughput

Cons:

* more memory
* slower retries

MongoDB chose balanced default.

---
