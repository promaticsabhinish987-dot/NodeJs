# Environment

Environment is a platform where engineers can build ,test and deploy our application. Our application can be in 4 different stages or environments , like

1. Development
2. Testing
3. Staging
4. Production

all stage require different configuration for running application. thats why we create multiple files for giving the configuration information acc to the stage.


Stage :- **Stage represents where the application is running in its lifecycle.**

## Environment Variables

Each file define some variables which we call environment variables.
**Environment variables** are key-value pairs stored outside the application code that configure how the application behaves in different environments.

They allow the same codebase to run in multiple environments without changing the source code.


How we can define these variables.

```ts
PORT=3000
DB_HOST=localhost
JWT_SECRET=mysecret
```

How we can access it 

```ts

//install dotenv

>>npm i dotenv

//require it

require("dotenv").config();

//get environment variable
console.log(process.env.PORT)
```
#### What is here dotenv?

```ts
require("dotenv").config();
```
What happens internally:

1. Node starts the application.

2. dotenv.config() reads the .env file.

3. It parses each line (KEY=VALUE).

4. It attaches them to process.env.


### What is process.env?

process is a global object in Node.js representing the current running Node.js process.

One property of this object is:

```ts
process.env
```

**process.env** is an object that contains all environment variables available to the running Node process.

How it looks like?


```ts
process.env = {
  PORT: "3000",
  DB_HOST: "localhost",
  JWT_SECRET: "mysecret",
  PATH: "...",
  HOME: "...",
}
```
What does process.env.PORT mean?
Access the environment variable named PORT from the current Node.js process environment.

```
console.log(process.env.PORT);

//if its undefined means that value not exist as env variable

```

4 Reason to use environment variable 

| Reason                   | Explanation                                                          |
| ------------------------ | -------------------------------------------------------------------- |
| Security                 | Secrets like API keys or JWT secrets are not stored in code          |
| Environment flexibility  | Same code runs in dev, staging, production                           |
| Configuration separation | Code and configuration are separated                                 |
| Deployment friendly      | Platforms like Docker, Kubernetes, AWS rely on environment variables |


#### What is the meaning of process.env.POR and what it does?
=> process is a global object in node js.
Defination :- process is an object referencing to the actual computer process running a Node program and allows for access to command-line arguments and much more.

or

The term process is an operating system term and not a node.js term. The process module in node.js is a central place where the designers of node.js put a bunch of methods that relate to the overall process such as process.exit() which exits the application and thus stops the process or process.env which gives you access to the environment variables for your program or process.argv which gives you access to the command line arguments your process was started with and so on... These are all things that apply to your overall program running.



#### How the .config() knows which file to set as process.env

dotenv , reads the .env file from root directory like.

```ts
dotenv.config({
  path: path.resolve(process.cwd(), ".env")
});
```
And it create a object like.

```ts
{
  PORT: "3000",
  DB_HOST: "localhost"
}
```
and merges with the process.env.

and we can now access it from anywhere in our application with process.env.PORT.


#### Can we explicitly define which file to use here.

yes. 

suppose we have  folder structure like.

```ts

project
 ├── config
 │    ├── .env.development
 │    ├── .env.production
 │    └── .env.test
 └── src

```

```ts

require("dotenv").config({
  path: "./config/.env.development"
});

```


### Can we make it dynamic.

Yes . as we know process is also used to read the command line arguments, so while running node js application we can define the environment, like stage in which we want to run our application , and acc to that command line information it pick the file.

A common pattern: for dynamic environment selection.

suppose we have files like.

```ts
.env.development
.env.production
.env.staging
```
```ts
const dotenv = require("dotenv");

const env = process.env.NODE_ENV || "development";

dotenv.config({
  path: `.env.${env}`
});
```

```ts
>>> NODE_ENV=production node server.js
```

where we should do it , in separate file, or in server.js or in app.js.

1. Put it in the entry file, like server.js or app.js

```ts
// server.js
require("dotenv").config();

const express = require("express");

const app = express();

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```
server.js is the first file Node executes, so environment variables are loaded before the rest of the application.

2. Create a Dedicated Config File (Better Architecture)

```ts

// folder structure
project
│
├── src
│   ├── config
│   │   └── env.js
│   ├── app.js
│   └── server.js
│
├── .env
└── package.json

//config.env.js
const dotenv = require("dotenv");

dotenv.config();

module.exports = {
  PORT: process.env.PORT,
  DB_HOST: process.env.DB_HOST,
  JWT_SECRET: process.env.JWT_SECRET
};


//server.js

const config = require("./config/env");

console.log(config.PORT);

```
Its easy to mange and separte from or applicaiton code and centralized.


Note :- dotenv does not override existing PORT or env varibale , it has higher priority for OS deined , like command line env details.

```ts
PORT=5000 node server.js
```


### can we do it in short , by unsing package.json scripts.



































