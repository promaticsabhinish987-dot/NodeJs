## High Frequency Counter Updates

For high-frequency counters (likes, views, clicks) in Node.js + MongoDB, a naïve $inc on a single document becomes a write bottleneck under load. Updating single document 100000 times in a second can increase database load and take more time.

We have to find a solution which will optimize **write throughput**. 
Write throughput is a performance metric that measures the rate at which a system can write data to storage or process incoming data within a specific period.

### 1. Problem with Naïve Approach


```ts
await Post.updateOne(
  { _id: postId },
  { $inc: { views: 1 } }
);
```
Issues:

- Single document = **write contention**

- MongoDB document-level locking → **hotspot**

- Throughput collapses at scale


**Write contention** :- mongodb uses document level-locking , only one write operation can modify a document at a time, and other write must wait in a queue.

**Hotspot (Hot Document / Hot Key) **:- 

**Definition:**
A hotspot is a disproportionately accessed resource (document, shard key, or index entry) that receives a very high share of traffic (reads or writes) compared to others.

**Types:**

- **Write hotspot** → too many writes to one document/key

- **Read hotspot** → too many reads from one document/key


| Concept              | Role                                             |
| -------------------- | ------------------------------------------------ |
| **Hotspot**          | Cause (skewed traffic to one resource)           |
| **Write Contention** | Effect (many writes competing for that resource) |


A hotspot creates write contention.

**Hotspot** = One billing counter in a mall with 1000 customers

**Write Contention** = All customers trying to pay at that same counter → queue forms



### 2. Distributed Counter (Bucket Pattern) best for production.

**Idea** 

Instead of 1 counter → use N counter documents (buckets)

Each request:

- Picks a random bucket

- Increments that bucket

Final count:

- Sum of all buckets


==> we will distribute the write counter, to solve write heavy problem, we are just distributing the write load among different counter buckets, and at the time of reading we will just aggrgate all the counter bucket and return its sum.

Problem with it , slow read because of aggrigation of counter buckets.


#### Schema Design


```ts
const mongoose = require("mongoose");

const CounterBucketSchema = new mongoose.Schema({
  entityId: { type: mongoose.Schema.Types.ObjectId, index: true }, // postId
  bucket: { type: Number, index: true }, // 0–99
  count: { type: Number, default: 0 }
}, { timestamps: true });

CounterBucketSchema.index({ entityId: 1, bucket: 1 }, { unique: true });

module.exports = mongoose.model("CounterBucket", CounterBucketSchema);
```

#### Increment Logic (Write Path)


```ts
const BUCKET_SIZE = 100;

async function incrementView(postId) {
  const bucket = Math.floor(Math.random() * BUCKET_SIZE);

  await CounterBucket.updateOne(
    { entityId: postId, bucket },
    { $inc: { count: 1 } },
    { upsert: true }
  );
}
```

- Writes distributed across 100 docs

- No hotspot

- Highly parallel


#### Read Logic (Aggregate)


```ts
async function getViews(postId) {
  const result = await CounterBucket.aggregate([
    { $match: { entityId: postId } },
    { $group: { _id: null, total: { $sum: "$count" } } }
  ]);

  return result[0]?.total || 0;
}
```


### 3. Problem with this solution

It takes more time to read , because of aggrigation. How can we decrease the read time. so that our functionality will work properly.


System will update the redis after a given interval of time, and user will write in bucket, and read from cache for fast read becasue its already calculated.

#### Redis , optimization for fast read.

Goal :- Eliminate expensive aggregation on every read while preserving accuracy.

**Core Idea**

**Writes go to both:**

- MongoDB (durability)

- Redis (real-time counter)

- Reads come from Redis (O(1))

- Background job ensures consistency



#### Write path, update both redis and mongodb.

redis will be updated in ms and mongodb will take time.

```ts
async function handleView(postId) {
  // 1. Fast increment in Redis
  await redis.incr(`post:${postId}:views`);

  // 2. Scalable write to MongoDB (bucket)
  await incrementView(postId);
}
```

#### Read path , read from redis, in ms.

```ts
async function getViews(postId) {
  const views = await redis.get(`post:${postId}:views`);
  return Number(views) || 0;
}
```

#### Background Sync Job (Critical) , update the redis counter in bg

update it in every 30 to 60 sec.

```ts
async function syncToRedis(postId) {
  const result = await CounterBucket.aggregate([
    { $match: { entityId: postId } },
    { $group: { _id: null, total: { $sum: "$count" } } }
  ]);

  const actualCount = result[0]?.total || 0;

  await redis.set(`post:${postId}:views`, actualCount);
}
```


### 4. Production level solution. - ⏱️ Batch Writes (Extreme Scale)

Batch Mongo Writes (Reduce DB Load)

Instead of writing every request:

write in bulk. Instead of hitting DB per request:

Buffering converts:

many small writes → fewer large writes


Instead of writing , for each request in db, we collect all the write in buffer , and update the db.

```
Request → Memory Buffer → (batch) → DB
```


```ts
// create in memory buffer
let buffer = {};
function handleView(postId) {
  buffer[postId] = (buffer[postId] || 0) + 1;
}

//{
//  "post1": 120,
//  "post2": 45
//}  , very fast write

```

How we can flush it.

#### Flush Mechanism (Batch Write)

```ts
setInterval(async () => {
  const currentBuffer = buffer;
  buffer = {}; // swap buffer (IMPORTANT) flush old buffer and fill it in new buffer, now new request will go to fresh buffer.

  const bulkOps = [];

  for (const postId in currentBuffer) {
    bulkOps.push({
      updateOne: {
        filter: { entityId: postId },
        update: { $inc: { count: currentBuffer[postId] } },
        upsert: true
      }
    });
  }

  if (bulkOps.length > 0) {
    await CounterBucket.bulkWrite(bulkOps);
  }
}, 1000);
```

Its prensent in memory, thats why its not safe for critical data, on server crash the view will be removed from ram.
For this problem you can use redish as buffer. flush redish.

We will write in buffer and in redish , and flush buffer , and write bulk in db, and read from cache and if it has no data fetch from db and write in cache and then read from cache.

#### Buffer + Redis


```ts
async function handleView(postId) {
  // Redis (real-time)
  await redis.incr(`post:${postId}:views`);

  // Buffer (batch DB write)
  buffer[postId] = (buffer[postId] || 0) + 1;
}


setInterval(async () => {
  const current = buffer;
  buffer = {};

  const ops = Object.entries(current).map(([postId, count]) => ({
    updateOne: {
      filter: { entityId: postId },
      update: { $inc: { count } },
      upsert: true
    }
  }));

  if (ops.length) {
    await CounterBucket.bulkWrite(ops);
  }
}, 1000);




async function getViews(postId) {
  let views = await redis.get(`post:${postId}:views`);

  if (!views) {
    views = await getViewsFromMongo(postId);
    await redis.set(`post:${postId}:views`, views, "EX", 3600);
  }

  return Number(views);
}

```


















