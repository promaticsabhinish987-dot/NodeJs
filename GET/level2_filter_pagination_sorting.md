# Filtering + Pagination + Sorting


```ts
// GET /posts?author=123&page=1&limit=10&sort=createdAt

router.get("/posts", async (req, res, next) => {
  try {
    const {
      author,
      page = 1,
      limit = 10,
      sort = "-createdAt"
    } = req.query;

    const query = {};

    if (author) {
      if (!mongoose.Types.ObjectId.isValid(author)) {
        return res.status(400).json({ success: false, message: "Invalid author ID" });
      }
      query.author = author;
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [posts, total] = await Promise.all([
      Post.find(query)
        .sort(sort)
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      Post.countDocuments(query)
    ]);

    res.status(200).json({
      success: true,
      meta: {
        total,
        page: parseInt(page),
        pages: Math.ceil(total / limit)
      },
      data: posts
    });

  } catch (err) {
    next(err);
  }
});
```

with mongoose.
use skip for 

Dataset is small (< 50k)

Note ;- 

1. why Promise why not

```ts
const posts = await Post.find(...); //1st run this for 100ms
const total = await Post.countDocuments(...); // then run this for 100ms
```
You double latency.

With Promise.all, both run in parallel.

If each takes 100ms:

Sequential = 200ms

Parallel = ~100ms



2. Why lean() Matters

Without .lean():

Mongoose converts each document into a full Mongoose Document object.

That means:

Change tracking

Getters/setters

Virtuals

Methods

You don’t need that for read-only APIs.

.lean() returns plain JS objects.


3. Why Return Metadata?

```ts
meta: {
  total,
  page,
  pages
}
```

4. skip() is dangerous at scale.

it traverse all 99990 to get next 10. its O(n)

Solution is **Cursor Pagination**

```ts
router.get("/posts", async (req, res, next) => {
  try {
    const { cursor, limit = 10 } = req.query;

    const safeLimit = Math.min(parseInt(limit), 50);

    const query = {};

    if (cursor) {
      query.createdAt = { $lt: new Date(cursor) };
    }

    const posts = await Post.find(query)
      .sort({ createdAt: -1 })
      .limit(safeLimit)
      .lean();

    const nextCursor =
      posts.length > 0
        ? posts[posts.length - 1].createdAt
        : null;

    res.status(200).json({
      success: true,
      nextCursor,
      data: posts
    });

  } catch (err) {
    next(err);
  }
});
```

Without index, cursor pagination is useless.


db.posts.createIndex({ author: 1, createdAt: -1 })

if filtering by author.

use compound cursor because day might be duplicated 


```ts
.sort({ createdAt: -1, _id: -1 })


{
  $or: [
    { createdAt: { $lt: cursor.createdAt } },
    {
      createdAt: cursor.createdAt,
      _id: { $lt: cursor._id }
    }
  ]
}
```
# Production principles

1. 1. Always Index Filter + Sort Fields
  
```ts
db.posts.createIndex({ author: 1, createdAt: -1 })
```
If you filter by author and sort by createdAt:

2.Cap limit
Never allow client to control unlimited results.


```ts
const safeLimit = Math.min(parseInt(limit), 50);
```

3.Validate Query Inputs

Always sanitize:

Page must be >= 1

Limit must be positive integer

Sort must be whitelisted

Never trust client.


4. Use Projection

Less data transferred = faster API.


```ts

Post.find(query)
  .select("title author createdAt")

```

5. Avoid Counting on Every Request (if heavy traffic)

Advanced pattern:

Cache total count

Or return hasNextPage instead of total pages



### WHy not using aggregation here

using power everytime is not best choice

| Feature              | find() | aggregate() |
| -------------------- | ------ | ----------- |
| Simple filter        | ✅      | ✅           |
| Pagination           | ✅      | ✅           |
| Projection           | ✅      | ✅           |
| Grouping             | ❌      | ✅           |
| Computed fields      | ❌      | ✅           |
| Joins ($lookup)      | ❌      | ✅           |
| Performance overhead | Lower  | Higher      |

use aggregation for complex group query only.


There is:

No grouping

No computed field

No join

No reshaping

No transformation

Using aggregation here would be like:

Using a full data-processing engine to filter a list.

Unnecessary complexity.


```ts
//we can implement same with aggregation
router.get("/posts", async (req, res, next) => {
  try {
    const { author, page = 1, limit = 10 } = req.query;

    const skip = (page - 1) * limit;

    const matchStage = {};

    if (author) {
      matchStage.author = new mongoose.Types.ObjectId(author);
    }

    const pipeline = [
      { $match: matchStage },
      { $sort: { createdAt: -1 } },
      { $skip: skip },
      { $limit: parseInt(limit) }
    ];

    const posts = await Post.aggregate(pipeline);

    res.json({ success: true, data: posts });

  } catch (err) {
    next(err);
  }
});
```


## But it break the production engineering rule :- Use the simplest tool that satisfies the requirement.(dont do over engineering if not needed)


If you don’t need transformation, don’t use aggregation.

Aggregation is powerful but heavier.


Note :-

Another Important Production Detail

Aggregation:

Does NOT use Mongoose document middleware.

Returns plain objects.

Does NOT support .lean() (because it already returns plain objects).

If you rely on:

Schema virtuals

Getters

Hooks

Aggregation bypasses that layer.











