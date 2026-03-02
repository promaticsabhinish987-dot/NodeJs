# Auth + Permissions + Derived Fields

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























