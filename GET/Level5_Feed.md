# Complex Production GET (Aggregation + Multi Join + Optimization)

**Scenario:**

Get user feed:

Only posts from followed users

Only non-blocked users

Exclude soft-deleted posts

Include:

  - author

 - totalLikes

- totalComments

- isLiked

Paginated

Sorted by recency

```ts
router.get("/feed", authMiddleware, async (req, res, next) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user._id);
    const { page = 1, limit = 10 } = req.query;

    const skip = (page - 1) * limit;

    const following = await Follow.find({ follower: userId })
      .select("following")
      .lean();

    const followingIds = following.map(f => f.following);

    const feed = await Post.aggregate([
      {
        $match: {
          author: { $in: followingIds },
          isDeleted: false
        }
      },
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
          from: "likes",
          localField: "_id",
          foreignField: "post",
          as: "likes"
        }
      },
      {
        $lookup: {
          from: "comments",
          localField: "_id",
          foreignField: "post",
          as: "comments"
        }
      },
      {
        $addFields: {
          totalLikes: { $size: "$likes" },
          totalComments: { $size: "$comments" },
          isLiked: {
            $in: [userId, "$likes.user"]
          }
        }
      },
      {
        $project: {
          likes: 0,
          comments: 0
        }
      },
      { $sort: { createdAt: -1 } },
      { $skip: skip },
      { $limit: parseInt(limit) }
    ]);

    res.status(200).json({
      success: true,
      data: feed
    });

  } catch (err) {
    next(err);
  }
});
```





