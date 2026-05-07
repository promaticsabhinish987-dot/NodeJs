
## PHASE 2: TRANSPORT LAYER


```
User selected file
↓
Browser created File object
```

Now the browser must move the file: from browser to server 

```
Browser → Network → Server
```

This is the transport phase.

---

## 2.1 Encoding Strategies

because we cant send the image directly to the server, we must encode it to **HTTP request body**

---

### Option A: Multipart Form Data (Binary)

```ts
const formData = new FormData();

formData.append('image', file); // File object directly

// browser convert it to multipart/form-data (special http formet)

formData.append('title', 'Profile Picture');

fetch('/upload', {
  method: 'POST',
  body: formData // Browser handles encoding
});
```

---

### Note

multiple separate parts --> multi part

multiple formet in single request

---

### Option B: Base64 JSON Payload

```ts
reader.readAsDataURL(file);

reader.onload = async (e) => {

  const base64 = e.target.result.split(',')[1];

  // Strip "data:image/jpeg;base64,"
  
  await fetch('/upload', {

    method: 'POST',

    headers: {
      'Content-Type': 'application/json'
    },

    body: JSON.stringify({
      image: base64,
      filename: file.name,
      mimetype: file.type
    })

  });

};
```

---

### Tradeoffs

- 33% larger payload (Base64 overhead)
- Easier to handle in JSON APIs

---

### Browser internal flow

```
File object
    ↓
Browser opens file stream
    ↓
Reads bytes progressively
    ↓
Adds multipart boundaries
    ↓
Sends chunks to network layer
```

---

Base64 converts binary into:

safe ASCII characters, becasue json support string not a raw binary.

---

## 2.2 Network Transmission

Internet cannot send giant blobs at once.

Routers handle small chunks.

---

### Multiplexing

multiple file send and then collect.

```ts
Promise.all([
  fetch('/upload', { body: formData1 }),
  fetch('/upload', { body: formData2 }),
  fetch('/upload', { body: formData3 })
]);
```

---

## 2.3 Progress Tracking

fetch() lacks direct upload progress events.

So production systems often use:

XMLHttpRequest (XHR)

```ts
const xhr = new XMLHttpRequest();

xhr.upload.addEventListener('progress', (e) => {

  if (e.lengthComputable) {

    const percent =
      (e.loaded / e.total) * 100;

    console.log(percent);

  }

});
```

---

as browser send the chunks the ,

**Browser counts transmitted bytes**

bytes sent from browser,

not the server receive.

