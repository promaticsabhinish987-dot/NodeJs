


# 1️⃣ Unauthorized Access to Private Routes

## 🔴 Attack

User directly calls:

```
GET /api/private-data
```

Without being logged in.

Or worse:
They steal someone’s JWT token and replay it.

---

## 🧠 Why This Happens (First Principle)

HTTP is stateless.
Server does not remember who the user is unless you verify identity on every request.

If you trust frontend authentication → you are already hacked.

---

## ✅ Solution

1. Authenticate every request
2. Validate JWT signature
3. Check token expiration
4. Attach user to request
5. Optionally implement token rotation

---

## 🛠 Tool

* `jsonwebtoken`
* `httpOnly` cookies
* Middleware

---

## 🧱 Production Code

### Auth Middleware

```js
const jwt = require("jsonwebtoken");

const authMiddleware = (req, res, next) => {
  try {
    const token = req.cookies.token; // httpOnly cookie

    if (!token) {
      return res.status(401).json({ message: "Unauthorized" });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ message: "Invalid or expired token" });
  }
};
```

### Private Route

```js
app.get("/api/private-data", authMiddleware, async (req, res) => {
  res.json({ message: "Protected data", user: req.user });
});
```

---

## 🔐 Extra Hardening

* Set cookie flags:

```js
res.cookie("token", token, {
  httpOnly: true,
  secure: true,
  sameSite: "strict",
});
```

---

# 2️⃣ SQL Injection / NoSQL Injection

## 🔴 Attack

User sends:

```json
{
  "email": { "$ne": null }
}
```

If you pass directly into Mongo query:

```js
User.find(req.body)
```

Attacker logs in without password.

---

## 🧠 Root Cause

You trusted user input directly in query execution.

---

## ✅ Solution

* Validate input
* Use schema validation
* Never pass raw req.body to DB

---

## 🛠 Tool

* `Joi` or `Zod`
* Mongoose schema strict mode

---

## 🧱 Production Example

```js
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

---

# 3️⃣ Password Cracking

## 🔴 Attack

Database leaks. Passwords stored as plain text.

Attacker reads:

```
123456
password
admin123
```

Game over.

---

## 🧠 Root Cause

Passwords must never be reversible.

---

## ✅ Solution

Hash + Salt.

---

## 🛠 Tool

* `bcrypt`

---

## 🧱 Production Code

```js
const bcrypt = require("bcrypt");

const hashedPassword = await bcrypt.hash(password, 12);
```

During login:

```js
const isMatch = await bcrypt.compare(password, user.password);
if (!isMatch) {
  return res.status(401).json({ message: "Invalid credentials" });
}
```

---

# 4️⃣ Brute Force Login Attack

## 🔴 Attack

Bot tries:

```
admin@gmail.com
admin1@gmail.com
admin2@gmail.com
```

10000 attempts per minute.

---

## 🧠 Why

No rate limiting.

---

## ✅ Solution

Rate limit requests.

---

## 🛠 Tool

* `express-rate-limit`

---

## 🧱 Production Code

```js
const rateLimit = require("express-rate-limit");

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: "Too many login attempts"
});

app.use("/login", loginLimiter);
```

---

# 5️⃣ Cross-Site Scripting (XSS)

## 🔴 Attack

User posts:

```html
<script>alert("Hacked")</script>
```

When rendered → executes in browser.

---

## 🧠 Root Cause

You rendered unescaped user input.

---

## ✅ Solution

* Sanitize input
* Escape output

---

## 🛠 Tool

* `helmet`
* `xss-clean`

---

## 🧱 Production Setup

```js
const helmet = require("helmet");
app.use(helmet());
```

---

# 6️⃣ CSRF Attack

## 🔴 Attack

User logged in.

Attacker sends hidden form:

```
POST /api/transfer-money
```

Browser automatically attaches cookies.

Money transferred.

---

## 🧠 Why

Cookies are automatically attached to cross-site requests.

---

## ✅ Solution

CSRF token validation.

---

## 🛠 Tool

* `csurf`

---

## 🧱 Production Code

```js
const csrf = require("csurf");

app.use(csrf({ cookie: true }));

app.get("/form", (req, res) => {
  res.json({ csrfToken: req.csrfToken() });
});
```

---

# 7️⃣ Data Exposure

## 🔴 Attack

API returns:

```json
{
  "password": "...",
  "resetToken": "...",
  "role": "admin"
}
```

Sensitive data leaked.

---

## 🧠 Root Cause

Over-fetching and over-sending.

---

## ✅ Solution

Use projection.

---

## 🛠 Tool

Mongoose `.select()`

---

```js
User.findById(id).select("-password -resetToken");
```

---

# 8️⃣ Denial of Service (DoS)

## 🔴 Attack

Send 1GB JSON body repeatedly.

Server memory crashes.

---

## 🧠 Why

Unlimited body parsing.

---

## ✅ Solution

Limit payload size.

---

## 🛠 Tool

```js
app.use(express.json({ limit: "10kb" }));
```

---

# 9️⃣ Database Security

## 🔴 Attack

MongoDB open to public internet.

Anyone connects.

---

## ✅ Solution

* Whitelist IP
* Use auth
* Disable remote root login
* Use private VPC
* Enable TLS

---

## Mongo Connection Secure

```js
mongoose.connect(process.env.DB_URI, {
  ssl: true,
  authSource: "admin"
});
```

---

# 🔟 Environment Variable Leakage

## 🔴 Attack

Commit `.env` to GitHub.

Attacker steals secret.

---

## ✅ Solution

* `.gitignore`
* Use secret manager (AWS Secrets Manager)

---

# 1️⃣1️⃣ Role Based Authorization

## 🔴 Attack

Normal user hits:

```
DELETE /api/admin/delete-user
```

---

## ✅ Solution

Authorization middleware.

---

```js
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ message: "Forbidden" });
    }
    next();
  };
};

app.delete("/admin", authMiddleware, authorize("admin"), handler);
```

---

# 🧱 Final Secure Stack (Production)

| Layer      | Tool               |
| ---------- | ------------------ |
| HTTPS      | Nginx + TLS        |
| Headers    | helmet             |
| Auth       | JWT + httpOnly     |
| Password   | bcrypt             |
| Rate limit | express-rate-limit |
| Validation | Joi                |
| CSRF       | csurf              |
| DB         | Private network    |
| Logs       | Winston            |
| Monitoring | Prometheus         |

---

# 🔥 Critical Production Mindset

Security is not one feature.

It is:

```
Defense in depth
```

You assume:

* Client is compromised
* Network is compromised
* Database might leak
* Tokens might be stolen
