# Pagination at 100M Documents.


## ====================== Solution start ========================

```
Index: {createdAt:1,_id:1}

Query:
range pagination

Limit:
50–200
```

Code :- 


```ts
const mongoose = require("mongoose");

const logSchema = new mongoose.Schema({
  message: String,
  level: String,
  createdAt: {
    type: Date,
    default: Date.now,
    index: true
  }
});

/*
Compound index for pagination
*/
logSchema.index({ createdAt: 1, _id: 1 });

const Log = mongoose.model("Log", logSchema);

module.exports = Log;
```

Solves:

- ordering by timestamp

- duplicate timestamps

- efficient range scans

Without _id, pagination can break when two logs share the same timestamp.


### We should not expose raw database fields directly.

encode the cursor.

```ts
function encodeCursor(doc) {
  const cursor = {
    createdAt: doc.createdAt,
    _id: doc._id
  };

  return Buffer.from(JSON.stringify(cursor)).toString("base64");
}
```

Decode cursor:


```ts
function decodeCursor(cursor) {
  if (!cursor) return null;

  const decoded = Buffer.from(cursor, "base64").toString("utf8");
  return JSON.parse(decoded);
}
```

Pagination query logic

```ts
async function getLogs({ cursor, limit = 50 }) {

  limit = Math.min(Math.max(limit, 1), 200);

  let query = {};

  if (cursor) {
    const decoded = decodeCursor(cursor);

    query = {
      $or: [
        { createdAt: { $gt: new Date(decoded.createdAt) } },
        {
          createdAt: new Date(decoded.createdAt),
          _id: { $gt: decoded._id }
        }
      ]
    };
  }

  const logs = await Log.find(query)
    .sort({ createdAt: 1, _id: 1 })
    .limit(limit);

  let nextCursor = null;

  if (logs.length > 0) {
    const lastDoc = logs[logs.length - 1];
    nextCursor = encodeCursor(lastDoc);
  }

  return {
    data: logs,
    nextCursor
  };
}
```
Express api

```ts
const express = require("express");
const app = express();

app.get("/logs", async (req, res) => {

  try {

    const { cursor, limit } = req.query;

    const result = await getLogs({
      cursor,
      limit: Number(limit) || 50
    });

    res.json(result);

  } catch (err) {
    res.status(500).json({ error: err.message });
  }

});
```


example

```ts
GET /logs


{
  "data": [
    { "_id": "66b1...", "message": "log1" },
    { "_id": "66b2...", "message": "log2" }
  ],
  "nextCursor": "eyJjcmVhdGVkQXQiOiIyMDI2..."
}

```


## Danger

## Critical Pagination Rule (MongoDB)

In MongoDB, **efficient pagination requires the index order to match the sort order**.

### Correct (Uses Index Scan)

```js
Index: { createdAt: 1, _id: 1 }
Sort : { createdAt: 1, _id: 1 }
```

Query:

```js
Log.find(query)
  .sort({ createdAt: 1, _id: 1 })
  .limit(50)
```

Execution:

```
IXSCAN → FETCH → LIMIT
```

Fast because MongoDB reads the index sequentially.

---

### Incorrect (Index Cannot Be Used)

```js
Index: { createdAt: 1, _id: 1 }
Sort : { createdAt: -1 }
```

MongoDB may execute:

```
COLLSCAN → In-memory SORT → LIMIT
```

Which means:

* Full collection scan
* Expensive sorting
* Very slow for large datasets.

---

### Rule to Remember

```
Index order must match sort order
```

Otherwise MongoDB **cannot use the index efficiently**, breaking high-scale pagination performance.


## ====================== Solution end ==========================

How we can implement pagination at 100M documnets.

given solution is

```ts
db.logs.find().skip(50000).limit(50);
```

This will give the result you want, data after 500000 docs.

But what is wrong with it?

### Problem : 1 

n skipp === O(n) time complexity 

evern for fetching 50 docs it first have to scan the 500000 docs to skip them , which will take time.

**Latency will go linear.**

Note :- skip() will break at scale because it scans n documents.


### Gap 1 :- why mongodb does not jumpt straigt to that document?

because mongodb docs are not stored in array or linear data structure it uses B-tree , and it supports range traversal, not position jumps - sequential traversal.
It must walk the tree sequentially.

### Gap 2 :- Why does pagination become inconsistent under insert load?

High insert rate gives different result, if we use skip().

Pagination become inconsistent under insert load.
Because pagination depends on **position**, not data value.
When we insert to much data, position of documents change, which will result inconsistent data.


Now we know clearly why skip() fails at scale.

Do we have any other option.
lets explore.


### Cursor Pagination

Cursor pagination says.


```
give me documents AFTER this value
Not skip first 5M docs
```

like 

If we have last seen id , we will not traverse 50000 docs we just go straight to that document and return the next 50 documents.
It will always give latest post and docs.

```ts
// suppose we have last seen id.
lastSeenId = 65fa231

db.logs.find({
  _id: { $gt: lastSeenId }
}).limit(50)

```


Now mongodb is using **index range**?

```
jump to index key = lastSeenId
return next 50

Time Complexity

O(log N + K)

K - returned rows, and its extremly fast

```

Till now we have one solution , store the last seen and fetch next 50. 
#### But how we can get last seen id?


### Gap :- Why is range query faster than skip?

Because the index tree can directly locate a key.

Id always uses indexing by default.

Searching **_id = X** is: take time **O(log N)**
 And then it will do linear search for next , 50 docs.

 #### how we can use this concept for pagination? its called cursor based pagination. Means we maintain a cursor or pointer, to directly go to that doc and then get next 50.
 
### Cursor based pagination design. and its goal

1.  with 100M+ documents

2. Remains fast for deep pages (because it does not use skip)

3. Remains stable under inserts (it gets always top )

```ts
const logs = await Log
  .find({})
  .sort({_id: 1}) // ;ast doc it //latest documents first
  .limit(50) 
```

This is the logical query.

MongoDB first converts it into a physical execution plan.

#### Does find({}) load all documents?
no
**find({}) defines the search space, not the amount of data loaded.**


```
It means

the filter condition matches all documents

not
load entire collection into memory
```


means it starts scaning from latest, because documents are already sorted in mongodb if indexed. 

Limit tells if we are done with 50 doc scanning from the whole , stop the scanning and return the documents.





find all sort them , and then get top 50 documents and maintain a cursor for last seen if.
for getting data like
last 50
2nd last 50
3nd lst 50

No

its like 


```
Scan _id index

Fetch documents in sorted order (sorting will not work becuse index is already sorted)

Stop after 50 
```


means we traverse from newest to oldest.

#### What about the time complexity of sorting here?
Why is there no sorting cost?

Because B-Tree indexes are already sorted.


return 

```

data: [...]
nextCursor: lastDocument._id

```

How we can make Next page request

```
GET /logs?cursor=65fa231
```

```ts

const logs = await Log.find({
  _id: { $gt: cursor }
})
.sort({_id: 1})
.limit(50)

```

response will be

```json
{
  "data": [...],
  "nextCursor": "660a912"
}
```

You will get the documents after the cursor not the newest one. newest one you get after refreshing , the page, to reset the cursor to the latest one.


```

1
2
3
4
5
6
7
8
9
10

cursor = 4

filter: _id > 4
→ [5,6,7,8,9,10]

sort ascending
→ [5,6,7,8,9,10]

limit 50
→ [5,6,7,8,9,10]

```

For getting the newest document you have to use it , to reset the cursor.

```ts
Log.find({})
.sort({ _id: -1 })
.limit(50)
```

### Gap 4 :- Why do we use _id as cursor?


Because _id are 

1. indexed automatically.
2. is monotonically increasing (stored in a order)
3. encodes timestamp (id is generated by using the time stamp encoding, for maintaining a order)

**An ObjectId is a 12-byte (96-bit) binary value, and the first 4 bytes encode a timestamp. This is why sorting by _id roughly sorts documents by creation time.**


### Structure of a MongoDB ObjectId


```
12 bytes = 96 bits
```

| Bytes   | Component                  | Purpose                    |
| ------- | -------------------------- | -------------------------- |
| 4 bytes | Timestamp                  | seconds since Unix epoch   |
| 5 bytes | Random / machine + process | uniqueness across machines |
| 3 bytes | Counter                    | incrementing value         |



```
|----4 bytes----|-----5 bytes------|---3 bytes---|
|   timestamp   | machine/process  |   counter   |


like


65f1a9b2 → timestamp
9c8d2f4a11 → machine/process random
7a3c → counter

```

It stores document like

```
older timestamps → newer timestamps
```

Sorting reverse reads it

```
.sort({_id: -1})

newest to oldest
```

Its not array based sorting.


TO get time stamp

```ts
const { ObjectId } = require("mongodb");

const id = new ObjectId("65f1a9b29c8d2f4a117a3c");
console.log(id.getTimestamp());
```


```ts
Log.find({_id:{$gt:cursor}})
.sort({_id:1})
.limit(50)
```
sort _d means its param , to target for sorting , and -1 and 1 for ascending or descending.
and for ascending or descending we can to to last, or first one to scan it.


It might be duplicated , so use compound index.


```ts
db.logs.createIndex({createdAt:1,_id:1})

db.logs.find({
  createdAt: { $gt: lastCreatedAt }
})
.sort({createdAt:1,_id:1})
.limit(50)
```

Why add _id in the index?

Because timestamps may duplicate.

Example:

```
10:00:00.123 logA
10:00:00.123 logB
```


Cursor only using createdAt would break ordering.

Compound index solves it.


### Cursor encoding in API

we dont want to expose raw database value thats why we encode the cursor.

like

```ts
cursor = base64({
  createdAt,
  _id
})

eyJjcmVhdGVkQXQiOiIyMDI2... (incode with base64 or with other)
```

Decoding 

```ts
const cursor = JSON.parse(
  Buffer.from(req.query.cursor,'base64')
)
```
### Skip vs Cursor Comparison


| Feature          | Skip Pagination | Cursor Pagination |
| ---------------- | --------------- | ----------------- |
| Time complexity  | O(N)            | O(logN)           |
| Deep pagination  | Slow            | Fast              |
| Insert safety    | Broken          | Stable            |
| Index usage      | Poor            | Excellent         |
| Production usage | Avoid           | Standard          |









