# GET code at production level

get all users.

```ts
// routes/user.routes.js
const express = require("express");
const router = express.Router();
const User = require("../models/User");

router.get("/", async (req, res, next) => {
  try {
    const users = await User.find().lean();
    res.status(200).json({
      success: true,
      data: users
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
```

1. why lean() :- We don’t need mongoose document methods.

Reduces memory usage.

Faster serialization.

2. why next(err).

Express is also a middleware , so it passes the err to the next middleware.

Express has a rule if we have next(error) , then it sill all the middleware and pass it to , error-handling middleware.

```ts
app.use((err, req, res, next) => {
  console.error(err);

  res.status(500).json({
    success: false,
    message: "Internal Server Error"
  });
});
```

We can define , it in all the routes but it break the production rules.

##  production architecture principles.
1. Centralized Error Handling :- if we do same thing for each route its repeated code.

Route handles business logic
Error middleware handles error response

because if we define in all the route , we may have inconsistent , error handling and its very difficult to go to each route to change error message. 

**Separation of concerns.**


2. Logging & Monitoring


```ts

app.use((err, req, res, next) => {
  logger.error({
    message: err.message,
    stack: err.stack,
    path: req.originalUrl,
    user: req.user?._id
  });

  res.status(err.statusCode || 500).json({
    success: false,
    message: err.message || "Internal Server Error"
  });
});

```
If you don’t use next(err):
You lose centralized observability.

**And in production, observability is survival.**

3. Custom Error Types

In seripus system we does not throw row errors, we throw custom error.

```ts

// Created custom error


class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
  }
}
```

use in route 

```ts
if (!user) {
  return next(new AppError("User not found", 404));
}
```
And error middleware decides how to respond.

This creates a clean architecture.


Note :- if anything fails like db fail in throw block , catch block run and next(err) will run the error middleware. by defulat its Internal server error.

1. If you forgot catch , server crash if any bug found, and if not return after a giving response , server will throw this error.

```ts
Error: Cannot set headers after they are sent
```



Final code 


```ts
router.get("/", async (req, res, next) => {
  try {
    const users = await User.find().lean();
    res.status(200).json({ success: true, data: users });
  } catch (err) {
    next(err);
  }
});

app.use((err, req, res, next) => {
  console.error(err);

  res.status(err.statusCode || 500).json({
    success: false,
    message: err.message || "Internal Server Error"
  });
});


// if want to define different category of error use if match

app.use((err, req, res, next) => {
  console.error({
    message: err.message,
    stack: err.stack,
    path: req.originalUrl
  });

  if (err.name === "ValidationError") {
    return res.status(400).json({
      success: false,
      message: err.message
    });
  }

  res.status(500).json({
    success: false,
    message: "Internal Server Error"
  });
});

```

## better production pattern (Create Async Wrapper)


```ts
const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

router.get("/", asyncHandler(async (req, res) => {
  const users = await User.find().lean();
  res.status(200).json({ success: true, data: users });
}));
```

