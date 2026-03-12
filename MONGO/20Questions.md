
# 1. Eliminating N+1 Query With Data Modeling

### Scenario

You built an API:

```
GET /posts/:id
```

Each post has `authorId`.
Your code:

```
post = db.posts.findOne({_id})
author = db.users.findOne({_id: post.authorId})
```

At **10k requests/sec**, database CPU spikes.

### Problem

Redesign the **MongoDB schema** so that:

* Only **1 query** is required.
* User name changes still propagate correctly.

### Knowledge Gap

* **Embedding vs referencing**
* **partial denormalization**
* **event-driven updates**

---

# 2. Pagination at 100M Documents

### Scenario

Collection `logs` contains **100 million documents**.

You run:

```js
db.logs.find().skip(5000000).limit(50)
```

Query latency becomes **5 seconds**.

### Problem

Design a **pagination system** that:

* Handles deep pagination
* Works under high insert rate
* Keeps ordering consistent

### Knowledge Gap

* **cursor-based pagination**
* **range queries vs skip**

---

# 3. Leaderboard Ranking

### Scenario

Gaming leaderboard collection:

```
players
- playerId
- score
```

You need:

```
GET /rank/:playerId
```

Return the **player's rank globally**.

### Problem

Design an efficient way to calculate rank for **10M players**.

### Knowledge Gap

* **aggregation pipeline**
* **$setWindowFields**
* **sorted indexes**

---

# 4. Preventing Duplicate Payments

### Scenario

Payments collection:

```
payments
- userId
- orderId
- amount
```

Users sometimes **double click payment button**, creating duplicate payments.

### Problem

Guarantee **idempotent writes**.

### Knowledge Gap

* **unique compound index**
* **transactions**
* **write concern**

---

# 5. High Frequency Counter Updates

### Scenario

You track video views:

```
videoViews
- videoId
- views
```

Millions of increments per minute:

```
$inc: {views:1}
```

Document becomes **write bottleneck**.

### Problem

Redesign counter system.

### Knowledge Gap

* **distributed counters**
* **bucketing strategy**

---

# 6. Time-Series Query Optimization

### Scenario

IoT sensor data:

```
sensor_data
- sensorId
- temperature
- timestamp
```

Query:

```
average temperature per hour
```

Dataset = **500M records**.

### Problem

Design an optimized schema + query.

### Knowledge Gap

* **time-series collections**
* **bucket compression**

---

# 7. Efficient Feed Generation

### Scenario

Instagram-style feed:

```
posts
- userId
- createdAt
```

User follows **2000 people**.

Feed query:

```
posts where userId in [2000 ids]
sort by createdAt
limit 50
```

Query becomes slow.

### Problem

Design a scalable feed system.

### Knowledge Gap

* **fan-out write**
* **fan-out read**
* **feed materialization**

---

# 8. Removing Expired Documents Automatically

### Scenario

OTP collection:

```
otp
- userId
- code
- createdAt
```

OTP should expire after **5 minutes**.

### Problem

Implement auto-deletion without cron jobs.

### Knowledge Gap

* **TTL indexes**

---

# 9. Efficient Full Text Search

### Scenario

Articles collection:

```
articles
- title
- content
```

Users search:

```
"distributed systems"
```

### Problem

Implement relevance ranking.

### Knowledge Gap

* **text indexes**
* **$text operator**
* **Atlas Search vs native search**

---

# 10. Avoiding Large Document Growth

### Scenario

Chat messages stored like:

```
chatRoom
- messages: []
```

After months, the array reaches **16MB document limit**.

### Problem

Redesign schema.

### Knowledge Gap

* **document size limits**
* **message bucketing**

---

# 11. Multi-Document Consistency

### Scenario

E-commerce order flow:

```
orders
inventory
payments
```

If payment succeeds but inventory update fails → inconsistent state.

### Problem

Guarantee atomicity.

### Knowledge Gap

* **MongoDB transactions**
* **two-phase commit**

---

# 12. Efficient Tag Filtering

### Scenario

Posts contain:

```
tags: ["mongodb","backend","database"]
```

Query:

```
posts containing mongodb AND backend
```

### Problem

Optimize query.

### Knowledge Gap

* **multikey indexes**

---

# 13. Geo Query for Nearby Drivers

### Scenario

Ride sharing app:

```
drivers
- location
```

Query:

```
find drivers within 3km
```

### Problem

Design geospatial search.

### Knowledge Gap

* **2dsphere indexes**
* **$near queries**

---

# 14. Real-Time Analytics

### Scenario

You need:

```
Top 10 videos watched today
```

But dataset updates constantly.

### Problem

Design system to compute this efficiently.

### Knowledge Gap

* **aggregation pipelines**
* **pre-aggregation**

---

# 15. Soft Delete Strategy

### Scenario

Users delete posts.

But you need:

* audit logs
* recovery

### Problem

Implement **soft delete** while keeping queries fast.

### Knowledge Gap

* **partial indexes**
* **query filters**

---

# 16. Schema Evolution Without Downtime

### Scenario

Old schema:

```
user
- name
```

New schema:

```
user
- firstName
- lastName
```

System already has **10M records**.

### Problem

Perform migration without downtime.

### Knowledge Gap

* **backward compatible schema**
* **dual writes**

---

# 17. Avoiding Hot Shard Problem

### Scenario

Sharded collection:

```
orders
shardKey = createdAt
```

All writes go to **latest shard**.

### Problem

Fix uneven shard distribution.

### Knowledge Gap

* **shard key design**

---

# 18. Efficient Deduplication

### Scenario

Logs ingestion pipeline creates duplicates.

Need to detect duplicates across:

```
timestamp + message + service
```

### Problem

Prevent duplicates efficiently.

### Knowledge Gap

* **hash indexes**
* **compound uniqueness**

---

# 19. Querying Nested Arrays

### Scenario

Order document:

```
orders
- items: [
   {productId, price, quantity}
]
```

Query:

```
orders where productId=123 AND quantity > 2
```

### Problem

Write efficient query + index.

### Knowledge Gap

* **$elemMatch**
* **multikey compound index**

---

# 20. Reducing Aggregation Memory Usage

### Scenario

Aggregation pipeline:

```
$group
$sort
$lookup
```

Pipeline fails with:

```
Exceeded memory limit
```

### Problem

Refactor pipeline.

### Knowledge Gap

* **pipeline optimization**
* **$facet**
* **allowDiskUse**

---










