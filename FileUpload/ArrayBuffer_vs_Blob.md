Array vs Blob :- https://stackoverflow.com/questions/11821096/what-is-the-difference-between-an-arraybuffer-and-a-blob


more :- https://medium.com/@nyoman.adi16/base64-vs-arraybuffer-vs-blob-the-battle-of-binary-which-one-should-you-use-9180148d8c38


| ArrayBuffer                              | Blob                                   |
| ---------------------------------------- | -------------------------------------- |
| Editable raw binary memory               | Immutable file-like binary data        |
| Used for processing/manipulating bytes   | Used for storing/transferring files    |
| Needs TypedArray/DataView to access data | Can be used directly with browser APIs |
| Best for WebGL, audio, protocols, crypto | Best for uploads, downloads, media     |

### One-line mental model

```text
ArrayBuffer = binary data for computation
Blob = binary data for storage/transfer
```
