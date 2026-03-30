```ts
//1. write a correct working service, (5 work)
// goal --> write a correct working service

exports.findUserById=async (id)=>{ // take input
if(!id) throw new Error("Invalid Id"); //validate the input 
const user=await userRepo.getById(id); // do db operation with repo
if(!user) throw new Error("User not found"); // validate the response from the db

return user; // return data , or object with selective fields.
};

// what if your feature require multiple entity , like user, and item and more 

// 2. analyze the feature and break it into workflow , steps.

//goal --> Decompose real-world problem into steps

exports.placeOrder = async (userId, items) => {
  // 1. Validate user
  const user = await userRepo.findById(userId);
  if (!user) throw new Error("User not found");

  // 2. Validate products + calculate total
  let total = 0;

  for (let item of items) {
    const product = await productRepo.findById(item.productId);

    if (!product) throw new Error("Product not found");
    if (product.stock < item.quantity) {
      throw new Error("Out of stock");
    }

    total += product.price * item.quantity;
  }

  // 3. Create order
  const order = await orderRepo.create({ userId, items, total });

  return order;
};



// Multi-entity coordination
// Step-by-step workflow
// Service = orchestrator

// what if it fail in middle, use transaction for consistency and acc to contraint we have multiple other options to use which are just scenerio based


//3. production level service

exports.placeOrder = async (userId, items) => {
  // 1. Validate user
  const user = await userRepo.findById(userId);
  if (!user) throw new Error("User not found");

  // 2. Idempotency check
  const existing = await orderRepo.findPendingByUser(userId);
  if (existing) return existing;

  // 3. Start transaction
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    let total = 0;

    // 4. Validate + calculate
    for (let item of items) {
      const product = await productRepo.findById(item.productId);

      if (!product) throw new Error("Product not found");
      if (product.stock < item.quantity) {
        throw new Error("Out of stock");
      }

      total += product.price * item.quantity;

      await productRepo.reduceStock(
        item.productId,
        item.quantity,
        session
      );
    }

    // 5. Create order
    const order = await orderRepo.create(
      { userId, items, total },
      session
    );

    // 6. Commit transaction
    await session.commitTransaction();

    // 7. Async side effects
    queue.add("sendEmail", { orderId: order._id });

    return order;

  } catch (err) {
    await session.abortTransaction();
    throw err;
  }
};







```
