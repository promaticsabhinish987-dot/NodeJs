Its main working is to get input , validate it, fetch required data from Model, construct new data object which is required and this controller is made for, and return the data.

Types of controller 
1. Resource Controller (UsersController,OrdersController) (CRUD/simple work flow)
2. Action / Use-Case Controller (Maps to verbs, not nouns.)(CheckoutController,ResetPasswordController)(business flows,multi-step logic)
3. Front Controller (important)
4. Application Controller (Base Controller)
5. View Controller (UI-focused)



##  Resource Controller

```ts

Client
  ↓
Controller (Waiter)
  ↓
Service (Chef)
  ↓
Repository (Pantry)
  ↓
Model (Recipe)

```


Suppose we have to create a user. How we can create.

1. Model : The recipe defines what a “User” is and how it behaves ==> Recipe (Rules & Structure)


```ts

// model/User.ts
export class User {
  constructor(
    public id: string,
    public name: string,
    public email: string
  ) {}

  static create(data: { id: string; name: string; email: string }) {
    if (!data.email.includes("@")) {
      throw new Error("Invalid email");
    }
    return new User(data.id, data.name, data.email);
  }
}


```

Model knows business rules, not HTTP or DB.


2. Repository = Pantry (Data access) ==> Repository knows WHERE data is stored and HOW to fetch/save it

stores ingredients

chef asks pantry for things

waiter never enters pantry

```ts

// repository/UserRepository.ts
import { User } from "../model/User";

export class UserRepository {
  private users: User[] = [];

  findAll(): User[] {
    return this.users;
  }

  findById(id: string): User | undefined {
    return this.users.find(u => u.id === id);
  }

  save(user: User): User {
    this.users.push(user);
    return user;
  }
}


```

Note :- Repository does no business logic — only storage.

3. Service = Chef (Business logic coordinator)

Service decides HOW to fulfill the request

reads recipe

gets ingredients from pantry

prepares food

enforces rules

```ts

// service/UserService.ts
import { User } from "../model/User";
import { UserRepository } from "../repository/UserRepository";
import { v4 as uuid } from "uuid";

export class UserService {
  constructor(private userRepo: UserRepository) {}

  createUser(data: { name: string; email: string }) {
    const user = User.create({
      id: uuid(),
      name: data.name,
      email: data.email
    });

    return this.userRepo.save(user);
  }

  listUsers() {
    return this.userRepo.findAll();
  }
}

```

4. Controller = Waiter (HTTP adapter)  ==> Controller translates HTTP into business actions

Controller translates HTTP into business actions

talks to customer

writes order

gives order to chef

serves food back


```ts

// controller/UserController.ts
import { UserService } from "../service/UserService";

export class UserController {
  constructor(private userService: UserService) {}

  create(req, res) {
    const user = this.userService.createUser(req.body);
    res.status(201).json(user);
  }

  list(req, res) {
    const users = this.userService.listUsers();
    res.json(users);
  }
}


```
knows HTTP

knows nothing about DB or rules

extremely thin



| Layer      | Analogy | Responsibility                 |
| ---------- | ------- | ------------------------------ |
| Controller | Waiter  | Takes order, talks to customer |
| Service    | Chef    | Knows how to cook              |
| Repository | Pantry  | Stores ingredients             |
| Model      | Recipe  | Rules of how food is made      |



## Application controller 


```ts
// controller/ApplicationController.ts
export abstract class ApplicationController {
  protected ok(res, data) {
    res.status(200).json({
      success: true,
      data
    });
  }

  protected created(res, data) {
    res.status(201).json({
      success: true,
      data
    });
  }

  protected fail(res, error: Error) {
    res.status(400).json({
      success: false,
      message: error.message
    });
  }
}



//controller simplify

// controller/UserController.ts
export class UserController extends ApplicationController {
  constructor(private userService: UserService) {
    super();
  }

  create(req, res) {
    try {
      const user = this.userService.createUser(req.body);
      this.created(res, user);
    } catch (e) {
      this.fail(res, e);
    }
  }
}



```




Note :- all types of controller pattern we use , just to simplify the Controller.






























