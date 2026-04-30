## Why logging?
logging = persisting time-ordered events for later inspection

### very basic level of logging is 

```ts
console.log("User created")

or

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
You can log in controller for tracking the api behaviour.

Gap1 :- loggin is not just printing , its about **structured event pipeline**


### Winston

_Winston is: A configurable logging pipeline._

where we can define three things.

1. log → event object 
2. format → transforms event
3. transport → destination


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

Q) can we have only one level at a time.

it provide number of logging levels , for defined level , or if we not define it will use another log level






