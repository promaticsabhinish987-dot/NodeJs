# Auth + Permissions + Derived Fields

What to show

Get post only if: Public OR user is owner OR user follows owner

```ts
router.get("/secure/posts/:id", authMiddleware, async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ success: false, message: "Invalid ID" });
    }

    const post = await Post.findById(id)
      .populate("author", "username avatar isPrivate")
      .lean();

    if (!post) {
      return res.status(404).json({ success: false, message: "Post not found" });
    }

    // Permission check
    if (post.author.isPrivate && post.author._id.toString() !== userId.toString()) {
      const isFollowing = await Follow.exists({
        follower: userId,
        following: post.author._id
      });

      if (!isFollowing) {
        return res.status(403).json({
          success: false,
          message: "You are not allowed to view this post"
        });
      }
    }

    // Derived field
    const isLiked = await Like.exists({
      user: userId,
      post: post._id
    });

    post.isLiked = !!isLiked;

    res.status(200).json({
      success: true,
      data: post
    });

  } catch (err) {
    next(err);
  }
});
```


1. Secure post fetch ?

A post is A resource that must be conditionally visible depending on identity and relationships.


Total = 3 DB round trips

This works but break at scale.


### Core Production Principles

1. Authentication ≠ Authorization

Your authMiddleware handles identity.
Your route handles permission logic.  // authorization is at business level

2. Never Trust Client-Derived State

```ts

"isLiked": true

```

get it from db



## Production-Grade Aggregation Version


```ts
Post.aggregate([
  { $match: { _id: new ObjectId(id) } },

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

  // Join follow relationship
  {
    $lookup: {
      from: "follows",
      let: { authorId: "$author._id" },
      pipeline: [
        {
          $match: {
            $expr: {
              $and: [
                { $eq: ["$follower", new ObjectId(userId)] },
                { $eq: ["$following", "$$authorId"] }
              ]
            }
          }
        }
      ],
      as: "followStatus"
    }
  },

  // Join like relationship
  {
    $lookup: {
      from: "likes",
      let: { postId: "$_id" },
      pipeline: [
        {
          $match: {
            $expr: {
              $and: [
                { $eq: ["$user", new ObjectId(userId)] },
                { $eq: ["$post", "$$postId"] }
              ]
            }
          }
        }
      ],
      as: "likeStatus"
    }
  },

  // Derived fields
  {
    $addFields: {
      isLiked: { $gt: [{ $size: "$likeStatus" }, 0] },
      isFollowing: { $gt: [{ $size: "$followStatus" }, 0] }
    }
  },

  // Permission filter
  {
    $match: {
      $or: [
        { isPublic: true },
        { "author._id": new ObjectId(userId) },
        { isFollowing: true }
      ]
    }
  },

  {
    $project: {
      followStatus: 0,
      likeStatus: 0
    }
  }
])
```






















