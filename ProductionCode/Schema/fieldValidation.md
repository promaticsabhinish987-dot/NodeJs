# Field Validation ---> Schema Design in mongoose.

## 1. Buildin validators 33

1. Require validator.

Takes two value in array a boolean and a message to throw if not filled.

```ts
required: [true, “user name is required”]
```

we can also define it without custom error message.

```ts
const personSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Name is required']
  }
});
```
| Validator   | Works On | Example                 |
| ----------- | -------- | ----------------------- |
| `required`  | all      | required: true          |
| `min`       | number   | min: 10                 |
| `max`       | number   | max: 100                |
| `minlength` | string   | minlength: 8            |
| `maxlength` | string   | maxlength: 50           |
| `enum`      | string   | enum: ['user', 'admin'] |
| `match`     | string   | regex                   |


```
all takes two thing , rule and message

min: [18, 'Error message']

max: [40, 'Error message']

```

## 2. custom validators (return boolean value or a error message)


```ts
  username: {
    type: String,
    required: true,
    validate: {
      validator: function(value) {
        return /^[a-zA-Z0-9]+$/.test(value); // username must contain only letters and numbers
      },
      message: 'Username must be alphanumeric'
    }
  }
```
validate :- take two argument 
1. Rule orfunction to validate , called validator
2. custom error message ,if found error in validator, or if we not define the custom it will use the validators error.



### How validation works

Mongoose run all the validation before save() saving the document, and if any validation fail document will be saved and throw validation error.


example

```ts
validate(value) {
  if (!validator.isEmail(value)) {
    throw new Error('Invalid email');
  }
}
```

### We have two ways to use custom validation

1. use it as simple function.

```ts
validate: function(value) {
  return value.length > 5;
}
```

2. like an object.

```ts
validate: {
  validator: function(value) {
    return value.length > 5;
  },
  message: 'Too short'
}
```

Note :- validator return boolean value or error message , and error message can be custom.

### Async validator (use external service to validate it)

```ts
validate: {
  validator: async function(value) {
    const exists = await SomeService.check(value);
    return !exists;
  },
  message: 'Already exists'
}
```
### We can validate before save() with

```ts
await doc.validate();
```
or use it with try and catch to catch validation error.




### Update Validation Gotchas

```
updateOne()
updateMany()
findByIdAndUpdate()
findOneAndUpdate()
```
👉 What happens?

❌ No schema validation
❌ No validate() function
❌ No required check
❌ No minlength, match, etc.

➡️ Invalid data goes directly into DB.

```
Update queries bypass document lifecycle 
```
Do operation at db level.


Solution :- partially validate when we update

```ts
await User.updateOne(
  { _id: id },
  { email: 'valid@email.com' },
  { runValidators: true }
);
```

- Runs schema validators (validate, match, etc.)
- Validates only updated fields
- validators run when we use save() and create doc.

### How to update them

1. use app level update validation.
2. use find with id and then update returned doc vlaue, and use save() to work well.








