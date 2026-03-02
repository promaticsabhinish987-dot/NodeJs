# Multiple Collections

task : Get post with author + comments + comment author (with post id)


1. MongoDB Has No Real JOIN

MongoDB stores data in **separate collections.**

There is no foreign key constraint like SQL.

Instead, we store ObjectId references.


Collections

```js
users
posts
comments
```

2. HOW DATA IS STORED

  ```ts

const userSchema = new mongoose.Schema({
  username: String,
  avatar: String
});


const commentSchema = new mongoose.Schema({
  text: String,
  author: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User"
  },
  post: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Post"
  }
});


const postSchema = new mongoose.Schema({
  title: String,
  content: String,
  author: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User"
  },
  comments: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: "Comment"
  }]
});



```

3. What populate() Actually Does

```ts
Post.findById(id).populate("author")
```
Populate runs multiple query one after another and replace the id with the object 

like here , 

```ts
const post = await Post.findById(id)
const user = await User.find({ _id: { $in: authorIds } })
```

1st find the Post by id , and then extract the author id from it and then Fetch the user where authorid is match.

It is **multiple queries**, not a real join.

4. Nested Populate

```ts
.populate({
  path: "comments",
  populate: {
    path: "author"
  }
})
```
runs total of 3 query.


4. Why Populate Becomes Expensive

Populate is not streaming , it loads everything in the memory. thats why its expensive.

You can use it , but for small data.

5. Why Aggregation Is Better at Scale

Aggregation uses MongoDB server-side join: ** $lookup**



```ts
Post.aggregate([
  { $match: { _id: new ObjectId(id) } },
  {
    $lookup: {
      from: "users",
      localField: "author", // present in Post table
      foreignField: "_id", // match with user_id 
      as: "author" // store return value to this key 
    }
  },
  { $unwind: "$author" }, // open array to show
  {
    $lookup: {
      from: "comments",
      localField: "_id",
      foreignField: "post",
      as: "comments"
    }
  }
])
```
Now the join happens:

Inside MongoDB engine. not in ram.
Populate does this in ram thats why its bad.

Single round trip, treated as singe query.



| Aspect         | Populate         | Aggregation        |
| -------------- | ---------------- | ------------------ |
| Queries        | Multiple         | Single pipeline    |
| Control        | Limited          | Full control       |
| Performance    | Good small scale | Better large scale |
| Transformation | Minimal          | Powerful           |
| Memory control | Node side        | DB side            |



## Important Production Rules

1. Always Index Join Fields

Otherwise full collection scan

2. Limit Fields with $project

```ts
{
  $project: {
    title: 1,
    "author.username": 1,
    "author.avatar": 1,
    comments: 1
  }
}
```


3. Be Careful With Large Arrays

what if we have 1000 comments for a post.

Better approach:

- Separate endpoint for comments (to fetch comments separately not with post)

- Or limit comments


```ts
{
  $lookup: {
    from: "comments",
    let: { postId: "$_id" },
    pipeline: [
      { $match: { $expr: { $eq: ["$post", "$$postId"] } } },
      { $sort: { createdAt: -1 } },
      { $limit: 10 }
    ],
    as: "comments"
  }
}
```

Now only latest 10 comments returned.

That is production thinking.

### Final code 

```ts
Post.aggregate([
  { $match: { _id: new mongoose.Types.ObjectId(id) } },

  {
    $lookup: {
      from: "users",
      localField: "author",
      foreignField: "_id",
      as: "author"
    }
  },
  { $unwind: "$author" },

  {
    $lookup: {
      from: "comments",
      let: { postId: "$_id" },
      pipeline: [
        { $match: { $expr: { $eq: ["$post", "$$postId"] } } },
        { $sort: { createdAt: -1 } },
        { $limit: 20 }
      ],
      as: "comments"
    }
  },

  {
    $project: {
      title: 1,
      content: 1,
      "author.username": 1,
      "author.avatar": 1,
      comments: 1
    }
  }
])
```


#### How we can show the total no of comment and like 

```ts
{
  "_id": "p1",
  "title": "...",
  "author": { ... },
  "totalComments": 25,
  "totalLikes": 120,
  "isLiked": true
}
```
how to get it

Counting in MongoDB

1. Load full arrays → then $size (bad for large dataset)
2. Use $lookup with pipeline + $count


```ts
const post = await Post.aggregate([
  { $match: { _id: new mongoose.Types.ObjectId(id) } },

  // Join author
  {
    $lookup: {
      from: "users",
      localField: "author",
      foreignField: "_id",
      as: "author"
    }
  },
  { $unwind: "$author" },

  // Count comments
  {
    $lookup: {
      from: "comments",
      let: { postId: "$_id" },
      pipeline: [
        { $match: { $expr: { $eq: ["$post", "$$postId"] } } },
        { $count: "total" }
      ],
      as: "commentCount"
    }
  },

  // Count likes
  {
    $lookup: {
      from: "likes",
      let: { postId: "$_id" },
      pipeline: [
        { $match: { $expr: { $eq: ["$post", "$$postId"] } } },
        { $count: "total" }
      ],
      as: "likeCount"
    }
  },

  // Convert arrays into numbers
  {
    $addFields: {
      totalComments: {
        $ifNull: [{ $arrayElemAt: ["$commentCount.total", 0] }, 0]
      },
      totalLikes: {
        $ifNull: [{ $arrayElemAt: ["$likeCount.total", 0] }, 0]
      }
    }
  },

  // Remove temporary fields
  {
    $project: {
      commentCount: 0,
      likeCount: 0
    }
  }
]);
```

1. Load full comment array

```ts
$lookup: { from: "comments", ... }
```
2. calculate and return only count

```ts
pipeline: [
  { $match: ... },
  { $count: "total" }
]
```

but its better to store the count in schema and update it, on query. to get it in O(1)


#### Best solution , store count in Post document 

```ts
{
  title,
  commentCount: 25,
  likeCount: 120
}
```

update the count on 


- comment create → increment

- comment delete → decrement

- like create → increment

Pre-computed counters = O(1) read.


| Situation                       | Use Aggregation Count | Use Stored Counter |
| ------------------------------- | --------------------- | ------------------ |
| Small app                       | ✅                     | Optional           |
| Medium traffic                  | ✅                     | Better             |
| High traffic (millions req/min) | ❌                     | ✅ Required         |



### Adding isLiked (Advanced)

To check if current user liked post:


```ts
{
  $lookup: {
    from: "likes",
    let: { postId: "$_id" },
    pipeline: [
      {
        $match: {
          $expr: {
            $and: [
              { $eq: ["$post", "$$postId"] },
              { $eq: ["$user", new mongoose.Types.ObjectId(req.user._id)] }
            ]
          }
        }
      }
    ],
    as: "likedByUser"
  }
},
{
  $addFields: {
    isLiked: { $gt: [{ $size: "$likedByUser" }, 0] }
  }
}
```


```ts
"isLiked": true
```



Note :- dont do heady read , use datastructure logic , this is the best place to use dsa logic because we have millions of data.













