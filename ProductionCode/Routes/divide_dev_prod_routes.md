## Divide the routes acc to the environment.

Development routes and production routes.

**You are partitioning your API surface area based on environment:**

Production → minimal, secure, stable
Development → extended, debuggable, introspectable

### app.use() vs router.use() vs router.get()

1. app.use() :- is a global level route,which is accessible from any where.
2. router.use() :- is a Router level configuration works for all the methods created at that router level, used to mount other routers, and middleware to that specific router. It mounts middlewre or subrouts.
3. router.get() :- is a simple route that works with single path and a controller. defines an endpoint.


By default the router.user() is self contained and isolated, not visible , until its mounted with app.use() , it can be nested.


### Best architecture to use it.

```
src/
│
├── routes/
│   └── v1/
│       ├── auth.route.js
│       ├── user.route.js
│       ├── docs.route.js
│       └── index.js
│
├── controllers/
│   ├── auth.controller.js
│   ├── user.controller.js
│
├── services/
│   ├── auth.service.js
│   ├── user.service.js
│
├── middlewares/
│   ├── auth.middleware.js
│   ├── validate.middleware.js
│
├── models/
│   ├── user.model.js
│
├── config/
│
├── app.js
└── server.js
```

1. app.js will import the router from the index.js
2. index.js import the routes from their folder and separate them with environment
3. user.route.js defined the endpoint and middlewares and other routes of that router level.

```ts
// auth.route.js

const express = require('express');
const router = express.Router();

router.post('/register', validate(authValidation.register), authController.register);
router.post('/login', validate(authValidation.login), authController.login);
router.post('/logout', validate(authValidation.logout), authController.logout);

module.exports = router; 
```

```ts
// docs.route.js

const express = require('express');
const router = express.Router();

router.use('/', swaggerUi.serve);

module.exports = router;
```

```ts
// user.route.js
const express = require('express');
const router = express.Router();

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

```ts
// index.js
const express = require('express');
const authRoute = require('./auth.route');
const userRoute = require('./user.route');
const docsRoute = require('./docs.route');
const config = require('../../config/config');

const router = express.Router();

// default routes --> always available in every environment
const defaultRoutes = [
  {
    path: '/auth',
    route: authRoute,
  },
  {
    path: '/users',
    route: userRoute,
  },
];

const devRoutes = [
  // routes available only in development mode
  {
    path: '/docs',
    route: docsRoute,
  },
];

defaultRoutes.forEach((route) => {
  router.use(route.path, route.route);
});

/* istanbul ignore next */
if (config.env === 'development') {
  devRoutes.forEach((route) => {
    router.use(route.path, route.route);
  });
}

module.exports = router;
```

```ts
//app.js
const express = require('express');
const routes = require('./routes/v1');// or v1/index.js (default)
const app = express();

// parse json request body
app.use(express.json());

// parse urlencoded request body
app.use(express.urlencoded({ extended: true }));


// limit repeated failed requests to auth endpoints
if (config.env === 'production') {
  app.use('/v1/auth', authLimiter);// not limit at development mode
}

// v1 api routes
app.use('/api/v1', routes);

// v2 api routes
//app.use('/api/v2', routes2);

module.exports = app;

```


### What we can domore then this.


















