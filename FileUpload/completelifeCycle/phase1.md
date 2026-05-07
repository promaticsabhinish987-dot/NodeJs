
## 1. <input type="file"> 

is an HTML form control used to let users select files from their device.

```html
<input type="file">
```

It opens anative browser file picker.

It does not directly return file contents. It returns **File Object**(information about the selected file but the file data is still in the disk).
We can access File Object through **input.files**.


```
User selects file
        ↓
Browser creates File object (when you click open after file selection)
        ↓
JS accesses file metadata/content  (like file name , size and more)
        ↓
Upload / preview / process (you can do)
```


#### File Object 

Each selected file become file object.


```
Blob
  ↑
File


// file is inherited from Blob

so file is


Blob + metadata of selected file.
```

A **Blob** (Binary Large Object) is a high-level object used to represent binary data, like a file. It can contain both binary data and associated metadata, such as the MIME type (e.g., image/jpeg or application/pdf), making it ideal for handling file-like objects


#### How we can access selected files.

```html
<input type="file" id="fileInput">
```
```ts
const input = document.getElementById("fileInput");

input.addEventListener("change", (e) => {
  console.log(e.target.files);
});
```

```
1. input.files

return the array like object of selected files.

2. const file = input.files[0]; // access first file

3. get metada of file

console.log(file.name);
console.log(file.size);
console.log(file.type);
console.log(file.lastModified);

name         → photo.png
size         → 245000
type         → image/png
lastModified → timestamp

```


Note : File Is NOT File Content

This is critical.

File object initially contains:

- metadata
- handle/reference

Actual bytes are read later.



#### Now we have file how we can read the content of it.

```
options


FileReader
blob.text()
blob.arrayBuffer()
URL.createObjectURL()
```
1. We can read a file as text.

2. read as Binary

3. Read as Data URL -- useful for image preview

differet ways to do it

```ts
const reader = new FileReader();

reader.onload = () => {
  console.log(reader.result);
};

reader.readAsDataURL(file);
```


```html
<input type="file" id="imgInput">
<img id="preview">
```
```ts
// image preview

imgInput.addEventListener("change", () => {
  const file = imgInput.files[0];

  const url = URL.createObjectURL(file);

  preview.src = url;
});

```

#### Multiple file selection 

```html
<input type="file" multiple>
```

#### Restrict selected file formet

```html
<input type="file" accept="image/*">
```

it decides what to show to user to select.

```
accept="image/*"  // imagesonly

accept=".pdf"  // pdf only

accept=".jpg,.png,.pdf" // accept multiple types
```

#### Capture attribute to capture the image 

```html
<input type="file" accept="image/*" capture>
```
We use it mostly in phone, it opens camera or microphone.


#### clear uploaded file 

```ts
input.value = "";
```

```html
<!DOCTYPE html>
<html lang="en">
<head>
   <meta charset="UTF-8">
   <meta name="viewport" content="width=device-width, initial-scale=1.0">
   <title>Document</title>
</head>
<body>
   <input type="file" accept=".png" multiple id="imageInput" >
<img id="preview">
   

   <script>
      let input=document.getElementById("imageInput");

      input.addEventListener("change",async (e)=>{
         console.log(e.target.files);

     const file = await e.target.files[0]
         const text = await file.text();

       console.log(text);//

       const buffer = await file.arrayBuffer();

       console.log(buffer)//ArrayBuffer(1575166)

       //preview
       const img=document.getElementById("preview");
       const url=URL.createObjectURL(file);
       img.src=url;


      });

      // read file as text

      
   </script>
</body>
</html>
```


| Need | Method | Reason |
|---|---|---|
| Upload to server | `arrayBuffer()` | Send raw binary bytes |
| Preview in `<img>` | `URL.createObjectURL()` | No Base64 encoding overhead |
| Send in JSON API | `readAsDataURL()` | JSON requires string data |
| Manipulate bytes | `arrayBuffer()` | Gives TypedArray/DataView access |
| Read text file | `text()` | Direct string conversion |
| Stream huge file | `stream()` | Memory efficient |
| Slice partial file | `slice()` | Avoid loading full file |
| Download generated file | `Blob + createObjectURL()` | Browser-friendly file handling |
| Canvas/WebGL processing | `arrayBuffer()` | Raw binary access required |
| Display PDF/video/audio | `createObjectURL()` | Native browser media support |


## 2. Example 

```html
<!DOCTYPE html>
<html>
<head>
  <title>File Upload</title>
</head>
<body>

<input type="file" id="fileInput" accept="image/png,image/jpeg">

<br><br>

<img 
  id="preview" 
  width="300" 
  style="display:none; object-fit:cover;"
>

<br><br>

<progress id="progressBar" value="0" max="100"></progress>

<p id="message"></p>

<script>

const input = document.getElementById("fileInput");
const preview = document.getElementById("preview");
const progressBar = document.getElementById("progressBar");
const message = document.getElementById("message");

const allowedFormats = [
  "image/png",
  "image/jpeg"
];

const minWidth = 300;
const minHeight = 300;

input.addEventListener("change", () => {

  const file = input.files[0];

  if (!file) return;

  message.textContent = "";
  progressBar.value = 0;

  // FORMAT VALIDATION
  if (!allowedFormats.includes(file.type)) {

    message.textContent = "Invalid file format";

    input.value = "";

    return;
  }

  // OBJECT URL
  const imageURL = URL.createObjectURL(file);

  // IMAGE FOR DIMENSION CHECK
  const img = new Image();

  img.src = imageURL;

  img.onload = () => {

    // DIMENSION VALIDATION
    if (
      img.width < minWidth ||
      img.height < minHeight
    ) {

      message.textContent =
        `Image must be at least ${minWidth}x${minHeight}`;

      URL.revokeObjectURL(imageURL);

      input.value = "";

      return;
    }

    // PREVIEW
    preview.src = imageURL;
    preview.style.display = "block";

    // FAKE PROGRESS DEMO
    let progress = 0;

    const interval = setInterval(() => {

      progress += 10;

      progressBar.value = progress;

      if (progress >= 100) {

        clearInterval(interval);

        message.textContent = "File ready";
      }

    }, 100);

  };

});

</script>

</body>
</html>
```






