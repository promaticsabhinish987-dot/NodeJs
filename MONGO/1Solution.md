# ====================== Solution Start =========================

**Architecture goal:**

```
posts collection
 ├─ authorId (reference)
 └─ authorSnapshot (embedded partial data)
```

**Benefits**

```
1. query read ( we have author data inside the post thats why it will take 1req = 1 query , work for list of post also)

2. full user data still accessible ( if we want to access the full user data for a post , we can also access that)

3. async update propagation ( your profile will be updates, sunchronously , but the post author data will be updatd in background)

```

### 1. Project Structure

```
project
│
├── models
│   ├── User.js
│   └── Post.js
│
├── services
│   └── userUpdateService.js
│
├── routes
│   ├── postRoutes.js
│   └── userRoutes.js
│
├── workers
│   └── postUpdateWorker.js
│
├── queue.js
└── server.js
```

### 2. User Model

```ts
// models/User.js

const mongoose = require("mongoose")

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true },
  avatar: String,
  email: String
})

module.exports = mongoose.model("User", UserSchema)
```

### 3. Post Model (Embedding + Reference)

```ts
// models/Post.js

const mongoose = require("mongoose")

const PostSchema = new mongoose.Schema({
  title: String,
  content: String,

  authorId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    index: true
  },

  authorSnapshot: {
    name: String,
    avatar: String
  }

}, { timestamps: true })

module.exports = mongoose.model("Post", PostSchema)
```

### 4. Create Post (Store Snapshot) (while creating post store snamshot of user)

```ts
// routes/postRoutes.js

const express = require("express")
const router = express.Router()

const Post = require("../models/Post")
const User = require("../models/User")

router.post("/posts", async (req, res) => {

  const { title, content, authorId } = req.body

  const user = await User.findById(authorId)

  const post = await Post.create({
    title,
    content,
    authorId,

    authorSnapshot: {
      name: user.name,
      avatar: user.avatar
    }
  })

  res.json(post)
})

module.exports = router
```

### 5. Fast Read API (1 Query)

Reads use embedded snapshot.


```ts
router.get("/posts/:id", async (req, res) => {

  const post = await Post.findById(req.params.id)

  res.json(post)

})
```
Only one db operation for post or list of post.

### 6. Get Full User Data When Needed

```ts
router.get("/posts/:id/full", async (req, res) => {

  const post = await Post.findById(req.params.id)

  const user = await User.findById(post.authorId)

  res.json({
    post,
    user
  })

})
```

like clicking to detail, or more...


### 7. Update User Profile


```ts
// routes/userRoutes.js

const queue = require("../queue")
const User = require("../models/User")

router.put("/users/:id", async (req, res) => {

  const { name, avatar } = req.body

  const user = await User.findByIdAndUpdate(
    req.params.id,
    { name, avatar },
    { new: true }
  )

  // push background job
  await queue.add("update-post-author", {
    userId: user._id,
    name: user.name,
    avatar: user.avatar
  })

  res.json(user)

})
```

### 8. Queue Setup

This is the best place to use queue, its for async task.

```ts
// queue.js redish or bulma

const { Queue } = require("bullmq")

const connection = {
  host: "127.0.0.1",
  port: 6379
}

const queue = new Queue("post-update", { connection })

module.exports = queue
```

### 9. Background Worker

Worker updates embedded snapshots.


```ts
// workers/postUpdateWorker.js

const { Worker } = require("bullmq")
const mongoose = require("mongoose")
const Post = require("../models/Post")

const connection = {
  host: "127.0.0.1",
  port: 6379
}

const worker = new Worker("post-update", async job => {

  const { userId, name, avatar } = job.data

  await Post.updateMany(
    { authorId: userId },
    {
      $set: {
        "authorSnapshot.name": name,
        "authorSnapshot.avatar": avatar
      }
    }
  )

}, { connection })
```


### 10. Server setup

```ts
// server.js

const express = require("express")
const mongoose = require("mongoose")

const postRoutes = require("./routes/postRoutes")
const userRoutes = require("./routes/userRoutes")

const app = express()

app.use(express.json())

mongoose.connect("mongodb://localhost:27017/blog")

app.use(postRoutes)
app.use(userRoutes)

app.listen(3000, () => {
  console.log("Server running")
})
```


| Operation   | DB Queries       |
| ----------- | ---------------- |
| Create Post | 2                |
| Read Post   | 1                |
| User Update | 1 + async update |


Now this can work for any no of users.


# ====================== Solution End =========================

# 1 Solution

## Goal

**Fetch Post with Author**

We want to return a **post with its author data**.

Currently **2 queries are required per post request**.

Example request:

```
GET /posts/:id
```

### Database Operations per Request

```ts
post = db.posts.findOne({_id})  // fetch that post
author = db.users.findOne({_id: post.authorId})  // also fetch the author of that post
```

### Time Taken by Each Query

| Step | Query       | Complexity            |
| ---- | ----------- | --------------------- |
| 1    | Find post   | O(log N) index lookup |
| 2    | Find author | O(log M) index lookup |

```
1 req/sec  == 2 db query
10,000 req/sec == 20,000 db query
```

### What is bad here?

1. Index traversal takes time.
2. Query parsing takes time.
3. Other database overheads exist.

---

## Now consider list queries

Right now we are requesting **only one post**.

But what if we fetch **many posts**?

Example:

```
GET /posts/?limit=100
```

### Database Operations

```
1 req/sec
= fetch 100 posts (1 db query)
= fetch 100 authors (100 db query)
```

```
10,000 req/sec
= 10,000 * 1  (10,000 db request for posts)
= 10,000 * 100 (1,000,000 db request for authors)
```

```
1 db query  -> fetch 100 posts
100 db query -> fetch their 100 authors

===============================
100 + 1 queries
===============================

Called:

N + 1 Problem
```

### Example Code

```ts
posts = db.posts.find({})

for each post:
   db.users.findOne()
```

---

# Redesign the Query or Schema

Now we need to **redesign the query or schema** to optimize it.

Possible solutions exist.

We can also use **hybrid approaches**.

Hybrid means combining **features of multiple techniques** to get the **best possible result**.

---

# Embedding vs Referencing

Every MongoDB schema design begins with one architectural decision:

```
Should related data live together or separately?
```

This leads to two strategies:

1. **Embedding** → store related data inside the same document
2. **Referencing** → store related data in another collection and link with an id

Understanding **when each fails** is the real knowledge gap.

---

## Q1

List the limitations of each and when to use them.

Also explain what **options ODM tools like Mongoose provide**.

---

# Embedding (Data Co-Location)

Embedding means **placing related data inside the parent document**.

There can be **multiple ways to embed data**, and each has its **own limitations and importance**.

---

## Q2

Why do we need embedding?

Embedding **reduces disk reads**.

Example:
If we place **author data inside each post**, then the query becomes:

```
1 req/sec == 1 db query
2 req/sec == 2 db query
```

This is **better than the previous design**.

---

### Then why don't we always use embedding?

Because although **reading becomes easier**, **updates become harder**.

Example:

If the **author changes their name**, we must update **all posts written by that author**.

This causes:

* Extra write operations
* Extra storage usage

---

## Problems

1. **Extra space usage**
   Data duplication occurs.

```
post collection size = 100MB
author data duplication = 30MB
```

2. **Updates become time consuming**

---

### Time Complexity

| Operation          | Complexity |
| ------------------ | ---------- |
| Read post + author | O(log N)   |
| Update author name | O(P)       |

```
P = number of posts written by the user
```

---

## Q3

Which embedding strategy should we choose?

Before deciding, we must understand **types of embedding**.

---

# Types of Embedding

## 1. Full Embedding

Example schema:

```json
posts
{
   title
   author: {
       id
       name
       email
       avatar
       followers
   }
}
```

### Benefits

1. We can read **all author attributes** easily.
2. Only **one query is required**.
3. No need for **MongoDB joins**.

---

### Limitations

1. **Update cost**

If any author attribute changes:

```
Update complexity = O(P)
```

All posts must be updated.

2. **Large storage usage**

Massive **data duplication** occurs.

Duplicates are generally **undesirable** in database design.

---

## Q4

How do we decide which embedding approach is better?

Let's look at the second type.

---

# 2. Partial Embedding (Snapshot Pattern)

Only store **frequently read fields**.

Example:

```ts
posts
{
   title
   authorId
   authorSnapshot: {
       name
       avatar
   }
}
```

This is called **partial denormalization**.

```
Normalization   = breaking data into multiple collections
Denormalization = combining related data
```

---

### Benefits

1. **Fast reads**

Only **one query** is needed to fetch **post + author snapshot**.

2. **Less storage usage**

Compared to full embedding, **data duplication is minimal**.

3. **Highly scalable**

This pattern works well for systems with **large numbers of posts**.

---

### Limitations

1. **Eventual consistency**

If the author updates their name, the post still shows the **old name**.

Therefore, a **background job must update snapshots**.

---

## Q4

This pattern looks good.

Should we use it?

---

# 3. Array Embedding

Used for **one-to-few relationships**.

Example:

```json
posts
{
   title
   comments: [
      {userId, text},
      {userId, text}
   ]
}
```

---

### Benefits

1. **Very fast read**

Only **one database request** is required.

2. **Atomic updates**

All updates occur **inside a single document**.

---

### Limitations

1. **MongoDB document size limit**

```
Maximum document size = 16MB
```

If comments grow large, the document **can exceed the limit**.

Therefore we should only embed **data that does not grow unbounded**.

Example:
Address data.

---

# When Embedding Works Best

Embedding is ideal when:

```
relationship = one-to-few
data changes rarely
data is read together
```

---

### Examples

1. **Address inside user**

* Rarely updated
* Always fetched with user

2. **Product variants**

* Needed together during reads

3. **Small comment lists**

* Limited growth
* Frequently read with parent document

---


# Referencing (Normalization)

Normalization , breaking table , and then combining with key. passing reference of related data.

Referencing means store related data in another collection and link using id.

```
posts
{
   _id
   title
   authorId
}

users
{
   _id
   name
}
```


To fetch author.
need two query 

```ts
post = db.posts.findOne() // find post 
user = db.users.findOne(post.authorId) // then find the author with id provided in the post
```

### But why to seperate the document?

Because some relationships grow too large.
Embedding fails, when data grows unbounded, means we dont know , the no of documents.and it can grow rapidly.

 like 

1. User followers
2. User likes
3. Comments on viral post

These valied can reach to millions, thats why we can not store these valies , inside the post , because we can store the 10MB of data in a document.
so embedding will fail.

embedding fails in two case

1. we dont know the size of documents, which we are embedding like comment on post.
2. need frequent update.


embedding become impossible here , thats why we use referencing , it does not increase a sinle doc size, because we are just storing the reference , like single reference of list of reference.

but we need , more db calls for getting data, but its good for update and takes less space to store , and give sinle point of access becasue we are accessing with key.


Its just opposite of embedding.

Time complexity.


| Operation   | Complexity |
| ----------- | ---------- |
| Read post   | O(log N)   |
| Read author | O(log M)   |

same thing will happen which was given in question.

It will take double time but , because of having sinlge point access with key, take less time to update.

Q) then what we should do, how we decide ?

first learn about its type.


## Types of Referencing

### 1. Manual Referencing

Application performs multiple queries.


```
post = posts.find()
user = users.find()
```
Benefits

1. simple, require simple query for getting required result.
2. flexible , we are controoling it thats why its flexible, and we can design it, in different way.

Limitations

1. N+1 query problem (1 req for n post and n request for n authors = 1 for post + n for authors )


### 2.Database Join Referencing

MongoDB supports joins via aggregation.

```
$lookup // uperator we use for left join
```

like

```
db.posts.aggregate([
   {
     $lookup:{
        from:"users",
        localField:"authorId",
        foreignField:"_id",
        as:"author"
     }
   }
])
```

Benefits

1. single query - database handle all complexity to give requed data, with sinle query. aggregation is a single query to db. we use it for decreasing db request. But it increases CPU use.
2. No duplication, because we are storing reference not full document.


Limitations

1. Expensive CPU usage , of databse.
2. slower then embedding (for getting related data), time consumed by db , for preparing the required results.

Time complexity 

```
O(N log M) // fetch n posts O(n) if indexed, takes log m for fetching the author.
```

Takes less space , and update fast, but read is slow here , because of CPU use.
In Embedding, takes more space, update slow, read fast, because of single db request, and less cpu processing of db.


### 3. Hybrid Referencing (Best Production Pattern)

```
reference + snapshot
```

_store reference to get full detail of author, and store minimal data of author, like name or image. to show with post._

like

```
posts
{
   title
   authorId
   authorName
   authorAvatar
}
```
1. Read uses snapshot (red is fast)
2. write uses reference (update is also fast)

for getting author full detail we need only 1 db query.


Q) but what if we store the list , as embedding, and what if we have to update the name which is also present in the post?


```
if read is higher then , write use this.

1000 reads
1 write
```
 
### clear comparison

| Feature     | Embedding  | Referencing |
| ----------- | ---------- | ----------- |
| Queries     | 1          | multiple    |
| Memory      | duplicated | minimal     |
| Consistency | weaker     | strong      |
| Scalability | limited    | unlimited   |
| Update cost | high       | low         |


### The real question is.

1. How often does the relationship change? ( if changing check frequency)
2. change frequency is low (embedd)
3. data grows unbounded (related data)
4. use referencing.
5. high read traffic (partial denormalization , use hybrid

```
One-to-few  → embed
One-to-many → reference
One-to-infinite → reference
High-read → denormalize
```

# With mongoose , which provide populate.

ODM layer (Mongoose) rather than MongoDB itself.

Its a layer of mongodb. which provide some methods, to deal with mongodb, it converts to native db query.

Mongodb itself support only

1. embedding
2. referencing
3. join with $lookup

But mongoose add higher level of abstration like

1. populate() - loads all inside ram
2.  population
3. dynamic references

These simplify development but introduce **performance trade-offs**.

| Feature     | `$lookup` | populate    |
| ----------- | --------- | ----------- |
| Execution   | database  | application |
| Queries     | 1         | multiple    |
| CPU cost    | DB heavy  | app heavy   |
| Flexibility | high      | easier      |


Populate is safe when

```
low traffic APIs
admin dashboards
internal tools
small datasets
```

#### What populate() Does

populate() resolves references between collections.


```ts
const PostSchema = new mongoose.Schema({
  title: String,
  author: {
     type: mongoose.Schema.Types.ObjectId,
     ref: "User"
  }
})
```


```ts
Post.find().populate("author")
```

```
{
  "title": "Mongo Guide",
  "author": {
    "_id": "123",
    "name": "Alex"
  }
}
```
#### How Populate Works Internally

It process multiple queries, automatically , it just provides an abstraction, but not increases performance of db.


#### Populate Types

1. Basic Populate

```ts
Post.find().populate("author")
```

2. Field Selection

```ts
Post.find().populate("author", "name avatar")
```

3. Nested Populate

```ts
Post.find().populate({
  path: "author",
  populate: { path: "company" }
})
```


4. Virtual Populate (reverse relation ship)

```ts
UserSchema.virtual("posts", {
  ref: "Post",
  localField: "_id",
  foreignField: "author"
})
```

#### Benefits of Populate

| Benefit                | Explanation                   |
| ---------------------- | ----------------------------- |
| Developer Productivity | easier relationships          |
| Cleaner code           | avoids manual joins           |
| Rapid development      | minimal queries written       |
| Flexible               | supports nested relationships |


#### Limitaions


1. Multiple Queries, Populate generates extra queries.
2. N+1 Query Risk
3. memory overhead , Large populations load many documents into Node.js memoryThis increases heap usage.
4. Slow for Large Graphs. Nested populate chains can create multiple queries. Post → Author → Company → Location

| Aspect      | Populate            |
| ----------- | ------------------- |
| Purpose     | resolve references  |
| Queries     | multiple            |
| Performance | moderate            |
| Best for    | small relationships |
| Risk        | N+1 queries         |




































