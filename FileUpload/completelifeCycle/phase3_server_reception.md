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

















