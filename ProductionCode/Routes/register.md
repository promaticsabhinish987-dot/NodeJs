### Register

```ts
router.post('/register', validate(authValidation.register), authController.register);
```


Controller

```ts
const register = catchAsync(async (req, res) => {
  const user = await userService.createUser(req.body);
  const tokens = await tokenService.generateAuthTokens(user);
  res.status(httpStatus.CREATED).send({ user, tokens });
});
```


### catchAsync

Why we are using catchAsync.

In synchronus way express catches error and show in console but with async and await , we catch the error in catch block and use, it.


```ts
router.get('/user', async (req, res) => {
  const user = await getUser(); // ❌ if this throws, Express won't catch it
  res.send(user);
});
```

Express will not handle this error , it will be unhandled error or your app might hang or crash. Because we are not handling the error in catch block, 
and we are also not providing Error middleware.

We Must use the catch block.

```ts
const register = async (req, res) => {
  try {
    const user = await userService.createUser(req.body);
    const tokens = await tokenService.generateAuthTokens(user);
    res.status(201).send({ user, tokens });
  } catch (err) {
    res.status(400).send({
      message: err.message,
    });
  }
};
```
But what is the problem with this code.

- ou are hardcoding HTTP status (400) for all errors
Not all errors are 400 Bad Request.

**Real production cases:**
Validation error → 400
Unauthorized → 401
Forbidden → 403
Not found → 404
DB failure → 500
Your code:

Note :- we are just hard coding it, is should be dynamic.
And its breaking , centralized error handling architecture.

- statusCode
error classification
operational vs programmer errors

like we are just shoing message, but we have more then that in error handling.

```ts
{
  statusCode: 409,
  message: "Email already exists",
  errorCode: "USER_EXISTS",
  isOperational: true
}
```
Logging and monitoring 

for loging we should have a centralized error handling system like

```ts
app.use((err, req, res, next) => {
  logger.error(err); // ✅ centralized logging
});
```

It duplicate the code for error handling and showing the internal error to the user.

Solution :- pass catch error to the global middleware to handle error.

```ts
const register = async (req, res, next) => {
  try {
    const user = await userService.createUser(req.body);
    const tokens = await tokenService.generateAuthTokens(user);
    res.status(201).send({ user, tokens });
  } catch (err) {
    next(err); // ✅ delegate
  }
};
```

How error middleware looks.

```ts
app.use((err, req, res, next) => {
  const statusCode = err.statusCode || 500; // if we have not specified the error status its internal server error.

  res.status(statusCode).send({
    message: err.isOperational
      ? err.message 
      : "Something went wrong",
  });
});
```

What is the problem with this code to catch the error, we are repeating the catch block. so we will use a abstration layer to it.

Solution :- catchAsync.

```ts
const catchAsync = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch((err) => next(err));
};

module.exports = catchAsync;

```

It will take a async function and return a function with resolve promise, and with catch error.


## Error handling in it. after next(err)


#### Design Goals for **errorHandler**

- Normalize all errors into a consistent structure
- Hide internal errors in production
- Log errors appropriately
- Send correct HTTP status codes

```ts
//app.js
const { errorConverter, errorHandler } = require('./middlewares/error');

// convert error to ApiError, if needed (convert the error into the api error)
//Middleware that prepares errors
app.use(errorConverter);

// handle error (handle global error, which is not the apiError)
app.use(errorHandler);

```

Here the convert error will convert with the defined api error , and if not match it will go to the next global error handler.

#### Why does errorConverter run before errorHandler?


Note 1 :- Express skips all normal middleware
It jumps ONLY to middleware with signature:

```
(err, req, res, next)
```

Note 2: if we have 2 middleware with the same priority they will handled linearly line by line.

Both are error middleware, so Express will:

1. Find the first one in order
2. Execute it
3. Move to the next

If we change the flow of execution we like

```ts
app.use(errorHandler);
app.use(errorConverter);
```
the errorConverter will not run.


### app.use(errorConverter); how we convert the error and know this is apiError.


```ts
class ApiError extends Error {
  constructor(statusCode, message, isOperational = true, stack = '') {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = isOperational;
    if (stack) {
      this.stack = stack;
    } else {
      Error.captureStackTrace(this, this.constructor);
    }
  }
}

module.exports = ApiError;

```
We are just creating a new class with the existing Error object that we have in js. 


```ts
=

let err1 = new Error("A new error occured!");

console.log("name",err1.name);
console.log("message",err1.message);
console.log(err1.stack);
console.log(err1.toString());

```


```
name Error
VM126:4 message A new error occured!
VM126:5 Error: A new error occured!
    at <anonymous>:1:12
VM126:6 Error: A new error occured!
```

>>> Error Obje :- https://medium.com/@ks.deepak07/error-object-in-js-1e433541bb4f

We are using this Error object.

and in constructor we are providing, as input.

```ts
class ApiError extends Error {
  constructor(statusCode, message, isOperational = true, stack = '') {
```

1. statusCode :- 400 ,500 more.
2. message :- "User not found"
3. isOperational :- its critical , and by default its true,

 | Type             | Example            | Action       |
| ---------------- | ------------------ | ------------ |
| Operational      | Invalid input      | Show message |
| Programmer error | undefined variable | Hide details |

Operational means , its in control and if its programmer mistake. hide it in production.

```ts
 if (config.env === 'production' && !err.isOperational) {
 // if we are at production server, and if its not a operational error, its programmer error , then now show it in production level.
    statusCode = httpStatus.INTERNAL_SERVER_ERROR;
    message = httpStatus[httpStatus.INTERNAL_SERVER_ERROR];
  }
```

like

```ts
if (config.env === 'production' && !err.isOperational) {
  message = "Internal Server Error"; 
}
```
When it will be false

**isOperational** is false for unexpected/system/programmer errors—basically, errors you did not explicitly design for.

Controller errors are safe to show to user but not app default error so unexpected error will not be displayer at production server.
It will show internal server error.

_How isOperational becomes false in your system_

```ts
if (!(error instanceof ApiError)) {
  error = new ApiError(
    statusCode,
    message,
    false, // 👈 IMPORTANT
    err.stack
  );
}
```

if its not a type of ApiError 




Note :-

```
What instanceof actually does

instanceof checks:

“Was this object created using this constructor (or its prototype chain)?”
```

It checks downword not upward, so

```ts
err instanceof ApiError // ✅ true
err instanceof Error    // ✅ true
```

Becasue we are checking the isntance of err, Error is the inner, and ApiError is outer, and we move from outer to inner and then to obj.

like 

```
Animal
  ↑
Dog
```
Dog is a instance of Animal but , Animal is not a instance of Dog.

### ApiError

```ts
class ApiError extends Error {
  constructor(statusCode, message, isOperational = true, stack = '') {
    super(message); // call parent to create error
    this.statusCode = statusCode; // add status to that error
    this.isOperational = isOperational; // if operational true else false
    if (stack) {
      this.stack = stack; // if custom stack is provided we overwrite the Error defailt stack.
    } else {
      Error.captureStackTrace(this, this.constructor); 
      // throw the erro of the current stack layer, else it will show the error from its origin and stack is created when we not handle it.
    }
  }
}

module.exports = ApiError;
```

How we will use it.

```ts
const httpStatus = require('http-status');
const { User } = require('../models');
const ApiError = require('../utils/ApiError');

/**
 * Create a user
 * @param {Object} userBody
 * @returns {Promise<User>}
 */
const createUser = async (userBody) => {
  if (await User.isEmailTaken(userBody.email)) { // return boolean value
    throw new ApiError(httpStatus.BAD_REQUEST, 'Email already taken'); // 400, message to capture it globally
  }
  return User.create(userBody);
};
```

```ts
/**
 * Check if email is taken
 * @param {string} email - The user's email
 * @param {ObjectId} [excludeUserId] - The id of the user to be excluded
 * @returns {Promise<boolean>}
 */
userSchema.statics.isEmailTaken = async function (email, excludeUserId) { // creating the static method for user
  const user = await this.findOne({ email, _id: { $ne: excludeUserId } });
  return !!user; // will return the promise !! will convert the coresponding value 
  // to the boolean (because we want boolean response not the db response wih the vlaue )
};
```

Summary :- we are handling error with next(err) and service will return the ApiError , And we just check the error if its ApiError handle it , else create other error , with internal server error.

```ts

// >>> middleware/error.js

const mongoose = require('mongoose');
const httpStatus = require('http-status');
const config = require('../config/config');
const logger = require('../config/logger');
const ApiError = require('../utils/ApiError');

const errorConverter = (err, req, res, next) => {
  let error = err;
  if (!(error instanceof ApiError)) {
    // if we have already the status code us that or check , if its the db error show bad request else show the internal server error.
    const statusCode =
      error.statusCode || error instanceof mongoose.Error ? httpStatus.BAD_REQUEST : httpStatus.INTERNAL_SERVER_ERROR;
      // if its mongoose error its a bad request, 
    const message = error.message || httpStatus[statusCode];// if we have error message use that or use message with the status code specific.
    error = new ApiError(statusCode, message, false, err.stack); // here we are defining that the error will be false
  }
  next(error);// if its the error created with apiError 
};

// eslint-disable-next-line no-unused-vars
const errorHandler = (err, req, res, next) => {
  let { statusCode, message } = err;
  if (config.env === 'production' && !err.isOperational) {
    statusCode = httpStatus.INTERNAL_SERVER_ERROR; // to 500
    message = httpStatus[httpStatus.INTERNAL_SERVER_ERROR]; // internal server error
  }

  res.locals.errorMessage = err.message;

  const response = {
    code: statusCode,
    message,
    ...(config.env === 'development' && { stack: err.stack }),// if true show include the error stack in response else not
  };

  if (config.env === 'development') {
    logger.error(err); // show full error in console if we are in development mode ,native error
  }

  res.status(statusCode).send(response);
};

module.exports = {
  errorConverter,
  errorHandler,
};

```








