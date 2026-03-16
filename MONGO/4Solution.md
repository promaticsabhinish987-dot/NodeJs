## 4. Preventing Duplicate Payments



## =========== Solution start ===================

Idempotency Key + Unique Index + Transaction + Majority Write Concern


```ts
// Database schema (payments collection)

{
  _id: ObjectId,
  userId: ObjectId,
  orderId: ObjectId,
  amount: Number,
  status: "pending | success | failed",
  idempotencyKey: String,
  createdAt: Date
}
```

Unique index

```ts
db.payments.createIndex(
  { idempotencyKey: 1 },
  { unique: true }
)
```
Transaction-Based Payment Flow

```ts
async function processPayment(client, paymentData) {

  const session = client.startSession();

  try {

    session.startTransaction({
      writeConcern: { w: "majority" }
    });

    const payments = client.db().collection("payments");
    const orders = client.db().collection("orders");

    await payments.insertOne(
      {
        userId: paymentData.userId,
        orderId: paymentData.orderId,
        amount: paymentData.amount,
        idempotencyKey: paymentData.idempotencyKey,
        status: "success",
        createdAt: new Date()
      },
      { session }
    );

    await orders.updateOne(
      { _id: paymentData.orderId },
      { $set: { status: "paid" } },
      { session }
    );

    await session.commitTransaction();

    return { success: true };

  } catch (err) {

    await session.abortTransaction();

    if (err.code === 11000) {

      return {
        success: true,
        message: "Payment already processed"
      };

    }

    throw err;

  } finally {

    await session.endSession();

  }

}
```



## =========== Solution end =====================

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

Even if two API requests arrive simultaneously:

```ts
Request 1 → insert success
Request 2 → duplicate index violation
```
Only one payment is stored.

You must have to handle the duplicate error gracefully.

```ts
try {

 await db.collection("payments").insertOne({
   userId: 1,
   orderId: 101,
   amount: 500
 })

} catch(err){

 if(err.code === 11000){
   console.log("Payment already processed")
 }

}
```

Now repeated requests produce the same logical result.

##### Knowledge gap

Why we cant not use it in production. for unique payment.
Because payment does not work with only one document, it follow a step like
Reduce the money from wallet, decrease inventory, and more which is a transaction, payment is a process of multiple steps, and all must be fulfilled, or all must be failed.
If you are not following a rollback sytem , if money deducted but payment is not created there might be inconsistency.


### 4. Second Layer: Transactions

Why do we need transactions?

Because payment systems rarely perform a single write.

Typical workflow:


```
1 create payment record
2 update order status
3 reduce wallet balance
4 create ledger entry
```

Without transactions:

```
payment inserted
server crash
order not updated
```

Now the system is **inconsistent**.

It should be consistent. So what we can do to make it consistent.


#### Mongodb **transaction**

MongoDB allows atomic multi-document operations.
Transactions let you execute multiple operations in isolation and potentially undo all the operations if one of them fails.

Used to trat multiple operation as one unit of task, and work as binary operation , like 0 or 1.

MongoDB transactions run inside a session.

#### Transaction Lifecycle (4 phase)



A MongoDB transaction has 4 phases.

1. Start session

```
session = client.startSession()
```
2. Start transaction

```
session.startTransaction()
```
3. Perform operations

All queries must include:

```
{ session }
```

4. Commit / Abort

```
session.commitTransaction()
```
or
```
session.abortTransaction()
```
Note :- mongodb transaction runs in seccion. If any step fail it abort or rollback.


Example

```ts
const session = client.startSession();

try {

  session.startTransaction();

  await db.collection("accounts").updateOne(
    { userId: "A" },
    { $inc: { balance: -100 } },
    { session }
  );

  await db.collection("accounts").updateOne(
    { userId: "B" },
    { $inc: { balance: 100 } },
    { session }
  );

  await session.commitTransaction();

} catch (error) {

  await session.abortTransaction();

} finally {

  session.endSession();

}
```
Will give gurantee

```
all operations succeed
OR
all operations rollback
```
#### Other things to know, transection uses ACID properties

| Property    | Meaning                                 |
| ----------- | --------------------------------------- |
| Atomicity   | All operations succeed or none          |
| Consistency | Database rules remain valid             |
| Isolation   | Concurrent transactions don't interfere |
| Durability  | Data survives crashes                   |


Further deep gaps:

- How MongoDB uses snapshot isolation

- How two-phase commit works in distributed clusters


its like github, a transection stores all thing temporary in staging area like gir add . , and it commits at once, if commit pass its sucesss and if commit failt it will show failure.

#### Knowledge gap
now we can create a transection for payment, but where it can fail?

Even if MongoDB inserts the document, we must ensure the data is safely replicated.

### 5. Third Layer: Write Concern

When should MongoDB tell the client "write successful"?

| Option                           | Meaning               |
| -------------------------------- | --------------------- |
| Immediately after primary writes | Fast but less durable |
| After replicas confirm           | Slower but safer      |

Write Concern controls this behavior.

Defination :- Write Concern defines the level of acknowledgment MongoDB requires before confirming a write operation as successful.

In other words:

```
It specifies how many nodes must confirm the write before the client receives a success response.

or

How many nodes must confirm the write
before the operation is considered successful
```

This is critical in replica set environments where data is replicated across multiple nodes.


```ts
db.payments.insertOne(
   doc,
   { writeConcern: { w: "majority" } }
)
```



Knowledge Gap

You should understand:

Replication internals

Questions:

- How does MongoDB replicate operations via oplog?

- What is primary election?

- What happens to writes during failover?















## ================== write concern Start =========================

Note :- For multi-document transactions, you set the write concern at the transaction level, not at the individual operation level. Do not explicitly set the write concern for individual write operations in a transaction.
Replica sets and sharded clusters support setting a global default write concern.

### Write Concern Specification


```
{ w: <value>, j: <boolean>, wtimeout: <number> }



{
  writeConcern: {
    w: <value>,
    j: <boolean>,
    wtimeout: <number>
  }
}
```

w :- Defines you want acknowledgement or not, with doc it, when you write, means you will wait for it or not.(1 if you want 0 if not acknowledgement)
j :- journal , defines that , we create a todo for the work that we are going to do because mongodb operation is slow ,and if in between , if mongodb shut down, the data will flush by default and if j is true , it will remember the task and retry when mongodb restart. (if you include it the process will be slow)
wtimeout :- when you have to give the response to the client, in ms.

Default w== 1

- Primary node acknowledges the write.

- Replication happens asynchronously.

| Write Concern  | Speed    | Durability | Typical Use         |
| -------------- | -------- | ---------- | ------------------- |
| `w:0`          | Fastest  | Lowest     | logs, metrics       |
| `w:1`          | Fast     | Medium     | normal app writes   |
| `w:2` / number | Moderate | Higher     | replicated systems  |
| `w:"majority"` | Slower   | Highest    | payments, financial |
| `w:"tag"`      | Variable | Controlled | geo-replication     |


MongoDB returns success only after more than half of the replica set nodes have written the operation.

```
majority = floor(total_nodes / 2) + 1
```

## ================== write concern End =========================


























## ================= Index key generation Start ========================

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

## ================= Index key generation End ========================







