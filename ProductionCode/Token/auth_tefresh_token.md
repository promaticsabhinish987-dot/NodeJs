# Access Token , Refresh Token , Rotation.

- Access token , and Refresh token we use for secuty purpose, validity of access token is 15min and validity of Refresh token is 7 day to 1 year.
- When you login, server deletes all the refresh token , and generates new access token and refresh token and save refresh token in the db.
- And when you request to a route request goes to a middleware and allow resource if valid access token.
- If invalid access token, unauthorised.
- Client then request to refresh toke, and server checks exiery in db, if its not expired, it will delete all the old refresh token, and generate the new one access token and refresh token and save refresh token in db.
- If refreshes the refresh token every 15 min, but if the refresh token expires like in 7 day, you have to agian login.
- Problem with only using access token is that we have to login after 15 min every time, but with the refresh token we just have to request refresh token and if gives us fresh login.



## Example

>> models/token.model.js

```ts
const mongoose = require('mongoose');
const { toJSON } = require('./plugins');
const { tokenTypes } = require('../config/tokens');

const tokenSchema = mongoose.Schema(
  {
    token: {
      type: String, //Token itself
      required: true,
      index: true,
    },
    user: {
      type: mongoose.SchemaTypes.ObjectId, //Owner of the token
      ref: 'User',
      required: true,
    },
    type: {
      type: String,
      enum: [tokenTypes.REFRESH, tokenTypes.RESET_PASSWORD, tokenTypes.VERIFY_EMAIL],
      required: true,
    },
//     | Type           | Behavior            |
// | -------------- | ------------------- |
// | REFRESH        | long-lived, rotated |
// | RESET_PASSWORD | one-time use        |
// | VERIFY_EMAIL   | one-time use        |

    expires: {
      type: Date,
      required: true, //tokenSchema.index({ expires: 1 }, { expireAfterSeconds: 0 }); can use TTL index
    },
    blacklisted: {
      type: Boolean,
      default: false, //Logout (without deleting history)
// Security incident tracking (we can check the users who req refresh token)
    },
  },
  {
    timestamps: true,
  }
);

// add plugin that converts mongoose to json
tokenSchema.plugin(toJSON);

/**
 * @typedef Token
 */
const Token = mongoose.model('Token', tokenSchema);

module.exports = Token;

```

>> services/token.service.js

When you login.

```ts
/**
 * Generate auth tokens
 * @param {User} user
 * @returns {Promise<Object>}
 */
const generateAuthTokens = async (user) => {
  //moment id date formetor
  const accessTokenExpires = moment().add(config.jwt.accessExpirationMinutes, 'minutes');
  const accessToken = generateToken(user.id, accessTokenExpires, tokenTypes.ACCESS);

  const refreshTokenExpires = moment().add(config.jwt.refreshExpirationDays, 'days');
  const refreshToken = generateToken(user.id, refreshTokenExpires, tokenTypes.REFRESH);
  await saveToken(refreshToken, user.id, refreshTokenExpires, tokenTypes.REFRESH); 

  return {
    access: {
      token: accessToken,
      expires: accessTokenExpires.toDate(),
    },
    refresh: {
      token: refreshToken,
      expires: refreshTokenExpires.toDate(),
    },
  };
};

// after saving the refresh token in db return it.
```

```ts

/**
 * Generate token
 * @param {ObjectId} userId
 * @param {Moment} expires
 * @param {string} type
 * @param {string} [secret]
 * @returns {string}
 */
const generateToken = (userId, expires, type, secret = config.jwt.secret) => {
  const payload = {
    sub: userId,
    iat: moment().unix(), //initialized at
    exp: expires.unix(), // will expire at
    type,
  };
  return jwt.sign(payload, secret);

```


```ts
/**
 * Save a token in db
 * @param {string} token
 * @param {ObjectId} userId
 * @param {Moment} expires
 * @param {string} type
 * @param {boolean} [blacklisted]
 * @returns {Promise<Token>}
 */
const saveToken = async (token, userId, expires, type, blacklisted = false) => {
  const tokenDoc = await Token.create({
    token,
    user: userId,
    expires: expires.toDate(),
    type,
    blacklisted,
  });
  return tokenDoc;
};
```

```ts
/**
 * Verify token and return token doc (or throw an error if it is not valid)
 * @param {string} token
 * @param {string} type
 * @returns {Promise<Token>}
 */
const verifyToken = async (token, type) => {
  const payload = jwt.verify(token, config.jwt.secret);
  // for refresh token and more find that token if exist return its doc if not then return the error refresh token not exist
  const tokenDoc = await Token.findOne({ token, type, user: payload.sub, blacklisted: false });
  if (!tokenDoc) {
    throw new Error('Token not found');
  }
  return tokenDoc;
};
```



>> controller.auth.conroller.js

/login

```ts
const login = catchAsync(async (req, res) => {
  const { email, password } = req.body;
  const user = await authService.loginUserWithEmailAndPassword(email, password);
  const tokens = await tokenService.generateAuthTokens(user); // generate access token and refresh token and send it to the user
  res.send({ user, tokens });
});
```

```ts
router
  .route('/')
  .post(auth('manageUsers'), validate(userValidation.createUser), userController.createUser)
  .get(auth('getUsers'), validate(userValidation.getUsers), userController.getUsers);

router
  .route('/:userId')
  .get(auth('getUsers'), validate(userValidation.getUser), userController.getUser)
  .patch(auth('manageUsers'), validate(userValidation.updateUser), userController.updateUser)
  .delete(auth('manageUsers'), validate(userValidation.deleteUser), userController.deleteUser);

module.exports = router;
```

/getUsers

```ts
const jwt = require('jsonwebtoken');

const auth = (requiredRole) => {
  return (req, res, next) => {
    try {
      // 1. Get token from header
      const token = req.headers.authorization?.split(' ')[1];

      if (!token) {
        return res.status(401).json({ message: 'No token' });
      }

      // 2. Verify token
      const decoded = jwt.verify(token, 'your-secret');

      // 3. Attach user
      req.user = decoded;

      // 4. Role check (optional)
      if (requiredRole && decoded.role !== requiredRole) {
        return res.status(403).json({ message: 'Forbidden' });
      }

      next();
    } catch (err) {
      return res.status(401).json({ message: 'Unauthorized' });
    }
  };
};

module.exports = auth;
```


or


```ts
const passport = require('passport');
const httpStatus = require('http-status');
const ApiError = require('../utils/ApiError');
const { roleRights } = require('../config/roles');

const verifyCallback = (req, resolve, reject, requiredRights) => async (err, user, info) => {
  if (err || info || !user) {
    return reject(new ApiError(httpStatus.UNAUTHORIZED, 'Please authenticate'));
  }
  req.user = user;

  if (requiredRights.length) {
    const userRights = roleRights.get(user.role);
    const hasRequiredRights = requiredRights.every((requiredRight) => userRights.includes(requiredRight));
    if (!hasRequiredRights && req.params.userId !== user.id) {
      return reject(new ApiError(httpStatus.FORBIDDEN, 'Forbidden'));
    }
  }

  resolve();
};

const auth = (...requiredRights) => async (req, res, next) => {
  return new Promise((resolve, reject) => {
    passport.authenticate('jwt', { session: false }, verifyCallback(req, resolve, reject, requiredRights))(req, res, next);
//function currying / higher-order function invocation (practically: a function returning another function, then immediately executing it).
  })
    .then(() => next())
    .catch((err) => next(err));
};

module.exports = auth;

``




















