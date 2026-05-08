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
