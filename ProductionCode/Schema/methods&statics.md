# Methods & Statics

**Methods are for Instance level behaviour(doc level operation).**
**Statics for are class level behaviour (collection level operation)**


## Methods

```ts
const userSchema = new mongoose.Schema({
  name: String,
  email: String
});

// instance method
userSchema.methods.getDisplayName = function () {
  return `${this.name} (${this.email})`;
};
```

Use

```ts
const user = await User.findById(id);
console.log(user.getDisplayName());
```

Example :-

1. Password comparison
2. formating field

## Statics


```ts
userSchema.statics.findByEmail = function (email) {
  return this.findOne({ email });
};
```

```ts
const user = await User.findByEmail("test@gmail.com");
```


## Can combine both

```ts
userSchema.methods.deactivate = async function () {
  this.isActive = false;
  await this.save();
};

userSchema.statics.deactivateByEmail = async function (email) {
  const user = await this.findOne({ email });
  if (user) await user.deactivate();
};
```

## But if we can do the same thing with the javascirpt then why we are using the statics and methods at data level layer.

If multiple services uses it define it in model, to define the single source of truth.

```
Data + Behaviour
```

Stop putting nonsense thigs in service.

## Examples


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

/**
 * Check if password matches the user's password
 * @param {string} password
 * @returns {Promise<boolean>}
 */
userSchema.methods.isPasswordMatch = async function (password) {
  const user = this;
  return bcrypt.compare(password, user.password);
};
```


```ts
const createUser = async (userBody) => {
  if (await User.isEmailTaken(userBody.email)) {
    throw new ApiError(httpStatus.BAD_REQUEST, 'Email already taken');
  }
  return User.create(userBody);
};
```
```ts
/**
 * Update user by id
 * @param {ObjectId} userId
 * @param {Object} updateBody
 * @returns {Promise<User>}
 */
const updateUserById = async (userId, updateBody) => {
  const user = await getUserById(userId);
  if (!user) {
    throw new ApiError(httpStatus.NOT_FOUND, 'User not found');
  }
  if (updateBody.email && (await User.isEmailTaken(updateBody.email, userId))) {
    throw new ApiError(httpStatus.BAD_REQUEST, 'Email already taken');
  }
  Object.assign(user, updateBody);
  await user.save(); // to run validators 
  return user;
};
```

```ts
const loginUserWithEmailAndPassword = async (email, password) => {
  const user = await userService.getUserByEmail(email);
  if (!user || !(await user.isPasswordMatch(password))) { // if we have no user and if user is avaliable but its password not match 
    throw new ApiError(httpStatus.UNAUTHORIZED, 'Incorrect email or password');
  }
  return user;
};
```

## Where you must use these

Here’s a **tight, decision-oriented list** of common cases with minimal code.

---

# 🔹 1. Authentication

### ✅ Method (document behavior)

```js
userSchema.methods.comparePassword = function (password) {
  return bcrypt.compare(password, this.password);
};
```

### ✅ Static (query)

```js
userSchema.statics.findByEmail = function (email) {
  return this.findOne({ email });
};
```

---

# 🔹 2. E-commerce Order

### ✅ Method

```js
orderSchema.methods.getTotal = function () {
  return this.items.reduce((sum, i) => sum + i.price * i.qty, 0);
};
```

### ✅ Static

```js
orderSchema.statics.getByUser = function (userId) {
  return this.find({ user: userId });
};
```

---

# 🔹 3. Social Media Post

### ✅ Method

```js
postSchema.methods.likeCount = function () {
  return this.likes.length;
};
```

### ✅ Static

```js
postSchema.statics.getTrending = function () {
  return this.find().sort({ likes: -1 }).limit(10);
};
```

---

# 🔹 4. User Status

### ✅ Method

```js
userSchema.methods.deactivate = function () {
  this.isActive = false;
  return this.save();
};
```

### ✅ Static

```js
userSchema.statics.getInactive = function () {
  return this.find({ isActive: false });
};
```

---

# 🔹 5. Payments

### ✅ Method

```js
paymentSchema.methods.isSuccess = function () {
  return this.status === "SUCCESS";
};
```

### ✅ Static

```js
paymentSchema.statics.getFailed = function () {
  return this.find({ status: "FAILED" });
};
```

---










