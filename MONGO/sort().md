## Sort()

1. How sort() works internally

2. When MongoDB uses index scan vs in-memory sort

3. Why index design affects query performance

Note :- find returns a cursor.


Note :- mongodb stored index in sorted order, for lon n search.
Otherwise its O(n)

Note :- Use .explain() on queries to see real execution plans

like 

```ts
db.logs.find(query)
       .sort({createdAt:1,_id:1})
       .limit(50)
       .explain("executionStats")
```


### Q) suppose we are storing the data with index in ascending order, and want to get data in descending order for top 10 , will it do it in same time complexity , or it will sort first. its indexed?


Yes — it will have the same time complexity. MongoDB does not sort again when the field is indexed. It simply scans the B-Tree index in reverse order.

It just jumps to the right most doc and read 10 docs 

```ts
1. Jump to rightmost B-Tree leaf (O(log N))
2. Read 10 entries backward
3. Stop
```

```
1. Jump to rightmost B-Tree leaf (O(log N))
2. Read 10 entries backward
3. Stop
```

### When sorting works actually

when we have no index field , it will fetch all in memory and then sort it.

Time complexity = O(n log n)


### index prefix rule.

A compound index can only be used efficiently if the query uses the leftmost fields of the index in order.

**Prefix** means


```
(age)
(age, score)
(age, score, name)
```


If compound index is 

```ts
{ age: 1, score: 1, name: 1 }
```


### if we sort by ace in descending order will it perform sorting

No

Assume the index is:


```
{ age: 1 }

```

which means ascending index order.

Now the query:

```
.sort({ age: -1 })

```

You are asking:

Will MongoDB perform sorting?

**Answer: No. MongoDB will not perform a sort operation. It will scan the index in reverse order.**










