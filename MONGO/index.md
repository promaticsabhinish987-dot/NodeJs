MongoDB indexing is a large internal subsystem involving.

1. storage engine structures, (optimization at storage level)
2. query planning, (optimize query)
3. and execution optimizations. (how to read efficiently)


### 1. Why indexes exist?

#### Problem 

Imagine a MongoDB collection:


```ts
users
{
  name: "Aman",
  age: 25
}

```


You run:


```ts
db.users.find({age:25})
```

Without an index MongoDB performs:

```
COLLECTION SCAN (scan all the collection linearly)
```
Meaning:


```
Read every document
Check condition
Return matches
```

If there are 10 million documents, the complexity is:

```
O(n)
```

This is slow.

Indexes reduce the complexity to approximately:

```
O(log n)
```

##### Knowledge Gap

Why log(n)?

Because MongoDB uses a B-Tree structure.

Understanding indexes requires understanding tree search structures.



### 2. The Physical Structure of MongoDB Index

















