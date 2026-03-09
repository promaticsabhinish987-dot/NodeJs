# Environment

Environment is a platform where engineers can build ,test and deploy our application. Our application can be in 4 different stages or environments , like

1. Development
2. Testing
3. Staging
4. Production

all stage require different configuration for running application. thats why we create multiple files for giving the configuration information acc to the stage.


Stage :- **Stage represents where the application is running in its lifecycle.**

## 1. Environment Variables

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


yes we can define the commands in package.json.

like

```json
{
  "dependencies": {
    "dotenv": "^17.3.1",
    "express": "^5.2.1"
  },
  "devDependencies": {
    "cross-env": "^7.0.3"
  },
  "scripts": {
    "dev": "cross-env NODE_ENV=development node server.js",
    "start": "cross-env NODE_ENV=production node server.js"
  }
}
```

cross-env , so that env variable work in windows also.

```ts
npm install -D cross-env
```

why we use it.

It sets environment variables before Node starts the process..

and make it working in windows also.

## 2. Types of env files

```ts
project/
 ├── src/
 ├── .env
 ├── .env.development
 ├── .env.production
 ├── .env.test
 ├── .env.local
 ├── .env.example
 ├── package.json
```

## 3. What we should put in this file.

1. Server Configuration

```ts
PORT=3000
HOST=localhost
NODE_ENV=development
```

2. Database Configuration

```ts
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=password
DB_NAME=myapp
```

3. Authentication Secrets

```ts
JWT_SECRET=mySecret
JWT_EXPIRES_IN=7d
SESSION_SECRET=randomsecret
```

4. Third Party APIs

```ts
STRIPE_API_KEY=sk_test_xxx
SENDGRID_API_KEY=xxxx
AWS_ACCESS_KEY_ID=xxxx
AWS_SECRET_ACCESS_KEY=xxxx
```

5. Feature Flags

```ts
ENABLE_CACHE=true
ENABLE_ANALYTICS=false
```
6. Application Settings

```ts
LOG_LEVEL=info
MAX_UPLOAD_SIZE=10485760
CACHE_TTL=3600
```

Q) tell me in detail about all?



## 4. .env.example File (Very Important)

why we have this file and how we can use it.
and what about gitignore.

.env.example is a template file that shows required variables without secrets.

It gives a placeholder to fill your value while, running this application for configuring the application.
it also provides the formet of data that we have to put.

```ts

PORT=
DB_HOST=
DB_PORT=
DB_USER=
DB_PASSWORD=
DB_NAME=

JWT_SECRET=
JWT_EXPIRES_IN=

STRIPE_API_KEY=

```
## 5. .gitignore and .env


Secrets should never be committed to Git.

Correct .gitignore:

```ts
# environment variables
.env
.env.*
!.env.example
```
ignore all.env files only push .env.example file to github.



## 6. how to stop our application if we miss any of the required environment variable.

Environment Validation (Production Level)

A major problem: missing env variables cause crashes later.

Solution: validate at startup.

```ts
npm install envalid
```

src/config/env.js

```ts
const dotenv = require("dotenv");
const { cleanEnv, str, num } = require("envalid");

dotenv.config();

const env = cleanEnv(process.env, {
  PORT: num({ default: 3000 }), // should be a number
  DB_HOST: str(), //should be a string
  JWT_SECRET: str(),
  NODE_ENV: str({
    choices: ["development", "production", "test"] // enum
  })
});

module.exports = env;
```


```ts
//server.js
const env = require("./src/config/env");

const express = require("express");

const app = express();

app.listen(env.PORT, () => {
  console.log(`Server running on port ${env.PORT}`);
});

```

Validators it provide.

| Validator | Type    |
| --------- | ------- |
| `str()`   | string  |
| `num()`   | number  |
| `bool()`  | boolean |
| `url()`   | URL     |
| `email()` | email   |
| `json()`  | JSON    |



```ts

const { bool, url } = require("envalid");

API_URL: url(),
FEATURE_FLAG: bool({ default: false })

```


## 7. Best Practices for Environment Variables

1. Never store secrets directly in code.

2. Use .env files only for local development.

3. Keep .env.example for documentation.

4. Use environment-specific files like .env.production.

5. Always add .env files to .gitignore.

6. Load environment variables at the start of the application.




## 8 create  a custom dotenv

```ts

const fs = require("fs")

function loadDotEnv(filePath) {

  const content = fs.readFileSync(filePath, "utf-8")

  const lines = content.split("\n")
  console.log(lines);

  for (let line of lines) {

    line = line.trim()

    // ignore empty lines and comments
    if (!line || line.startsWith("#")) continue

    const [key, value] = line.split("=")

    if (key && value) {
      console.log(key,value)
      process.env[key.trim()] = value.trim()
    }
  }
}

loadDotEnv(".env")

// module.exports = loadDotEnv
```






















