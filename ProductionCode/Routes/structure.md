## Basic Structure


```ts
const employeeRoute = require("express").Router();
const authMiddleware = require("../../middlewares/auth.middleware");
const authorize = require("../../middlewares/authRole.middleware");
const { getProfile, checkIn, checkOut, getMyAttendance, applyLeave,
   getMyLeaves,getSalaryConfig,
   cancelLeave } = require("./employee.controller")


employeeRoute.get("/profile", authMiddleware,authorize("employee"), getProfile);

employeeRoute.post("/attendance/checkin",authMiddleware,authorize("employee"), checkIn);
employeeRoute.post("/attendance/checkout",authMiddleware,authorize("employee"), checkOut);

employeeRoute.get("/attendance",authMiddleware,authorize("employee"), getMyAttendance);

employeeRoute.post("/leave/apply",authMiddleware,authorize("employee"), applyLeave);
employeeRoute.get("/leave",authMiddleware,authorize("employee"), getMyLeaves);
employeeRoute.delete("/leave/:id",authMiddleware,authorize("employee"), cancelLeave);

//get salary config
employeeRoute.get("/salaryConfig",authMiddleware,authorize("employee"), getSalaryConfig);
//payment history

module.exports = employeeRoute;

```

```ts
//app.js

const express=require("express");
const app=express();
const authRoute=require("./routes/auth/auth.route")
const adminRoute=require("./routes/admin/admin.route")
const employeeRoute=require("./routes/employee/employee.route")
const errorHandler=require("./middlewares/error.middleware")
const cookieParser=require("cookie-parser")
const cors=require("cors")


app.use(express.json())
app.use(cookieParser())
app.use(cors({
  origin: 'http://localhost:4200',
  credentials: true
}));


app.use("/api/v1/auth/authRoute",authRoute);
app.use("/api/v1/admin",adminRoute)
app.use("/api/v1/employee",employeeRoute)

// global error handler
app.use(errorHandler)

app.get("/",(req,res)=>{
   res.send("hello world")
})


module.exports = app;


```


## Limitations and improvement

1. Checking the required fields like name email in every controller, validating password in every controller, and validating its data type in every controller.


Solution :- Then what we can do now, can we isolate it at single place and use it at route level,like validating the schema of input. 

Lets try to improve it.


- Centralized validation

```
validate(schema)
```


But how we get schema and will create validate function.

Validate function should accept different type of schema like register,login and more.


```ts
router.post('/register',
  validate(authValidation.register),
  authController.registera
);
```

At scale, you don’t manually validate fields. You use a schema validator.

```
Joi (very popular, expressive)
Zod (modern, TS-friendly)
```
We can validate 3 things 


```
req.body
req.query
req.params
```

_valiations/user.validation.js_

```ts
const Joi = require("joi");

const createUser = {
  body: Joi.object({
    name: Joi.string().min(3).required(),
    email: Joi.string().email().required(),
    age: Joi.number().min(18).optional(),
  }),
};

const getUser = {
  params: Joi.object({
    userId: Joi.string().hex().length(24).required(), // Mongo ObjectId
  }),
};

const listUsers = {
  query: Joi.object({
    page: Joi.number().min(1).default(1),
    limit: Joi.number().min(1).max(100).default(10),
  }),
};

module.exports = {
  createUser,
  getUser,
  listUsers,
};
```

These are the schema , now how we can use these schemas.
How we can validate this schema. and return a middleware.
We will return a middleware that will validate dyamnically.


```ts
const validate = (schema) => {
  return (req, res, next) => {
    const errors = [];

    if (schema.body) {
      const { value, error } = schema.body.validate(req.body);
      if (error) errors.push(error.details[0].message);
      else req.body = value;
    }

    if (schema.params) {
      const { value, error } = schema.params.validate(req.params);
      if (error) errors.push(error.details[0].message);
      else req.params = value;
    }

    if (schema.query) {
      const { value, error } = schema.query.validate(req.query);
      if (error) errors.push(error.details[0].message);
      else req.query = value;
    }

    if (errors.length) {
      return res.status(400).json({
        success: false,
        message: errors.join(", "),
      });
    }

    next();
  };
};
```

Use these Schema validator in your route.

```ts
const express = require("express");
const router = express.Router();

const validate = require("../middlewares/validate");
const userValidation = require("../validations/user.validation");

router.post(
  "/users",
  validate(userValidation.createUser),
  (req, res) => {
    res.send("User created");
  }
);

router.get(
  "/users/:userId",
  validate(userValidation.getUser),
  (req, res) => {
    res.send("User fetched");
  }
);

router.get(
  "/users",
  validate(userValidation.listUsers),
  (req, res) => {
    res.send("Users list");
  }
);

module.exports = router;
```

Not blindly validate , validate only required field.  and those which we use the most.

Note :- we can also add our own custom validator in JOI.

If we want to write our own error and not want to expose the build in errors.
















