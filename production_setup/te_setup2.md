## Typescript setup

step 1 :- Install typescript as dev dependency

```ts
>> npm i typescript -D
```

step 2 :- create a folder tsconfig.json (for typescript configuration)

or use a command 

```ts
>> npx tsc --init
```

step 3 :- update this file and create input and output directory

```json
{
  "compilerOptions": {

    /* Specifies the root folder where TypeScript source files are located */
    "rootDir": "./src",

    /* Specifies the output folder where compiled JavaScript files will be placed */
    "outDir": "./dist",

    /* Sets the JavaScript version the TypeScript compiler will generate */
    "target": "ES2020",

    /* Defines the module system used in the compiled output (CommonJS for Node.js) */
    "module": "commonjs",

    /* Enables all strict type-checking options */
    "strict": true,

    /* Ensures null and undefined are handled explicitly */
    "strictNullChecks": true,

    /* Ensures functions follow strict parameter type compatibility */
    "strictFunctionTypes": true,

    /* Requires class properties to be initialized in the constructor */
    "strictPropertyInitialization": true,

    /* Throws error if a local variable is declared but never used */
    "noUnusedLocals": true,

    /* Throws error if a function parameter is declared but never used */
    "noUnusedParameters": true,

    /* Ensures every function code path returns a value */
    "noImplicitReturns": true,

    /* Removes comments from the compiled JavaScript output */
    "removeComments": true,

    /* Determines how modules are resolved (Node.js style resolution) */
    "moduleResolution": "node",

    /* Enables compatibility between CommonJS and ES module imports */
    "esModuleInterop": true,

    /* Generates source map files for debugging TypeScript in dev tools */
    "sourceMap": true,

    /* Skips type checking of declaration files to speed up compilation */
    "skipLibCheck": true,

    /* Enforces consistent casing in file imports across operating systems */
    "forceConsistentCasingInFileNames": true
  },

  /* Specifies the folders/files TypeScript should compile */
  "include": ["src"],

  /* Specifies folders/files TypeScript should ignore */
  "exclude": ["node_modules", "dist"]
}
}

```


step 4 :- install @types/node so that ts understand the node.js code 

```ts
npm install -D @types/node (ts understand node js code like fs)
npm install -D ts-node //ts-node allows you to run TypeScript files directly without compiling them first. 
```

Run the ts without compiling it with 

```ts
>>> npx ts-node src/app.ts
```

But ts-node is used in development mode for production we have to compile the whole ts file to run it, and in production we run js

```ts
development → ts-node
production → compiled JS
```

step 5 :- install nodemon

```ts
npm install -D nodemon 
```

and configure package.json file

```json

{
  "scripts": {
    "dev": "nodemon --watch src --ext ts --exec ts-node src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js"
  }
}

```


| Part             | Meaning                         |
| ---------------- | ------------------------------- |
| `nodemon`        | starts nodemon watcher          |
| `--watch src`    | watch the `src` directory       |
| `--ext ts`       | restart when `.ts` files change |
| `--exec ts-node` | run using ts-node               |
| `src/server.ts`  | entry file                      |



step 6 :- Run development server


```ts
 npm run dev
```

### Better approach (cleaner)


Instead of a long script, create nodemon.json.


```json
{
  "watch": ["src"], // watch this folder for changes
  "ext": "ts", //file extention (watch only these files)
  "exec": "ts-node src/server.ts" //(execute this command)
}
```

Then simplify package.json script

```json
{
  "scripts": {
    "dev": "nodemon",
    "build": "tsc",
    "start": "node dist/server.js"
  }
}
```


Final folder structure 

```ts
project
│
├── src
│   └── server.ts
│
├── dist
│
├── nodemon.json
├── tsconfig.json
├── package.json
```

### Latest replace nodemon + ts-node with tsx 

```ts
npm install -D tsx
```

```json
{
  "scripts": {
    "dev": "tsx watch src/server.ts"
  }
}
```
This replaces nodemon + ts-node entirely.

















