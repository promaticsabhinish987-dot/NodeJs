## Why logging?

**logging = persisting time-ordered events for later inspection**

> *"Logging skill is the ability to preserve the minimum necessary truth about a system’s state transitions such that any failure can be reconstructed without access to the system itself."*

```
tool + skill = mastery

skill => apbility to make shift for people, like unknown to known.

its about learning about weapon ,and using it in different way, without even thinking.
```

---

## Very basic level of logging

```ts
console.log("User created")
```

```ts
module.exports = (req,res,next)=>{
   const start=Date.now();

   res.on("finish",()=>{
      const duration=Date.now()-start;

      console.log({
         method:req.method,
         url:req.originalUrl,
         status:res.statusCode,
         time:`${duration}ms`
      })
   })
   next()
}
```

You can log in controller for tracking the API behaviour.

---

### Gap 1

**logging is not just printing, its about structured event pipeline**

---

## Winston

**Winston is: A configurable logging pipeline**

Where we define three things:

1. **log → event object**
2. **format → transforms event**
3. **transport → destination**

```ts
const winston = require("winston");

const logger = winston.createLogger({
  level: "info",
  transports: [
    new winston.transports.Console()
  ]
});

logger.info("Server started");
```

---

### Q) Can we have only one level at a time?

It provides multiple logging levels.
If not defined, it uses default levels.

---

## Logger pipeline

```
Event → Filter → Transform → Route → Storage
```

> A logger is a data pipeline for system events—closer to ETL (Extract, Transform, Log) than printing.

---

## 1. Env Selection

| Env  | Goal                      |
| ---- | ------------------------- |
| Dev  | Debugging (max signal)    |
| Prod | Stability + observability |

**Different environments require different signal-to-noise ratios**

```ts
const isDev = ...
const isProd = ...
```

---

## 2. Log Level Filtering

```ts
level: isDev ? 'debug' : 'info'
```

| Level | Meaning              |
| ----- | -------------------- |
| debug | noisy internal state |
| info  | business events      |
| error | failures             |

**Log level = information entropy control (amount of data exposure)**

---

### Error Stack Handling

```ts
const enumerateErrorFormat = winston.format((info) => {
  if (info instanceof Error) {
    Object.assign(info, { message: info.stack });
  }
  return info;
});
```

> Excess logs = signal dilution
> Production must filter aggressively

---

## 3. Format Layer (Data Transformation)

**Format = serialization for downstream systems**

---

### A) Production

Logs are machine-readable (JSON)

```ts
format.json()
```

Pipeline:

```
timestamp → error(stack) → splat → json
```

Example:

```json
{
  "level": "error",
  "message": "DB failed",
  "stack": "...",
  "timestamp": "..."
}
```

---

### B) Development

Logs are human-readable

```ts
colorize + printf
```

Example:

```
error [2026-05-02] DB failed { userId: 1 }
```

| Environment | Optimization Target   |
| ----------- | --------------------- |
| Dev         | Human cognition speed |
| Prod        | Machine parsing       |

---

## 4. Transport Layer (Routing)

### Console Transport

```ts
level: isDev ? 'debug' : 'error'
```

| Env  | Console Output |
| ---- | -------------- |
| Dev  | all logs       |
| Prod | only errors    |

> Not persistent → lost on crash

---

### File Transports (Production)

```ts
error.log
combined.log
```

| File         | Stores      |
| ------------ | ----------- |
| error.log    | only errors |
| combined.log | all ≥ info  |

---

### Q) Explain execution level

File = **local durable storage**

> One log file is not enough
> Log separation = faster debugging + lower search cost

---

### MongoDB Transport

```ts
level: 'error'
```

Only critical failures go to DB (e.g., payments)

> DB logging = queryable long-term storage

---

### Q) Log retention & scale

* Do not store all logs in DB
* Expensive and slow
* Must be selective

---

## 5. Error Handling Layer

```ts
exceptionHandlers
rejectionHandlers
```

| Type      | Example       |
| --------- | ------------- |
| Exception | sync crash    |
| Rejection | async failure |

> System fails outside try/catch boundaries

> Unhandled errors require global interception

---

## 6. Full Execution Flow

### Development

```
Event
 → pass level filter (debug)
 → dev format (color + printf)
 → console
 → developer reads instantly
```

---

### Production

```
Event
 → pass level filter (info)
 → JSON transform
 → routes:
     → console (errors only)
     → file (persistent)
     → MongoDB (critical)
```

> As persistence increases → data volume must decrease

---

## 7. System Mental Model

```
[Capture]
   ↓
[Filter (level)]
   ↓
[Transform (format)]
   ↓
[Route (transport)]
   ↓
[Persist / Observe]
```
