# To design GET /rank/:playerId for 10 million players

```ts
async function getRank(playerId){

  const player = await db.collection("players")
    .findOne({playerId});

  if(!player) return null;

  const higher = await db.collection("players")
    .countDocuments({
      score: { $gt: player.score }
    });

  return {
    playerId,
    rank: higher + 1
  };
}
```

Problem :- what about the duplicate scores?
we can maange compound index.

If we do

```ts
players.find().sort({score:-1})
```

Time complexity is.


```ts
Sort = O(N log N)
Scan = O(N)
```

Mongodb does


But MongoDB Already Solves This With Index

With an index:

```
{ score: -1, playerId: 1 }
```

Query:

```
db.players.find().sort({score:-1}).limit(10)
```

MongoDB simply:

B+Tree → read first 10 entries

Complexity:
```
O(log N + K)
```

## ===================================

## MongoDB Leaderboard Ranking — Short Note

### Problem

Leaderboard collection:

```js
players
{
  playerId,
  score
}
```

API:

```
GET /rank/:playerId
```

Goal: **Return the global rank of a player among ~10M players efficiently.**

---

# 1. Sorted Index

Create a **descending index on score**.

```js
db.players.createIndex({ score: -1, playerId: 1 })
```

Purpose:

* Maintains players **already sorted by score**
* Avoids expensive runtime sorting
* Supports **fast range scans**

Internal structure:

```
B-Tree index
```

Time complexity:

```
Search → O(log N)
```

---

# 2. Rank Calculation Strategy

Rank definition:

```
Rank = number of players with higher score + 1
```

Steps:

1. Fetch player score

```js
player = db.players.findOne({ playerId })
```

2. Count players with higher score

```js
db.players.countDocuments({
  score: { $gt: player.score }
})
```

3. Compute rank

```
rank = count + 1
```

Because of the **sorted index**, this count uses **index range scanning**.

---

# 3. Aggregation Pipeline

MongoDB pipelines process data in **stages**.

Example:

```js
db.players.aggregate([
  { $sort: { score: -1 } }
])
```

Concept:

```
collection → stage → stage → result
```

Used for **analytics queries and transformations**.

---

# 4. `$setWindowFields` (Window Functions)

MongoDB supports **window functions** for ranking.

Example:

```js
db.players.aggregate([
  {
    $setWindowFields: {
      sortBy: { score: -1 },
      output: {
        rank: { $rank: {} }
      }
    }
  }
])
```

Result:

```
A → rank 1
B → rank 2
C → rank 2
D → rank 4
```

Operators:

| Operator          | Behavior                  |
| ----------------- | ------------------------- |
| `$rank`           | Same score → same rank    |
| `$documentNumber` | Strict ranking (1,2,3...) |

Limitation:

```
Requires scanning large dataset → expensive for real-time API
```

---

# 5. Production Approach

For **10M players**, the efficient design is:

```
1. Sorted index
2. Fetch player score
3. Count players with higher score
4. rank = count + 1
```

Advantages:

```
Fast
Index supported
Works at large scale
```

---

# 6. Real-World Optimization

High-traffic leaderboards often use:

```
Redis Sorted Sets
```

Commands:

```
ZADD leaderboard score playerId
ZREVRANK leaderboard playerId
```

Complexity:

```
O(log N)
```

MongoDB is then used for **persistent storage**, while Redis handles **real-time ranking**.

---

## Key Takeaways

| Concept              | Role                           |
| -------------------- | ------------------------------ |
| Sorted Index         | Efficient leaderboard ordering |
| Compound Index       | Stable ranking for same scores |
| Aggregation Pipeline | Data processing framework      |
| $setWindowFields     | Ranking with window functions  |
| Range Count Query    | Fast rank calculation          |

---

If useful, I can also provide a **10-line interview answer version** of this leaderboard problem (exactly how it is expected in **system design interviews**).

