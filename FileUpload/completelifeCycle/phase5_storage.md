## Storage system

multer provide two ways to store image and other file.

1. in ram with memoryStorage --> we get req.file.buffer -- raw binary to use
2. in disk (file system) with diskStorage -- we get req.file.imageName


### Limitation 

we can not store image or binary data in ram and in disk, and not in our app database.

```
Binary data and related metadata must be stored separately. We can not store binary data in the app infra, not in ram, not in filesystem , not in db.
```

### What are the other option 

#### S3 cloud storage is the best place to store our image and other file.

it gives us a bucket and we can generate a unique image id and store that in s3 with the image binary and then we can get the image with that url.

```
npm install express multer aws-sdk
```

Note :- we can also use stream to decrease the Ram load.

#### upload to s3


S3 objects are identified with 

```
Bucket + Key
```



```ts
const express = require('express');
const multer = require('multer');
const AWS = require('aws-sdk');

const app = express();


// ----------------------------------
// AWS CONFIG
// ----------------------------------

AWS.config.update({

  accessKeyId: 'YOUR_ACCESS_KEY',

  secretAccessKey: 'YOUR_SECRET_KEY',

  region: 'ap-south-1'
});

const s3 = new AWS.S3();


// ----------------------------------
// MULTER
// ----------------------------------

const upload = multer({
  storage: multer.memoryStorage()
});


// ----------------------------------
// ROUTE
// ----------------------------------

app.post(
  '/upload',
  upload.single('image'),

  async (req, res) => {

    try {

      // File from multer
      const file = req.file;

      console.log(file);

      /*
      {
        originalname,
        mimetype,
        buffer,
        size
      }
      */


      // --------------------------
      // S3 Upload Parameters
      // --------------------------

      const params = {

        Bucket: 'my-image-bucket',

        Key: `images/${Date.now()}-${file.originalname}`,

        Body: file.buffer,

        ContentType: file.mimetype
      };


      // --------------------------
      // Upload To S3
      // --------------------------

      const result =
        await s3.upload(params).promise();


      // --------------------------
      // Response
      // --------------------------

      res.json({

        success: true,

        url: result.Location
      });

    }

    catch (err) {

      console.error(err);

      res.status(500).json({
        error: 'Upload failed'
      });
    }
  }
);


app.listen(3000, () => {
  console.log('Server running');
});
```

Result Object

```ts
{
  Location: 'https://bucket.s3.amazonaws.com/image.jpg',

  Key: 'images/123-cat.jpg',  //unique object odentifier

  Bucket: 'my-image-bucket' // where obejct shoudl live 
}
```

#### delete from s3

We have to provide the bucket and the key to uniquely identify the object.

```ts
const AWS = require('aws-sdk');

AWS.config.update({

  accessKeyId: 'YOUR_ACCESS_KEY',

  secretAccessKey: 'YOUR_SECRET_KEY',

  region: 'ap-south-1'
});

const s3 = new AWS.S3();

async function deleteImage() {

  try {

    const params = {

      Bucket: 'my-image-bucket',

      Key: 'images/cat.jpg'
    };

    const result =
      await s3.deleteObject(params).promise();

    console.log('Deleted');

    console.log(result);

  }

  catch (err) {

    console.error(err);
  }
}

deleteImage();

```
```
PORT=3000

AWS_ACCESS_KEY_ID=YOUR_KEY
AWS_SECRET_ACCESS_KEY=YOUR_SECRET
AWS_REGION=ap-south-1

S3_BUCKET=my-image-bucket

DATABASE_URL=postgresql://postgres:password@localhost:5432/imagesdb
```

```ts
{
  id: "c9f2d1",

  original_name: "cat.jpg",

  mime_type: "image/webp",

  width: 1200,

  height: 800,

  file_size: 345678,

  storage_key: "images/c9f2d1.webp", // help to delete the object from s3

  image_url:
    "https://cdn.example.com/images/c9f2d1.webp", // for fetching the image from frontend

  created_at: "2026-05-11"
}
```



## What if  we dont what to store in s3 and have mongodb databse 

use different database just to store the image or other file. 


# Storing Binary Data in MongoDB with Mongoose

There are **3 major ways** to store binary data in MongoDB:

| Method        | Best For                 | Internal Storage  |
| ------------- | ------------------------ | ----------------- |
| `Buffer`      | small files/images       | BSON Binary field |
| `GridFS`      | large files/videos       | chunked storage   |
| Base64 string | almost never recommended | text string       |

---

# 1. Using `Buffer` (Direct Binary Storage)

Best for:

* profile images
* PDFs
* thumbnails
* small uploads (<16MB)

MongoDB BSON supports native binary types.

---

## Schema

```js
const mongoose = require("mongoose");

const fileSchema = new mongoose.Schema({
  filename: String,

  data: Buffer,

  contentType: String,

  size: Number
});

module.exports = mongoose.model("File", fileSchema);
```

---

# Uploading Binary Data

Example with Node.js + Express + Multer.

Install:

```bash
npm install express mongoose multer
```

---

## Multer Memory Storage

```js
const multer = require("multer");

const storage = multer.memoryStorage();

const upload = multer({ storage });
```

`memoryStorage()` means:

```txt
file uploaded
    ↓
stored in RAM as Buffer
    ↓
available in req.file.buffer
```

---

# Saving to MongoDB

```js
const express = require("express");
const mongoose = require("mongoose");
const upload = require("./upload");
const File = require("./File");

const app = express();

mongoose.connect("mongodb://127.0.0.1:27017/test");

app.post("/upload", upload.single("file"), async (req, res) => {

  const file = await File.create({
    filename: req.file.originalname,
    data: req.file.buffer,
    contentType: req.file.mimetype,
    size: req.file.size
  });

  res.json({
    id: file._id
  });
});

app.listen(3000);
```

---

# Retrieving Binary Data

```js
app.get("/file/:id", async (req, res) => {

  const file = await File.findById(req.params.id);

  res.set("Content-Type", file.contentType);

  res.send(file.data);
});
```

Browser receives raw bytes:

```txt
MongoDB BSON Binary
        ↓
Node Buffer
        ↓
HTTP Response
        ↓
Browser decodes bytes
```

---

# What Happens Internally

When you save:

```js
data: req.file.buffer
```

Internally:

```txt
File uploaded
    ↓
OS socket receives TCP packets
    ↓
Node assembles bytes
    ↓
Multer creates Buffer
    ↓
Mongoose serializes Buffer
    ↓
MongoDB BSON Binary type
    ↓
stored inside document
```

MongoDB stores binary as:

```bson
BinData(subtype, raw bytes)
```

Not as text.

---

# BSON Binary vs Base64

## Buffer (GOOD)

```js
data: Buffer
```

Stored as raw bytes.

Efficient.

---

## Base64 (BAD)

```js
data: "iVBORw0KGgoAAA..."
```

Problems:

* 33% larger
* extra encoding/decoding
* memory overhead
* slower transmission

Use only when absolutely necessary.

---

# MongoDB Document Size Limit

MongoDB document limit:

```txt
16MB per document
```

So:

* small files → Buffer
* large files → GridFS

---

We not need to parse the bunary data img automatically parse it in browser with content type.

```html
<img src="http://localhost:3000/image/123" />
```

browser parses it automatically.

For other purpose we can manullay parse it and can create a url.


```ts
//download file in frontend

const response = await fetch("/file/123");

const blob = await response.blob();

const url = URL.createObjectURL(blob);

const a = document.createElement("a");

a.href = url;

a.download = "file.pdf";

a.click();

URL.revokeObjectURL(url);
```


## GridFS






































