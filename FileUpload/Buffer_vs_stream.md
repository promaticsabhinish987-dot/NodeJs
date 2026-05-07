(stream vs buffer) :- https://medium.com/globant/node-js-buffer-vs-stream-e2c23df543c1


Validation(joi) :- https://medium.com/@semajprimm/validate-user-input-in-a-node-js-express-api-a74e202a3424

A computer can only understand binary data, that is, data in the form of 0’s and 1’s. The sequential movement of these data is called a stream. Stream data in broken parts called chunks; the computer starts processing the data as soon as it receives a chunk, not waiting for the whole data.

We will look here at Streams and Buffers. Sometimes, the processing speed is less than the rate of receiving chunks or faster than the rate of receiving chunks; in both cases, it is necessary to hold the chunks because processing requires a minimum amount of it, which is done using the buffers.


### All streams are instances of EventEmitter. 


#### You can immediately use a chunk as soon as it is available through the data event. 



```ts
// Buffer - entire file in memory
const buffer = fs.readFileSync('image.jpg');

// Stream - processes in chunks
const stream = fs.createReadStream('image.jpg');
```
