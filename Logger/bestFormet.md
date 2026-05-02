## Best Practice Format

#### 1. Flat structured logging


```ts
logger.info('APPLICATION_STARTED', {
  port: config.PORT,
  serverUrl: config.SERVER_URL
})
```

#### 2. Error logging (correct way)


```ts
logger.error('APPLICATION_ERROR', {
  message: err.message,
  stack: err.stack,
  name: err.name
})
```


#### 3. Simple Events


```ts
logger.info('RATE_LIMITER_INITIATED')
```

Note :- nesting is bad , because its not for human its for machine.



##### Compatibility with tools

Works perfectly with:


```
ELK stack
Datadog
CloudWatch
```

**Using Node.js with Amazon CloudWatch allows you to monitor application performance through logs, metrics, and automated alarms.**



#### Clean structure

```ts
{
  "level": "info",
  "message": "APPLICATION_STARTED",
  "port": 3000,
  "serverUrl": "http://localhost:3000"
}
```

```ts
logger.info('EVENT_NAME', { ...context })
logger.error('EVENT_NAME', err OR { structured error })
```
























