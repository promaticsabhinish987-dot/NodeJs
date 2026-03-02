# SQL Injection / NoSQL Injection

You trusted user input directly in query execution.Never trust user input data, always validate it for db query.

Attack :- SQL injection is a web security vulnerability that allows attackers to interfere with queries an application makes to its database. By injecting malicious SQL code into input fields, attackers can bypass authentication, view, modify, or delete sensitive data, and sometimes gain full control over the database server.


### mongodb if uses

```ts
User.find({ email: email, password: password })
```
If backend accepts raw JSON input:


```ts

{
  "email": { "$ne": null },
  "password": { "$ne": null }
}

```

Query becomes:

```ts

User.find({
  email: { $ne: null },
  password: { $ne: null }
})

```

```ts
  //verify password
    const isMatch=await bcrypt.compare(password,isRegisterd.passwordHash)
//this step in login login user, in two steps, 1st find user by email then check is user exist then compare their bcrypt bssword , its safe. thats why we use it.

```
```ts

User.findOne({
  email: { $ne: null },
  password: { $ne: null }
})

//this login method is not safe because we have one step, to be true, and nosql attack is poissible


```

If you want to stop before implementing the query use type safty, 

```ts

if (typeof email !== "string" || typeof password !== "string") {
  return res.status(400).json({ message: "Invalid input type" });
}

```
it accept only string not object.
It will block 

```ts
{ "email": { "$ne": null } }
```

### Use express-mongo-sanitize

```
npm install express-mongo-sanitize
```

```ts
const mongoSanitize = require("express-mongo-sanitize");
app.use(mongoSanitize());
```

It removes keys that start with $ or contain .

so 

```ts
{ "$ne": null }

//will become

{} // becaus any object start with $ will be removed from query. beause mongodb know its a sql injection.

```
It will block any type of injection ,Injection blocked. 

### Use Mongoose Schema Strict Mode

Mongoose default strict mode prevents unknown fields.

```ts
mongoose.set("strictQuery", true);
```
### Never Trust req.body Directly


Use validation library:

1. Zod

2. Joi

3. express-validator

```ts

const schema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required()
});

```
validate before db query.

## noSQl injection free login.


```ts

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

//stop the sql command here.

    if (typeof email !== "string" || typeof password !== "string") {
      return res.status(400).json({ message: "Invalid input type" });
    }

    const user = await User.findOne({ email });

    if (!user) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);

    if (!isMatch) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    // token generation continues...
 const token=jwt.sign(
      {id:isRegisterd._id},
      JWT_SECRET,
      {expiresIn:"7d"}
    )

 res.cookie("token", token, {
    httpOnly: true,        // prevent JS access (XSS protection)
    secure: false,         // true in production (HTTPS only)
    sameSite: "lax",       // important for cross-origin
    maxAge: 1000 * 60 * 60 * 24, // 1 day
  });


     res.status(200).json({message:"you are successfully login", data : isRegisterd})

  } catch (err) {
    res.status(500).json({ message: "Internal server error" });
  }
};

```
































Types of SQL Injection

1. Classic (Tautology Injection)

```ts
' OR '1'='1//used to bypass login.
```

2. Union-Based Injection ,Attacker appends another query.

```ts

' UNION SELECT password FROM users -- //now attacker can run any query to your data base to get your password.

```

3. Error-Based Injection

```ts
' ORDER BY 10 --
```

It it throw error schema will expose.

all works with dynamic query changes, so always have static query.


SQL injection is the placement of malicious code in SQL statements, via web page input.

Solution :- 

1. Validate input
2. Use schema validation
3. Never pass raw req.body to DB

### 🛠 Tool

1. Joi or Zod

2. Mongoose schema strict mode

```ts

const Joi = require("joi");

const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().min(6).required()
});

app.post("/login", async (req, res) => {
  const { error } = loginSchema.validate(req.body);
  if (error) {
    return res.status(400).json({ message: "Invalid input" });
  }

  const user = await User.findOne({ email: req.body.email });
});

```
