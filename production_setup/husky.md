# simple setup , run test.js script using husky at pre-commit


### ======================== basic setup start ===========================


step 1 :- initialize git repository 

```ts
>> git init  // this will create a folder .git
```

step 2 :- Install husky and lintstaged as dev dependency  (install after git initialization)

```ts
>> npm i husky lint-staged -D
```

step 3 :- Initialize husky folder

```ts
>> npx husky init

// will create folder
project
│
├─ test.js
├─ package.json
└─ .husky
    ├─ pre-commit
    └─ _
```


step 4 :- write script to run test.js


package.json
```json
{
  "name": "demo",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "test": "node test.js", // here
    "prepare": "husky"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "description": "",
  "devDependencies": {
    "husky": "^9.1.7",
    "lint-staged": "^16.3.2"
  }
}

```

step 5 :- update pre-commit to run the test.js script

```sh
npm test
# write command here like test.js or run a json script
```

step 6 :- when you sommit test.js will run 


```ts
git commit -m "husky"

> demo@1.0.0 test
> node test.js

Running pre-commit checks...
All checks passed!
On branch master
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   .husky/pre-commit
        modified:   package.json

no changes added to commit (use "git add" and/or "git commit -a")
```

And if you fail you can not commit.

Note :- if you will node add .gitignore it will show in git status all the nodemodule files.

### ======================== basic setup end ===========================



# Husky?
Husky allows you to run scripts automatically when certain Git events happen.

Git has something called hooks:

| Hook       | When it runs                   |
| ---------- | ------------------------------ |
| pre-commit | before a commit                |
| commit-msg | before commit message accepted |
| pre-push   | before pushing to remote       |
| post-merge | after merging                  |


Husky lets you attach scripts to these hooks easily.

We can run any script at different stages, in git lifecycle.

Without it , un structured code, code with error might push, which later become a mess,thats why we run a script to push only the correct formet and error free code to the github.

like 

```ts
git commit
      ↓
Husky pre-commit hook runs
      ↓
run lint + format + tests
      ↓
if fail → commit blocked
```

So bad code never enters the repository.


lint-staged runs checks on staged files

Install husky and lint-staged to run script for staged files only.
```ts
npm install --save-dev husky lint-staged

//initialize husky
npx husky init

// this command will create
.husky/
   pre-commit

```


```json
//packaeg.json
{
  "lint-staged": {
    "*.js": [
      "eslint --fix",
      "prettier --write"
    ]
  }
}

//run every time when do 
```

###  Why Companies Use This

Benefits:

1. Prevent bad commits

Broken code never enters repository.

2. Consistent code style

Everyone's code looks same.

3. Faster CI pipelines

Because many errors are fixed locally.

4. Developer discipline

Forces good coding practices.


### proper setup


Install all required packages.

```ts
npm install --save-dev husky lint-staged eslint prettier
```

Initialize Husky

```ts
npx husky init


//this will create
.husky/
   pre-commit

```

adds this script in package.json


```ts
"prepare": "husky"

//This ensures husky installs automatically after npm install.
```


Project structure will be

```ts
project
│
├── .husky
│    └── pre-commit
│
├── src
│    └── app.js
│
├── package.json
├── .eslintrc.json
├── .prettierrc
```

Setup ESLint

```ts
>>>npx eslint --init

.eslintrc.json

{
  "env": {
    "node": true,
    "es2022": true
  },
  "extends": "eslint:recommended",
  "parserOptions": {
    "ecmaVersion": "latest"
  },
  "rules": {
    "no-unused-vars": "warn",
    "no-console": "off",
    "semi": ["error", "always"]
  }
}

```

Setup pretier

```ts
.prettierrc

{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "all"
}
```

Configure lint-staged

Inside package.json


```ts
{
  "lint-staged": {
    "*.js": [
      "eslint --fix",
      "prettier --write"
    ]
  }
}


//run this command on staged
only staged JS files
      ↓
run eslint fix
run prettier format
```






