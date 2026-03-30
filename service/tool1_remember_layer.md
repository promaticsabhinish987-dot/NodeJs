## There are only two step to master a skill.

1. Master the tool
2. Master the use case of that tool from basic to advance


or use **Blooms Taxonomy.**

| Level         | Meaning             |
| ------------- | ------------------- |
| 1. Remember   | Know syntax / facts |
| 2. Understand | Explain concepts    |
| 3. Apply      | Use in simple cases |
| 4. Analyze    | Break into parts    |
| 5. Evaluate   | Compare approaches  |
| 6. Create     | Design systems      |


or use **Drefus Model.**

| Level         | Meaning             |
| ------------- | ------------------- |
| 1. Remember   | Know syntax / facts |
| 2. Understand | Explain concepts    |
| 3. Apply      | Use in simple cases |
| 4. Analyze    | Break into parts    |
| 5. Evaluate   | Compare approaches  |
| 6. Create     | Design systems      |


## Blooms Taxonomy.



### 1. Remember (recall) fix set to memorize

-- defines the parts of tool.

1. **Defination** :-

- Service = business logic layer
- Service = orchestrates system behavior (we can use from anywhere)
- Service = stateless function/module (not create variable, just do processing)
- Service = independent of transport layer (HTTP, WS, etc.) (not know about the external world of api)
- Service = input → processing → output (its core work is to process given data and return output)

2. **Layer rules**

- Controller calls Service ✅
- Service calls Repository ✅
- Repository talks to DB ✅

3. Responsibility of service.

- Apply business rules (eg user must be active, min amount should be 100)
- Validate domain logic (eg Booking date validation , Unique email constraint)
- Orchestrate multiple operations (Like a conductor in an orchestra: does multiple things , to commans in sequence to give required result)
- Transform data (eg return only required field not the db strucure, but the structure that is should return, can return computed field)
- Coordinate between layers (eg calls repo or utils, a service chains multiple service, user service , product service)
- Handle application-level errors (eg insufficient balance , invalid operation)

4. **What Service Does NOT Do**

Memorize clearly:

- ❌ No HTTP handling (req, res, headers)
- ❌ No routing
- ❌ No direct database queries
- ❌ No UI formatting
- ❌ No framework-specific logic (its independent from every thing)

5. **Input Outpur Rules**

takes clean and structured data, not raw req body, and return object. Work as pure function.

_Clean data = already extracted, structured, minimal_

- Not pass raw request to the service.

should get clean object.

```ts
// service
exports.createUser = async ({ name, email }) => {
  if (!email) throw new Error("Email required");

  return await userRepo.create({ name, email });
};
```

Plain output = raw business result (no raw db data) ony those data which controller use. to satisfy the working and core responsibility of a service, why this service was created.

6. **Stateless Nature**

Must recall:

- No global variables (data comes from input and return as output only, and service should be isolated)
- No in-memory counters (like for user if use uuid not counter or in memory value)
- No shared mutable state

```
Same input → Same output
No memory of previous calls
No shared mutation
```

and if creating the variable like the discount store it globally, and use function to get and set it. (try not to use)


7. **Error handling rules.**

| Layer      | Error Type      |
| ---------- | --------------- |
| Service    | Business errors |
| Controller | HTTP errors     |
| Repository | DB errors       |


Service Throws:
"User not found"
"Invalid operation"
"Insufficient balance"

8. **Naming conventions.**

_Service methods should reflect business intent(should define its core responsibility)_

Examples
- getUserById
- createOrder
- processPayment
- validateUserAccess

9. **Service Types (Basic Classification)**

Memorize categories:

- CRUD Service (normal repo call single repo)
- Validation Service (a reusable service like active user check, takes user checks state and throw error, or return true,no db call and reusable across service)
- Orchestration Service (co ordinate multiple operations and repository, in flow)
- Integration Service (external APIs)(communication with external service like email service, payment service , work like adapter)
- Domain Service (complex workflows) (combine all the service, like place order)


```ts
// domain service
// order.service.js
exports.placeOrder = async (userId, items) => {
  // 1. Validate user
  const user = await userRepo.findById(userId);
  if (!user) throw new Error("User not found");

  // 2. Validate items + calculate total
  let total = 0;

  for (let item of items) {
    const product = await productRepo.findById(item.productId);

    if (product.stock < item.quantity) {
      throw new Error("Out of stock");
    }

    total += product.price * item.quantity;
  }

  // 3. Create order
  const order = await orderRepo.create({ userId, items, total });

  // 4. External integration
  const paymentId = await paymentService.chargeCard(total, user.paymentToken);

  // 5. Async side-effect
  queue.add("sendEmail", { orderId: order._id });

  return {
    order,
    paymentId
  };
};
```

10. **Dependencies of Service**

Service typically depends on:

Repositories
Other services
Utilities (hashing, logging, etc.)
External APIs


11. Folder location

```
src/services/user.service.js
```

12. Execution flow

```
Request
 → Controller
 → Service
 → Repository
 → Database
 → Back to Service
 → Controller
 → Response
```

13. **Key Properties (One-Line Memory Hooks)**

Memorize these:

Service = Brain
Controller = Translator
Repository = Data Gateway


14. **Reusability Rule**

Service should be reusable across:

HTTP APIs
Cron jobs
Background workers
Event handlers

15 **Questions**

- What does a service do?
- What should it never do?
- What layer does it call?
- What type of errors does it throw?
- What does it return?






