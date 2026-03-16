## 4. Preventing Duplicate Payments

Preventing duplicate payments is a classic idempotency problem in distributed systems. The objective is:

 - **_No matter how many times the request is sent, only one payment should be created._**


### 1. Understanding the Real Problem

**Scenario**

Collection: payments

```
payments
- userId
- orderId
- amount
```

User clicks Pay twice quickly → two API calls hit the server.

Without safeguards:

```
Payment 1 → success
Payment 2 → success
```

Database result:

```ts
{userId:1, orderId:101, amount:500}
{userId:1, orderId:101, amount:500}
```

This produces duplicate charges.



### 2. What is Idempotency?

Idomptent :- an operation is idomptent if executing it multiple times prodcues the same final state as executing it once.

like payment , once successfull every time it will show payment successfull.



### 3. First Solution: Unique Compound Index


We enforce that one user can only create one payment for an order.

MongoDB allows this with a **compound unique index**.

```ts
db.payments.createIndex(
   { userId: 1, orderId: 1 },
   { unique: true }
)
```
This will first check the index if already created, it will not create it again ang give duplicate key error.


### ================= Index key generation Start ========================

Q) how mongodb create index with given value?
Q) does it create duplicate index?

Mongodb takes a value or attribute like gmail and uses a predictable encoding algorith to covert it into binary formet,and store it, its deterministic algorithm , so that it will producse same key with the same value.


```
Same key value ---> same keyString.
```
Note:- key might be duplicated but the key and doc it will be unique.

Mongo db by default create duplicate index if we provide the same key , but it will point to different document.
Same key will point to different document. or multiple documents can share the same key.


```
Psudocode to generate index (unique : true)

if key exists in index
       reject insert.
else
      insert key.



Psudocode to generate index

insert key regardless of
     duplicates.

```

##### There can be four case with index and uniqueness.

1. Non-Unique Single Field Index (Duplicates Allowed)


```ts

// create data
db.users.insertMany([
 { _id:1, email:"a@gmail.com" },
 { _id:2, email:"a@gmail.com" },
 { _id:3, email:"b@gmail.com" }
])



// create index

db.users.createIndex({ email:1 }) // this index is not unique.


//mongodb extract the gmail and generate key.
---------------------------------
KeyString("a@gmail.com") → RID1
KeyString("a@gmail.com") → RID2
KeyString("b@gmail.com") → RID3
---------------------------------
```

- duplicate keys exist
- only RecordId differs


2. Unique Single Field Index (Duplicates Not Allowed)

```ts

// create index
db.users.createIndex({ email:1 }, { unique:true })


//insert data
db.users.insertOne({email:"a@gmail.com"})  //✓ success

// try to reinsert
db.users.insertOne({email:"a@gmail.com"})  //E11000 duplicate key error


// keys stored in db

KeyString("a@gmail.com") → RID1

```

3. Compound Index Example

```ts
// create the data
db.orders.insertMany([
 { _id:1, userId:1, orderId:101 },
 { _id:2, userId:1, orderId:102 },
 { _id:3, userId:1, orderId:101 }
])

// create compound index
db.orders.createIndex({ userId:1, orderId:1 })


// stored internally
KeyString(1,101) → RID1
KeyString(1,101) → RID3
KeyString(1,102) → RID2

```
Duplicates allowed because index is not unique.

4. Unique Compound Index

```ts
// create index
db.orders.createIndex(
 { userId:1, orderId:1 },
 { unique:true }
)

// insert
{userId:1, orderId:101}  ✓ allowed
{userId:1, orderId:101}  ✗ rejected

// because the combination must be unique. Only then it will generate a unique index.

//Internally it will b stored as

KeyString(1,101) → RID1
KeyString(1,102) → RID2

```
| Index Type              | Stored Keys              |
| ----------------------- | ------------------------ |
| Non-unique single field | same key + different RID |
| Unique single field     | duplicate key rejected   |
| Non-unique compound     | duplicate tuple allowed  |
| Unique compound         | duplicate tuple rejected |


Basically it uses this function in order to encode the value to create a index.

```
KeyString(indexed_value) → RecordId
KeyString(value1,value2,...) → RecordId
```

### ================= Index key generation End ========================







