# Password Cracking

Database leaks. Passwords stored as plain text.

Root cause :- Passwords must never be reversible.

Solution :- Hash + Salt.


🛠 Tool :- bcrypt

```ts
//register in production

const bcrypt = require("bcrypt");

const hashedPassword = await bcrypt.hash(password, 12);


//login
const isMatch = await bcrypt.compare(password, user.password);
if (!isMatch) {
  return res.status(401).json({ message: "Invalid credentials" });
}

```

Note :- hasing is not reversible , same input , gives same output, but encryption is not like this we can reverse it with key.

only plain hasing is not secure , if we not use salt.

Attackers precompute billions of hashes.

These are called **rainbow tables**.

Salt = random value added to password before hashing.

```ts
hash(password + randomSalt)
```
two users have same password but because of salt , both encrypted code will be different.

bcrypt is slow by nature , and its intentional, so that a attacker can not use bruteforce, quickly. it uses sh256, db5 encryption technique.

```ts

bcrypt.hash(password, 12) //12 is here cost factor.
//12 = 2^12 iterations.

$algorithm$cost$salt+hash

eg

$2b$12$e9Wz...hashedvalue...

```


## Best practice

1. Enforce Strong Password Policy

Minimum:

8–12 characters

Mix of types

Or better: long passphrases


if password is strong its not easy to crack with normal dictonary attack , mix password makes difficult to generate that big , bruteforce keys.


2. Rate Limit Login Attempts


```ts
express-rate-limit
```
5 attempts per 15 minutes.

Block account for some time, and require captcha.


3. Add 2FA (Critical for High Security)

Two factor authentication , like OTP and more. 



```ts
const rateLimit = require("express-rate-limit");

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // limit each IP to 5 login attempts per window
  message: {
    message: "Too many login attempts. Try again after 15 minutes."
  },
  standardHeaders: true, // Return rate limit info in headers
  legacyHeaders: false,  // Disable X-RateLimit-* headers
});
```

```ts
app.post("/login", loginLimiter, loginController); //apply only in login
```

Ip can be changed multiple time, so we also use email to uniquely identify.

```ts
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  keyGenerator: (req) => {
    return req.body.email + "-" + req.ip;
  },
  message: {
    message: "Too many login attempts. Try again later."
  },
});
```
It will fail for multiple instance server 

so use redish

```ts
npm install rate-limit-redis redis

const RedisStore = require("rate-limit-redis");
const { createClient } = require("redis");

const redisClient = createClient({
  url: "redis://localhost:6379",
});
redisClient.connect();

const loginLimiter = rateLimit({
  store: new RedisStore({
    sendCommand: (...args) => redisClient.sendCommand(args),
  }),
  windowMs: 15 * 60 * 1000,
  max: 5,
  keyGenerator: (req) => req.body.email + "-" + req.ip,
  standardHeaders: true,
  legacyHeaders: false,
});
```

If multiple failure ,increase data

```ts

if (user.failedAttempts >= 5) {
   user.lockUntil = Date.now() + 15 * 60 * 1000;
}


// before login check

if (user.lockUntil && user.lockUntil > Date.now()) {
   return res.status(403).json({ message: "Account temporarily locked" });
}


```


