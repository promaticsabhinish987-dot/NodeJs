# **Image Lifecycle: Client → Server → Storage → Retrieval**

A complete technical journey with precise implementation details.

---

## **PHASE 1: CLIENT-SIDE CAPTURE**

### **1.1 User Selection**

**HTML Input Element:**
```html
<input type="file" accept="image/*" multiple id="imageInput">
```

**What happens internally:**
- Browser opens native file picker dialog
- User selects file(s) from filesystem
- Browser creates **File object** (inherits from Blob)
- File object contains: `name`, `size`, `type`, `lastModified`

**JavaScript receives:**
```javascript
input.addEventListener('change', (e) => {
  const file = e.target.files[0];
  // file is a File object, NOT binary data yet
  // It's a reference, actual bytes still on disk
});
```

### **1.2 Client-Side Validation**

**Before reading bytes, validate metadata:**
```javascript
function validateImage(file) {
  // Type check (unreliable - user can rename .txt to .jpg)
  const validTypes = ['image/jpeg', 'image/png', 'image/webp'];
  if (!validTypes.includes(file.type)) {
    throw new Error('Invalid MIME type');
  }
  
  // Size check (prevents massive uploads)
  const maxSize = 10 * 1024 * 1024; // 10MB
  if (file.size > maxSize) {
    throw new Error('File exceeds 10MB');
  }
  
  return true;
}
```

**Why this matters:** Saves bandwidth. Reject before upload, not after.

### **1.3 Reading File into Memory**

**FileReader API - converts File to usable data:**
```javascript
const reader = new FileReader();

// Method 1: ArrayBuffer (binary data)
reader.readAsArrayBuffer(file);
reader.onload = (e) => {
  const arrayBuffer = e.target.result; // Raw bytes
  const uint8Array = new Uint8Array(arrayBuffer);
  // Now you have actual image bytes
};

// Method 2: Data URL (Base64)
reader.readAsDataURL(file);
reader.onload = (e) => {
  const dataURL = e.target.result;
  // "data:image/jpeg;base64,/9j/4AAQSkZJRg..."
};
```

**Memory impact:**
- Original file: 5MB on disk
- ArrayBuffer in memory: 5MB RAM
- Base64 encoding: 6.67MB (33% larger due to encoding overhead)

### **1.4 Client-Side Preview Generation**

**Create thumbnail without server:**
```javascript
function createPreview(file) {
  return new Promise((resolve) => {
    const img = new Image();
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    
    img.onload = () => {
      // Calculate aspect-ratio-preserving dimensions
      const maxDimension = 200;
      let width = img.width;
      let height = img.height;
      
      if (width > height) {
        if (width > maxDimension) {
          height *= maxDimension / width;
          width = maxDimension;
        }
      } else {
        if (height > maxDimension) {
          width *= maxDimension / height;
          height = maxDimension;
        }
      }
      
      canvas.width = width;
      canvas.height = height;
      ctx.drawImage(img, 0, 0, width, height);
      
      // Convert canvas to Blob (compressed)
      canvas.toBlob((blob) => {
        resolve(blob); // Smaller than original
      }, 'image/jpeg', 0.7); // 70% quality
    };
    
    img.src = URL.createObjectURL(file);
  });
}
```

**What happened:**
1. Decoded JPEG to raw pixels (uncompressed RGB)
2. Drew onto smaller canvas (downsampled)
3. Re-encoded to JPEG at lower quality
4. Result: 5MB → 50KB thumbnail

---

## **PHASE 2: TRANSPORT LAYER**

### **2.1 Encoding Strategies**

**Option A: Multipart Form Data (Binary)**
```javascript
const formData = new FormData();
formData.append('image', file); // File object directly
formData.append('title', 'Profile Picture');

fetch('/upload', {
  method: 'POST',
  body: formData // Browser handles encoding
});
```

**What's transmitted (HTTP wire format):**
```
POST /upload HTTP/1.1
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW

------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="title"

Profile Picture
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="image"; filename="photo.jpg"
Content-Type: image/jpeg

[BINARY JPEG DATA - RAW BYTES]
------WebKitFormBoundary7MA4YWxkTrZu0gW--
```

**Characteristics:**
- Efficient: Sends raw bytes, no encoding overhead
- Boundary delimiter separates parts
- Content-Type header preserves MIME type

**Option B: Base64 JSON Payload**
```javascript
reader.readAsDataURL(file);
reader.onload = async (e) => {
  const base64 = e.target.result.split(',')[1]; // Strip "data:image/jpeg;base64,"
  
  await fetch('/upload', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      image: base64,
      filename: file.name,
      mimetype: file.type
    })
  });
};
```

**What's transmitted:**
```
POST /upload HTTP/1.1
Content-Type: application/json

{
  "image": "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsL...",
  "filename": "photo.jpg",
  "mimetype": "image/jpeg"
}
```

**Trade-offs:**
- 33% larger payload (Base64 overhead)
- Easier to handle in JSON APIs
- Can include metadata in same payload
- Slower parsing on server

### **2.2 Network Transmission**

**TCP/IP Layer:**
1. **Chunking**: Large file split into TCP packets (typically 1460 bytes each)
2. **Sequencing**: Each packet numbered for reassembly
3. **Acknowledgment**: Receiver confirms each packet
4. **Retransmission**: Lost packets resent

**Example: 5MB image:**
- Packets sent: ~3,500 packets
- With packet loss (1%): ~35 retransmissions
- Total time (10 Mbps): ~4 seconds

**HTTP/2 Multiplexing:**
```javascript
// Multiple uploads simultaneously without blocking
Promise.all([
  fetch('/upload', { body: formData1 }),
  fetch('/upload', { body: formData2 }),
  fetch('/upload', { body: formData3 })
]);
// All share single TCP connection, interleaved packets
```

### **2.3 Progress Tracking**

**Monitor upload progress:**
```javascript
const xhr = new XMLHttpRequest();

xhr.upload.addEventListener('progress', (e) => {
  if (e.lengthComputable) {
    const percentComplete = (e.loaded / e.total) * 100;
    console.log(`${percentComplete.toFixed(2)}% uploaded`);
    // e.loaded = bytes sent so far
    // e.total = total bytes to send
  }
});

xhr.open('POST', '/upload');
xhr.send(formData);
```

---

## **PHASE 3: SERVER RECEPTION**

### **3.1 Node.js HTTP Server Receives Stream**

**Raw incoming data (without middleware):**
```javascript
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

**What's in memory:**
- Each chunk: ~16KB Buffer
- Concatenated: Full file in single Buffer
- Memory usage: Equals file size + overhead

### **3.2 Multipart Parsing with Multer**

**Multer middleware handles parsing:**
```javascript
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

**Multer's internal process:**
1. Reads Content-Type boundary
2. Splits stream at boundaries
3. Parses each part's headers
4. Accumulates body into Buffer
5. Attaches to req.file

### **3.3 Disk-Based Storage (Streaming)**

**For large files, avoid memory:**
```javascript
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, '/tmp/uploads');
  },
  filename: (req, file, cb) => {
    // Generate unique filename
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ storage });

app.post('/upload', upload.single('image'), (req, res) => {
  // req.file.path = '/tmp/uploads/image-1234567890.jpg'
  // Image written to disk during upload, not after
  // Memory usage: Constant (streaming buffer ~64KB)
});
```

**Stream flow:**
```
HTTP Stream → Multer → Write Stream → Disk
   (network)    (parse)   (fs.createWriteStream)
```

### **3.4 Server-Side Validation (Deep)**

**MIME type in header is user-controlled. Verify actual format:**
```javascript
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

**Why this matters:**
- User can rename `malicious.exe` to `image.jpg`
- Header says `image/jpeg`, but file is executable
- Sharp reads file signature (first bytes) to detect real format
- JPEG starts with `FF D8 FF`, PNG starts with `89 50 4E 47`

---

## **PHASE 4: TRANSFORMATION**

### **4.1 Image Decoding (Decompression)**

**JPEG decoding process:**
```javascript
const sharp = require('sharp');

// When you call sharp(), it:
// 1. Reads compressed JPEG bytes
// 2. Decodes DCT coefficients
// 3. Reconstructs RGB pixel values
// 4. Stores in uncompressed memory buffer

const pipeline = sharp('photo.jpg');

// At this point: Still compressed
// Memory: ~5MB (file size)

const rawPixels = await pipeline.raw().toBuffer();

// Now: Fully decompressed
// Memory: width × height × channels bytes
// Example: 3024 × 4032 × 3 = 36,578,304 bytes (35MB)
```

**Memory explosion:**
- Compressed JPEG: 5MB
- Decompressed pixels: 35MB (7× larger)
- This is why streaming matters for large images

### **4.2 Resize Operation**

**Downsampling algorithm:**
```javascript
await sharp('large.jpg')
  .resize(800, 600, {
    fit: 'cover', // Crop to exact dimensions
    position: 'center',
    kernel: 'lanczos3' // Resampling algorithm
  })
  .toFile('resized.jpg');
```

**What happens internally:**
1. **Decode source**: 3024×4032 pixels loaded
2. **Calculate crop**: Determine which pixels to keep
3. **Resample**: Use Lanczos3 filter to interpolate new pixel values
   - Reads neighborhood of pixels
   - Applies weighted average
   - Generates smooth output
4. **Encode result**: Compress to JPEG

**Memory during process:**
```
Source buffer:  35MB (3024×4032×3)
Target buffer:   1.4MB (800×600×3)
Working memory: ~50MB (libvips internal buffers)
Peak usage:     ~86MB
```

### **4.3 Format Conversion**

**PNG to WebP (lossy compression):**
```javascript
await sharp('screenshot.png')
  .webp({ quality: 80 })
  .toFile('screenshot.webp');
```

**Process:**
1. Decode PNG (lossless, possibly huge)
2. RGB pixels in memory
3. WebP encoder applies lossy compression
4. Result: 70% smaller file

**Quality vs Size:**
```javascript
// Quality comparison
const sizes = {};

for (const quality of [100, 90, 80, 70, 60]) {
  const info = await sharp('input.jpg')
    .jpeg({ quality })
    .toBuffer({ resolveWithObject: true });
  
  sizes[quality] = info.info.size;
}

// Typical results:
// 100: 5,242,880 bytes
// 90:  2,097,152 bytes (60% reduction, visually lossless)
// 80:  1,048,576 bytes (80% reduction, minor artifacts)
// 70:    786,432 bytes (85% reduction, visible artifacts)
// 60:    524,288 bytes (90% reduction, poor quality)
```

### **4.4 Metadata Extraction & Removal**

**Extract EXIF data:**
```javascript
const metadata = await sharp('photo.jpg').metadata();

// metadata.exif contains camera data
// metadata.icc contains color profile
// metadata.orientation contains rotation

// Privacy: Remove all metadata
await sharp('photo.jpg')
  .rotate() // Auto-rotate based on EXIF orientation
  .withMetadata({
    exif: {}, // Remove EXIF
    icc: sRGB_profile // Keep only color profile
  })
  .toFile('clean.jpg');
```

**Why remove metadata:**
- EXIF contains GPS coordinates (privacy risk)
- Camera make/model (fingerprinting)
- Timestamp (privacy)
- Thumbnail embedded in EXIF (bloat)

### **4.5 Multiple Variants Generation**

**Create responsive image set:**
```javascript
async function generateVariants(sourcePath) {
  const variants = [
    { name: 'thumbnail', width: 150, height: 150 },
    { name: 'small', width: 400, height: null }, // Preserve aspect
    { name: 'medium', width: 800, height: null },
    { name: 'large', width: 1600, height: null }
  ];
  
  const results = await Promise.all(
    variants.map(async (v) => {
      const outputPath = `${v.name}.jpg`;
      
      await sharp(sourcePath)
        .resize(v.width, v.height, {
          fit: v.height ? 'cover' : 'inside',
          withoutEnlargement: true // Don't upscale
        })
        .jpeg({ quality: 85, progressive: true })
        .toFile(outputPath);
      
      return { variant: v.name, path: outputPath };
    })
  );
  
  return results;
}
```

**Progressive JPEG encoding:**
- Standard JPEG: Top-to-bottom rendering
- Progressive: Blurry → Sharp rendering
- Larger file (+5%), better UX

---

## **PHASE 5: STORAGE**

### **5.1 Filesystem Storage**

**Organized directory structure:**
```javascript
const crypto = require('crypto');
const fs = require('fs').promises;
const path = require('path');

async function saveToFilesystem(buffer, originalName) {
  // Generate hash-based ID (prevents collisions)
  const hash = crypto.createHash('sha256')
    .update(buffer)
    .digest('hex');
  
  // Sharding: Prevents too many files in one directory
  // abc123... → ab/c1/abc123...
  const shard1 = hash.substring(0, 2);
  const shard2 = hash.substring(2, 4);
  
  const directory = path.join('/var/images', shard1, shard2);
  await fs.mkdir(directory, { recursive: true });
  
  const ext = path.extname(originalName);
  const filename = `${hash}${ext}`;
  const fullPath = path.join(directory, filename);
  
  await fs.writeFile(fullPath, buffer);
  
  return {
    id: hash,
    path: fullPath,
    url: `/images/${shard1}/${shard2}/${filename}`
  };
}
```

**Why sharding matters:**
- 1,000,000 files in one directory: Slow filesystem operations
- 256 subdirectories (00-ff): ~3,900 files each (manageable)

### **5.2 Database Metadata**

**Store metadata, not binary:**
```javascript
const { Pool } = require('pg');
const pool = new Pool();

async function saveMetadata(imageData, userId) {
  const query = `
    INSERT INTO images (
      id, user_id, original_name, mime_type,
      file_size, width, height, storage_path,
      created_at
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
    RETURNING *
  `;
  
  const values = [
    imageData.id,
    userId,
    imageData.originalName,
    imageData.mimeType,
    imageData.size,
    imageData.width,
    imageData.height,
    imageData.path
  ];
  
  const result = await pool.query(query, values);
  return result.rows[0];
}
```

**Schema design:**
```sql
CREATE TABLE images (
  id VARCHAR(64) PRIMARY KEY, -- SHA256 hash
  user_id INTEGER REFERENCES users(id),
  original_name VARCHAR(255),
  mime_type VARCHAR(50),
  file_size INTEGER, -- Bytes
  width INTEGER,
  height INTEGER,
  storage_path VARCHAR(500), -- Filesystem or S3 key
  variants JSONB, -- {"thumbnail": "path1", "large": "path2"}
  created_at TIMESTAMP DEFAULT NOW(),
  INDEX idx_user_created (user_id, created_at)
);
```

### **5.3 Cloud Storage (S3)**

**Upload to AWS S3:**
```javascript
const AWS = require('aws-sdk');
const s3 = new AWS.S3();

async function uploadToS3(buffer, filename, mimetype) {
  const params = {
    Bucket: 'my-images-bucket',
    Key: `uploads/${Date.now()}-${filename}`, // Unique key
    Body: buffer,
    ContentType: mimetype,
    ACL: 'private', // Not publicly accessible
    Metadata: {
      'uploaded-by': 'nodejs-server',
      'upload-timestamp': new Date().toISOString()
    },
    StorageClass: 'STANDARD', // or 'INTELLIGENT_TIERING'
  };
  
  const result = await s3.upload(params).promise();
  
  return {
    url: result.Location, // S3 URL
    key: result.Key,
    etag: result.ETag // MD5 hash for verification
  };
}
```

**Streaming upload (memory-efficient):**
```javascript
const fs = require('fs');

function uploadLargeFile(filePath) {
  const fileStream = fs.createReadStream(filePath);
  
  const uploadParams = {
    Bucket: 'my-images-bucket',
    Key: path.basename(filePath),
    Body: fileStream
  };
  
  return s3.upload(uploadParams).promise();
  // File streams directly to S3, never fully in RAM
}
```

### **5.4 CDN Integration**

**CloudFront configuration:**
```javascript
// After S3 upload, invalidate CDN cache if image updated
const cloudfront = new AWS.CloudFront();

async function invalidateCDN(imageKey) {
  const params = {
    DistributionId: 'E1234ABCD5678',
    InvalidationBatch: {
      CallerReference: `${Date.now()}`,
      Paths: {
        Quantity: 1,
        Items: [`/uploads/${imageKey}`]
      }
    }
  };
  
  await cloudfront.createInvalidation(params).promise();
}
```

**Serving strategy:**
```
User Request → CloudFront (Edge Location)
                ↓ Cache Miss
            S3 Bucket (Origin)
                ↓
            CloudFront (Cache for 1 year)
                ↓
            User Receives Image
```

---

## **PHASE 6: RETRIEVAL & DELIVERY**

### **6.1 Basic Serving**

**Express route:**
```javascript
app.get('/images/:id', async (req, res) => {
  const { id } = req.params;
  
  // Query database for metadata
  const image = await db.query(
    'SELECT * FROM images WHERE id = $1',
    [id]
  );
  
  if (!image) {
    return res.status(404).send('Image not found');
  }
  
  // Read from filesystem
  const buffer = await fs.readFile(image.storage_path);
  
  // Set correct headers
  res.set({
    'Content-Type': image.mime_type,
    'Content-Length': buffer.length,
    'Cache-Control': 'public, max-age=31536000', // 1 year
    'ETag': `"${image.id}"` // For conditional requests
  });
  
  res.send(buffer);
});
```

### **6.2 Streaming Delivery**

**Memory-efficient serving:**
```javascript
app.get('/images/:id', async (req, res) => {
  const image = await getImageMetadata(req.params.id);
  
  res.set({
    'Content-Type': image.mime_type,
    'Content-Length': image.file_size,
    'Cache-Control': 'public, max-age=31536000'
  });
  
  // Stream file to response
  const fileStream = fs.createReadStream(image.storage_path);
  fileStream.pipe(res);
  
  // Handles backpressure automatically
  // If client slow, stream pauses reading from disk
});
```

### **6.3 Conditional Requests (HTTP 304)**

**Save bandwidth with ETag:**
```javascript
app.get('/images/:id', async (req, res) => {
  const image = await getImageMetadata(req.params.id);
  const etag = `"${image.id}"`;
  
  // Check if client has cached version
  const clientETag = req.get('If-None-Match');
  
  if (clientETag === etag) {
    // Client's cache is still valid
    return res.status(304).end(); // No body sent
  }
  
  // Send full image
  res.set('ETag', etag);
  const buffer = await fs.readFile(image.storage_path);
  res.send(buffer);
});
```

**Bandwidth saved:**
- First request: 5MB downloaded
- Subsequent requests: ~200 bytes (304 response headers)

### **6.4 Range Requests (Partial Content)**

**Support byte-range requests for video/large images:**
```javascript
app.get('/images/:id', async (req, res) => {
  const image = await getImageMetadata(req.params.id);
  const fileSize = image.file_size;
  const range = req.get('Range');
  
  if (range) {
    // Parse "bytes=0-1023"
    const parts = range.replace(/bytes=/, '').split('-');
    const start = parseInt(parts[0], 10);
    const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
    const chunkSize = (end - start) + 1;
    
    res.status(206); // Partial Content
    res.set({
      'Content-Range': `bytes ${start}-${end}/${fileSize}`,
      'Accept-Ranges': 'bytes',
      'Content-Length': chunkSize,
      'Content-Type': image.mime_type
    });
    
    const fileStream = fs.createReadStream(image.storage_path, { start, end });
    fileStream.pipe(res);
  } else {
    // Full file
    res.sendFile(image.storage_path);
  }
});
```

### **6.5 On-Demand Transformation**

**Generate variants at request time:**
```javascript
app.get('/images/:id/:size', async (req, res) => {
  const { id, size } = req.params;
  const image = await getImageMetadata(id);
  
  // Define size presets
  const sizes = {
    thumb: { width: 150, height: 150 },
    medium: { width: 800, height: null },
    large: { width: 1600, height: null }
  };
  
  const dimensions = sizes[size];
  if (!dimensions) {
    return res.status(400).send('Invalid size');
  }
  
  // Check cache
  const cacheKey = `${id}-${size}`;
  const cached = await redis.get(cacheKey);
  if (cached) {
    res.set('Content-Type', 'image/jpeg');
    return res.send(Buffer.from(cached, 'base64'));
  }
  
  // Generate on-the-fly
  const buffer = await sharp(image.storage_path)
    .resize(dimensions.width, dimensions.height, { fit: 'inside' })
    .jpeg({ quality: 85 })
    .toBuffer();
  
  // Cache for 1 hour
  await redis.setex(cacheKey, 3600, buffer.toString('base64'));
  
  res.set('Content-Type', 'image/jpeg');
  res.send(buffer);
});
```

### **6.6 Responsive Images (HTML)**

**Client requests appropriate size:**
```html
<img 
  srcset="
    /images/abc123/thumb 150w,
    /images/abc123/medium 800w,
    /images/abc123/large 1600w
  "
  sizes="
    (max-width: 600px) 150px,
    (max-width: 1200px) 800px,
    1600px
  "
  src="/images/abc123/medium"
  alt="Description"
>
```

**Browser selects:**
- Mobile (375px viewport): Requests 150w variant
- Tablet (768px viewport): Requests 800w variant
- Desktop (1920px viewport): Requests 1600w variant

### **6.7 WebP with Fallback**

**Content negotiation:**
```javascript
app.get('/images/:id', async (req, res) => {
  const image = await getImageMetadata(req.params.id);
  const acceptHeader = req.get('Accept') || '';
  
  // Check if client supports WebP
  const supportsWebP = acceptHeader.includes('image/webp');
  
  let buffer;
  let contentType;
  
  if (supportsWebP) {
    // Serve WebP (smaller)
    buffer = await sharp(image.storage_path)
      .webp({ quality: 80 })
      .toBuffer();
    contentType = 'image/webp';
  } else {
    // Fallback to JPEG
    buffer = await fs.readFile(image.storage_path);
    contentType = image.mime_type;
  }
  
  res.set('Content-Type', contentType);
  res.set('Vary', 'Accept'); // Tell CDN to cache separately
  res.send(buffer);
});
```

---

## **COMPLETE LIFECYCLE SUMMARY**

```
┌─────────────────┐
│  1. CLIENT      │ File object created, validation, preview
├─────────────────┤
│  2. ENCODING    │ FormData (binary) or Base64 (JSON)
├─────────────────┤
│  3. NETWORK     │ TCP packets, HTTP/2 multiplexing
├─────────────────┤
│  4. SERVER RX   │ Stream → Buffer/Disk, multipart parsing
├─────────────────┤
│  5. VALIDATE    │ MIME check, format detection, metadata
├─────────────────┤
│  6. TRANSFORM   │ Decode → Resize → Compress → Variants
├─────────────────┤
│  7. STORAGE     │ Filesystem (sharded), S3, metadata DB
├─────────────────┤
│  8. RETRIEVAL   │ Stream, ETag, ranges, CDN
├─────────────────┤
│  9. CLIENT RX   │ Progressive render, responsive selection
└─────────────────┘
```

Every step matters. Every byte tracked. Every millisecond optimized.
