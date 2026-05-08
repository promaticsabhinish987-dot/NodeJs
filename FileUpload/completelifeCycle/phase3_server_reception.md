
# PHASE 3: SERVER RECEPTION

### 3.1 Node.js HTTP Server Receives Stream

1. we get data in chunks from internet and browser sends the tcp packets in chunks and server also reeives chunks.up
2. upload speed is partially controlled by the kernel backpressure, kernel stores the incoming packets in _socket receive buffer_ , after buffering node js event loop gets notified(chunk received)
3. node js does not get file in request it gets chunks that it can collect and comine to use it as a single file. and its totally event based.


```ts
const http = require('http');

http.createServer((req, res) => {
  // req is a ReadableStream
  // Data arrives in chunks, not all at once
  
  const chunks = [];
  
  req.on('data', (chunk) => {
    // chunk is a Buffer (binary data)
    chunks.push(chunk);
    console.log(`Received ${chunk.length} bytes`);
  });
  
  req.on('end', () => {
    // All chunks received
    const fullBuffer = Buffer.concat(chunks);
    console.log(`Total: ${fullBuffer.length} bytes`);
    
    // fullBuffer contains entire multipart payload
    // Still need to parse boundaries and extract image
  });
});
```

Note:- each chunk is 16kb buffer and concatinated into single buffer.
Pipe it.

```ts
const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();

app.post('/upload', (req, res) => {

  const outputPath = path.join(__dirname, 'video.mp4');

  // Writable stream
  const writeStream = fs.createWriteStream(outputPath);

  req.on('data', (chunk) => {
    console.log('Chunk:', chunk.length);
  });

  // Pipe incoming bytes directly to disk
  req.pipe(writeStream);

  writeStream.on('finish', () => {

    console.log('File saved');

    res.send('Upload complete');
  });

  writeStream.on('error', (err) => {

    console.error(err);

    res.status(500).send('Upload failed');
  });

});

app.listen(3000);
```


### 3.2 Multipart Parsing with Multer

Multer is a multi part stream parser. 


Multer's internal process:

1. Reads Content-Type boundary
2. Splits stream at boundaries
3. Parses each part's headers
4. Accumulates body into Buffer
5. Attaches to req.file


```ts
const multer = require('multer');
const upload = multer({
  storage: multer.memoryStorage(), // Keeps in RAM
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB max
    files: 5 // Max 5 files per request
  },
  fileFilter: (req, file, cb) => {
    // Runs BEFORE file fully uploaded
    // file.mimetype from Content-Type header (untrusted)
    if (!file.mimetype.startsWith('image/')) {
      return cb(new Error('Only images allowed'));
    }
    cb(null, true);
  }
});

app.post('/upload', upload.single('image'), (req, res) => {
  // req.file is populated by multer
  console.log(req.file);
  /*
  {
    fieldname: 'image',
    originalname: 'photo.jpg',
    encoding: '7bit',
    mimetype: 'image/jpeg',
    buffer: <Buffer ff d8 ff e0 00 10 4a 46 49 46...>, // Actual bytes
    size: 5242880 // Bytes
  }
  */
});
```

Q) do parsing only with node js.

```html
<form action="/upload" method="POST" enctype="multipart/form-data">
  <input type="file" name="image">
  <button>Upload</button>
</form>
```

```ts
const express = require('express');
const multer = require('multer');
const fs = require('fs');

const app = express();

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024
  }
});

app.post('/upload', upload.single('image'), (req, res) => {

  console.log(req.file);

  /*
    {
      buffer: <Buffer ...>,
      mimetype: 'image/jpeg',
      size: 12345
    }
  */

  // Save manually
  fs.writeFileSync(
    './saved.jpg',
    req.file.buffer
  );

  res.send('Uploaded');
});

app.listen(3000);
```








#### Ways to store data with multer.

The storage engine defines :- **where file bytes flow after multipart parsing.**

This is the core architecture decision.

- Store data in ?

1. RAM?
2. disk?
3. cloud?
4. custom stream?
5. database?
6. compression pipeline?


##### **Multer has two buld in storage engines.**

| Storage Engine    | Stores Where     | Memory Usage | Best For              |
| ----------------- | ---------------- | ------------ | --------------------- |
| `memoryStorage()` | RAM Buffer       | High         | Small temporary files |
| `diskStorage()`   | Local filesystem | Low          | Large uploads         |


##### 1. memoryStorage()

Stores entire file in RAM.

Example

```ts
const multer = require('multer');

const upload = multer({
  storage: multer.memoryStorage()
});
```


```ts
req.file = {
  fieldname: 'image',
  originalname: 'cat.jpg',
  mimetype: 'image/jpeg',
  size: 12345,

  // Entire file in RAM
  buffer: <Buffer ff d8 ff e0 ...>
}
```

```ts
req.file.buffer
```

**a contiguous binary memory allocation exists inside Node.js heap/external memory.**

Large uploads become dangerous.


##### use when 

small images
immediate processing
temporary transformations
uploading directly to S3
image resizing in memory


without disk write, like if you dont have to store it in disk use it.

##### 2. diskStorage()

Writes directly to filesystem.

Example


```ts
const path = require('path');
const multer = require('multer');

const storage = multer.diskStorage({

  destination(req, file, cb) {
    cb(null, './uploads');
  },

  filename(req, file, cb) {

    const unique =
      Date.now() + '-' + Math.random();

    cb(
      null,
      unique + path.extname(file.originalname)
    );
  }
});

const upload = multer({ storage });

```

files are stored in chunks , not 1st put all file in buffer. it takes a chunk create buffer then relese it to destination file location.


```ts
req.file = {
  destination: './uploads',
  filename: '12345.jpg',
  path: 'uploads/12345.jpg',
  size: 55555
}
```

##### Where file should be written


```ts
destination(req, file, cb) {

  if (file.mimetype.startsWith('image/')) {
    cb(null, './images');
  } else {
    cb(null, './others');
  }
}
```

we can categorise the files with type. by creating different folder.

multer uses internally.

```ts
fs.createWriteStream(destinationPath)
```


##### filename define the name of the file we will store for this data.



In production for uniqueness

```
UUID + timestamp + extension

example

f81d4fae-7dec-11d0-a765.jpg
```


##### fileFilter() — Security Gate

it tells should the multer accept the incoming file or not., and file.mimetype comes from header attacker can change it. not trust it alone.


```ts
const upload = multer({

  storage,

  fileFilter(req, file, cb) {

    if (!file.mimetype.startsWith('image/')) {
      return cb(new Error('Images only'));
    }

    cb(null, true);
  }
});
```

##### limits - protects server resources.


```ts
const upload = multer({

  storage,

  limits: {
    fileSize: 5 * 1024 * 1024,
    files: 3,
    fields: 10
  }
});
```

Multer/Busboy monitors:

1. bytes received
2. number of files
3. number of form fields


```
multer({

  storage,
  dest,
  limits,
  fileFilter,
  preservePath
})
```

### 3.4 Server-Side Validation (Deep)


MIME type in header is user-controlled. Verify actual format:


```ts
const sharp = require('sharp');

async function validateImageFormat(filePath) {
  try {
    const metadata = await sharp(filePath).metadata();
    
    // metadata contains:
    // {
    //   format: 'jpeg', // Actual format by reading file signature
    //   width: 3024,
    //   height: 4032,
    //   space: 'srgb',
    //   channels: 3,
    //   depth: 'uchar',
    //   density: 72,
    //   hasAlpha: false
    // }
    
    // Verify dimensions aren't extreme (decompression bombs)
    if (metadata.width > 10000 || metadata.height > 10000) {
      throw new Error('Image dimensions too large');
    }
    
    // Verify format matches claim
    const allowedFormats = ['jpeg', 'png', 'webp'];
    if (!allowedFormats.includes(metadata.format)) {
      throw new Error(`Invalid format: ${metadata.format}`);
    }
    
    return metadata;
  } catch (err) {
    // File is corrupted or not an image
    throw new Error('Invalid image file');
  }
}
```


1. User can rename malicious.exe to image.jpg
2. Header says image/jpeg, but file is executable
3. Sharp reads file signature (first bytes) to detect real format
4. JPEG starts with FF D8 FF, PNG starts with 89 50 4E 47


































## Till now

```html
<script>

const fileInput = document.getElementById("fileInput");
const preview = document.getElementById("preview");
const progressBar = document.getElementById("progressBar");
const status = document.getElementById("status");

fileInput.addEventListener("change", async () => {

  const file = fileInput.files[0];

  if (!file) return;

  // =========================
  // MIME TYPE VALIDATION
  // =========================

  const allowed = [
    "image/png",
    "image/jpeg"
  ];

  if (!allowed.includes(file.type)) {

    status.textContent =
      "Invalid image format";

    return;
  }

  // =========================
  // FILE SIZE VALIDATION
  // =========================

  /*
    file.size is in bytes
  */

  const MAX_SIZE =
    2 * 1024 * 1024; // 2MB

  if (file.size > MAX_SIZE) {

    status.textContent =
      "Image size exceeds 2MB";

    return;
  }

  // =========================
  // CREATE OBJECT URL
  // =========================

  const imageURL =
    URL.createObjectURL(file);

  // =========================
  // IMAGE DIMENSION VALIDATION
  // =========================

  const img = new Image();

  img.src = imageURL;

  img.onload = () => {

    const width = img.width;
    const height = img.height;

    console.log("Width:", width);
    console.log("Height:", height);

    /*
      Example validation:
      minimum 300x300
      maximum 2000x2000
    */

    if (
      width < 300 ||
      height < 300
    ) {

      status.textContent =
        "Image dimensions too small";

      URL.revokeObjectURL(imageURL);

      return;
    }

    if (
      width > 2000 ||
      height > 2000
    ) {

      status.textContent =
        "Image dimensions too large";

      URL.revokeObjectURL(imageURL);

      return;
    }

    // =========================
    // PREVIEW IMAGE
    // =========================

    preview.src = imageURL;
    preview.style.display = "block";

    // =========================
    // FORM DATA
    // =========================

    const formData = new FormData();

    formData.append("image", file);

    formData.append(
      "title",
      "Profile Picture"
    );

    // =========================
    // XHR
    // =========================

    const xhr = new XMLHttpRequest();

    xhr.upload.addEventListener(
      "progress",
      (e) => {

        if (e.lengthComputable) {

          const percent =
            (e.loaded / e.total) * 100;

          progressBar.value = percent;

          status.textContent =
            percent.toFixed(2) +
            "% uploaded";
        }

      }
    );

    xhr.onload = () => {

      if (xhr.status === 200) {

        status.textContent =
          "Upload completed";

      } else {

        status.textContent =
          "Upload failed";
      }

      URL.revokeObjectURL(imageURL);

    };

    xhr.onerror = () => {

      status.textContent =
        "Network error";
    };

    xhr.open(
      "POST",
      "/upload"
    );

    xhr.send(formData);

  };

  img.onerror = () => {

    status.textContent =
      "Failed to read image";

    URL.revokeObjectURL(imageURL);

  };

});

</script>
```



Note :- The URL **revokeObjectURL()** method releases an existing object URL which was created by using URL createObjectURL(). This method is called when you are finished using an object URL and don't want the browser to keep the reference to that file any longer.

```
Parameters :- objectURL: A DOMString object URL to be released.
```

#### Why?

URL.createObjectURL() creates a temporary in-memory URL that points to a Blob, File, or MediaSource. its not real internet url.
blob url  ---> actual binary data in memory.


so if we not clear it it will acumulate and ocupy more memory.

=> When you assign a blob URL to img.src, the browser uses that temporary URL to locate the binary image data stored in memory, reads the bytes, decodes formats like JPEG or PNG into raw pixel data, uploads or stores the decoded bitmap inside the rendering engine/GPU buffer, and finally paints the image on the screen. After decoding completes, the <img> element no longer depends on the original blob URL because it is now rendering from the already-decoded pixel buffer, so calling URL.revokeObjectURL(url) safely removes only the temporary blob URL reference while the displayed image continues to work normally.

















