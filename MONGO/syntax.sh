1. mongo  --- connect to mongodb
2. use user --- use created database or create one and switch to that database
3. db.createCollection("post") --- create a post collection {ok:1}
4. > db.user.insertOne({name:"Abhinish Kumar",course:["mongodb","nodejs"]})


{
	"acknowledged" : true,
	"insertedId" : ObjectId("69ba52d5de93e7161fe7ad46")
}

5. > db.post.insertMany([{title:"mongodb"},{title:"Node js"}])


{
	"acknowledged" : true,
	"insertedIds" : [
		ObjectId("69ba5311de93e7161fe7ad47"),
		ObjectId("69ba5311de93e7161fe7ad48")
	]
}


db.user.insertOne(
   {
      title:"abhinish"
   }
);

db.user.insertMany({
   [
      {

      },
      {
         
      }
   ]
})



db.users.updateOne({name:"A"},{$set:{name:"Arjun"}});
{ "acknowledged" : true, "matchedCount" : 1, "modifiedCount" : 1 }



db.users.updateMany({},{$set:{name:"Empty"}}); (add or update if available)

db.users.updateMany({},{name:"Empty"});  (replace the document)

{ "acknowledged" : true, "matchedCount" : 3, "modifiedCount" : 3 }
> db.users.updateOne({name:"Empty"},{$set:{name:"Arjun"}});
{ "acknowledged" : true, "matchedCount" : 1, "modifiedCount" : 1 }
> db.user.deleteOne({name:"Empty"});
{ "acknowledged" : true, "deletedCount" : 0 }


 db.users.deleteMany({});
{ "acknowledged" : true, "deletedCount" : 2 }
> db.users.drop();
true











next10

1. > db.users.find()  (return all the document of collection,accept a filter)
{ "_id" : ObjectId("69c2142f6401f2b7414b8efa"), "name" : "Rose", "age" : 39, "salary" : 60000 }
{ "_id" : ObjectId("69c214426401f2b7414b8efb"), "name" : "Rahul" }

Q) does it return 100000 of document at once.

2. > db.users.findOne() (returns 1st filtered document)
{
	"_id" : ObjectId("69c2142f6401f2b7414b8efa"),
	"name" : "Rose",
	"age" : 39,
	"salary" : 60000
}

3. > db.users.findOneAndDelete({name:"Rahul"})
{ "_id" : ObjectId("69c214426401f2b7414b8efb"), "name" : "Rahul" } (return deleted document)

4. > db.users.findOneAndUpdate({name:"Raju"},{$set:{name:"Rahul Mishra"}})
{ "_id" : ObjectId("69c21e4e6401f2b7414b8efd"), "name" : "Raju" } (return old doc)

5. > db.users.findOneAndReplace({name:"Rahul Mishra"},{name:"Raju kumar",age:33}) (replace the complete document)
{ "_id" : ObjectId("69c21e4e6401f2b7414b8efd"), "name" : "Rahul Mishra" }

// project if want to display the selected fields,(1 or 0) _id is selected by default


6. >> db.users.find({},{name:1})   (return name )
{ "_id" : ObjectId("69c2142f6401f2b7414b8efa"), "name" : "Rose" }
{ "_id" : ObjectId("69c21e4e6401f2b7414b8efd"), "name" : "Raju kumar" }

> db.users.find({},{name:1,_id:0})
{ "name" : "Rose" }
{ "name" : "Raju kumar" }


// if want to return all the attribute but not password or specific

> db.users.find({},{_id:0})
{ "name" : "Rose", "age" : 39, "salary" : 60000 }
{ "name" : "Raju kumar", "age" : 33 }


// nested attribute projection
7. >> > db.users.find({name:"Rose"},{name:1,_id:0,"detail.city":1}) (use string for nested projection)
{ "name" : "Rose", "detail" : { "city" : "Ludianan" } }



// what if we want to find the users with no emial id exist

8. >> db.users.find({detail:null})
{ "_id" : ObjectId("69c21e4e6401f2b7414b8efd"), "name" : "Raju kumar", "age" : 33 }

// use regex search .com mail end with



9. > show dbs (show dabtabase available)
Proctice            0.000GB
admin               0.000GB
config              0.000GB
demoDatabase        0.000GB
employeeManagement  0.001GB
getreal             0.008GB
inlinkpay           0.000GB
local               0.000GB
mydatabase          0.000GB
myprojectdbname     0.002GB
sk-mesta            0.007GB
studentkare-17      0.001GB

 10. > show collections  (show all the collecitns of current databse)
users







>> next 10

logical and comparison operators

demo data is below

comparison operators ($eq, $gt, $lt, $gte, $lte, $ne, $in $nin)

1. Age greater than 28

>> > db.users.find({age:{$gt:28}})
{ "_id" : ObjectId("69c515b235cacf7bf3acc144"), "name" : "Priya Verma", "age" : 30, "salary" : 60000, "city" : "Mumbai", "isActive" : false, "skills" : [ "Python", "Django" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc147"), "name" : "Arjun Mehta", "age" : 35, "salary" : 80000, "city" : "Pune", "isActive" : false, "skills" : [ "Go", "Microservices" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc149"), "name" : "Vikas Yadav", "age" : 32, "salary" : 70000, "city" : "Delhi", "isActive" : false, "skills" : [ "DevOps", "AWS" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc14b"), "name" : "Karan Malhotra", "age" : 29, "salary" : 55000, "city" : "Bangalore", "isActive" : false, "skills" : [ "C++", "Algorithms" ] }


2. Salary between 40k and 60k

>>> > db.users.find({salary:{$gte:40000,$lte:60000}})
{ "_id" : ObjectId("69c515b235cacf7bf3acc143"), "name" : "Amit Sharma", "age" : 25, "salary" : 40000, "city" : "Delhi", "isActive" : true, "skills" : [ "JavaScript", "Node.js" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc144"), "name" : "Priya Verma", "age" : 30, "salary" : 60000, "city" : "Mumbai", "isActive" : false, "skills" : [ "Python", "Django" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc146"), "name" : "Neha Gupta", "age" : 28, "salary" : 50000, "city" : "Delhi", "isActive" : true, "skills" : [ "React", "Node.js" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc148"), "name" : "Sneha Kapoor", "age" : 27, "salary" : 45000, "city" : "Mumbai", "isActive" : true, "skills" : [ "Angular", "TypeScript" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc14b"), "name" : "Karan Malhotra", "age" : 29, "salary" : 55000, "city" : "Bangalore", "isActive" : false, "skills" : [ "C++", "Algorithms" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc14c"), "name" : "Anjali Joshi", "age" : 26, "salary" : 48000, "city" : "Pune", "isActive" : true, "skills" : [ "JavaScript", "React" ] }


3. Return all the users who are not from delhi

> db.users.find({city:{$ne:"Delhi"}})
{ "_id" : ObjectId("69c515b235cacf7bf3acc144"), "name" : "Priya Verma", "age" : 30, "salary" : 60000, "city" : "Mumbai", "isActive" : false, "skills" : [ "Python", "Django" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc145"), "name" : "Rahul Singh", "age" : 22, "salary" : 30000, "city" : "Bangalore", "isActive" : true, "skills" : [ "Java", "Spring" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc147"), "name" : "Arjun Mehta", "age" : 35, "salary" : 80000, "city" : "Pune", "isActive" : false, "skills" : [ "Go", "Microservices" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc148"), "name" : "Sneha Kapoor", "age" : 27, "salary" : 45000, "city" : "Mumbai", "isActive" : true, "skills" : [ "Angular", "TypeScript" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc14a"), "name" : "Pooja Rani", "age" : 24, "salary" : 35000, "city" : "Chandigarh", "isActive" : true, "skills" : [ "HTML", "CSS" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc14b"), "name" : "Karan Malhotra", "age" : 29, "salary" : 55000, "city" : "Bangalore", "isActive" : false, "skills" : [ "C++", "Algorithms" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc14c"), "name" : "Anjali Joshi", "age" : 26, "salary" : 48000, "city" : "Pune", "isActive" : true, "skills" : [ "JavaScript", "React" ] }



in and nin ({ field: { $in: [value1, value2, value3] } })

4. find the users from delhi and mumbai

> db.users.find({city:{$in:["Delhi","Mumbai"]}})
{ "_id" : ObjectId("69c515b235cacf7bf3acc143"), "name" : "Amit Sharma", "age" : 25, "salary" : 40000, "city" : "Delhi", "isActive" : true, "skills" : [ "JavaScript", "Node.js" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc144"), "name" : "Priya Verma", "age" : 30, "salary" : 60000, "city" : "Mumbai", "isActive" : false, "skills" : [ "Python", "Django" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc146"), "name" : "Neha Gupta", "age" : 28, "salary" : 50000, "city" : "Delhi", "isActive" : true, "skills" : [ "React", "Node.js" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc148"), "name" : "Sneha Kapoor", "age" : 27, "salary" : 45000, "city" : "Mumbai", "isActive" : true, "skills" : [ "Angular", "TypeScript" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc149"), "name" : "Vikas Yadav", "age" : 32, "salary" : 70000, "city" : "Delhi", "isActive" : false, "skills" : [ "DevOps", "AWS" ] }
> 


5. find all the users who dont know javascrip react js or node js 

> db.users.find({skills:{$nin:["JavaScript","Node.js","React"]}})
{ "_id" : ObjectId("69c515b235cacf7bf3acc144"), "name" : "Priya Verma", "age" : 30, "salary" : 60000, "city" : "Mumbai", "isActive" : false, "skills" : [ "Python", "Django" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc145"), "name" : "Rahul Singh", "age" : 22, "salary" : 30000, "city" : "Bangalore", "isActive" : true, "skills" : [ "Java", "Spring" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc147"), "name" : "Arjun Mehta", "age" : 35, "salary" : 80000, "city" : "Pune", "isActive" : false, "skills" : [ "Go", "Microservices" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc148"), "name" : "Sneha Kapoor", "age" : 27, "salary" : 45000, "city" : "Mumbai", "isActive" : true, "skills" : [ "Angular", "TypeScript" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc149"), "name" : "Vikas Yadav", "age" : 32, "salary" : 70000, "city" : "Delhi", "isActive" : false, "skills" : [ "DevOps", "AWS" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc14a"), "name" : "Pooja Rani", "age" : 24, "salary" : 35000, "city" : "Chandigarh", "isActive" : true, "skills" : [ "HTML", "CSS" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc14b"), "name" : "Karan Malhotra", "age" : 29, "salary" : 55000, "city" : "Bangalore", "isActive" : false, "skills" : [ "C++", "Algorithms" ] }
> 

implement in and nin in js 

function inOperator(fieldValue, valuesArray) {
  // If field is an array (like skills)
  if (Array.isArray(fieldValue)) {
    return fieldValue.some(val => valuesArray.includes(val));
  }

  // Normal scalar comparison
  return valuesArray.includes(fieldValue);
}


Logical Operators ($and , $or , $not , $nor)

6. Active users in Delhi

> db.users.find({$and:[{city:"Delhi",isActive:true}]})
{ "_id" : ObjectId("69c515b235cacf7bf3acc143"), "name" : "Amit Sharma", "age" : 25, "salary" : 40000, "city" : "Delhi", "isActive" : true, "skills" : [ "JavaScript", "Node.js" ] }
{ "_id" : ObjectId("69c515b235cacf7bf3acc146"), "name" : "Neha Gupta", "age" : 28, "salary" : 50000, "city" : "Delhi", "isActive" : true, "skills" : [ "React", "Node.js" ] }


7. or

8. $not

$not → Negates a condition (not a value directly)
{ age: { $not: { $gt: 25 } } }




9. $nor → None of the conditions should match
{
  $nor: [
    { city: "Delhi" },
    { age: { $lt: 25 } }
  ]
}









>>> next 10

$add , $subtract , $multiply  $divide $abs Math.abs(x)
age = Math.max(age, 18) 
age = Math.min(age, 60)
age = age + 1
age = age * 1.05


🧩 1. Field Update Operators (Normal Queries)

Context: updateOne, updateMany (without [])
Nature: Direct mutation (imperative, atomic)

🔧 Assignment / Structural
Operator	Type
$set	Assign value
$unset	Remove field
$rename	Rename field

1. set :- sets new attribute or overrise the vlaie of the attribute if already exist.

works with updateone and updateMany 

> db.users.updateOne({},{$set:{age:25}})
{ "acknowledged" : true, "matchedCount" : 1, "modifiedCount" : 1 }

> db.users.updateOne({},{$set:{bonus:25000}})
{ "acknowledged" : true, "matchedCount" : 1, "modifiedCount" : 1 }
> db.users.findOne()
{
	"_id" : ObjectId("69c515b235cacf7bf3acc143"),
	"name" : "Amit Sharma",
	"age" : 25, // update
	"salary" : 40000,
	"city" : "Delhi",
	"isActive" : true,
	"skills" : [
		"JavaScript",
		"Node.js"
	],
	"bonus" : 25000 // create 
}


2. $unset :- used to remove a field and works with updateOne and updateMany 

> db.users.updateOne({},{$unset:{bonus:""}})  --> will delete the attribute bonus from the first document.
{ "acknowledged" : true, "matchedCount" : 1, "modifiedCount" : 1 }

> db.users.findOne()
{
	"_id" : ObjectId("69c515b235cacf7bf3acc143"),
	"name" : "Amit Sharma",
	"age" : 25,
	"salary" : 40000,
	"city" : "Delhi",
	"isActive" : true,
	"skills" : [
		"JavaScript",
		"Node.js"
	]
}


3. $rename :- used to rename the key , and it works with updateOne and updateMany and mostly we use it with updateMany because of the consistency


salary to baseSalary

> db.users.updateMany({},{$rename:{salary:"baseSalary"}})
{ "acknowledged" : true, "matchedCount" : 10, "modifiedCount" : 10 }



🔢 Arithmetic (Mutation-Oriented)
Operator	Type
$inc	Add / subtract  ---> a=a+(-1) or (10)
$mul	Multiply  ----> a=a*(20)



add 5000 bonus to the salary of each user

4. $inc :- 

> db.users.updateMany({},{$inc:{baseSalary:5000}}) --> will update the salary of each user with 5000
{ "acknowledged" : true, "matchedCount" : 10, "modifiedCount" : 10 }

cut the PF of 2000 from each users salary


> db.users.updateMany({},{$inc:{baseSalary:-2000}}) --> will reduce the 2000 from each users salary
{ "acknowledged" : true, "matchedCount" : 10, "modifiedCount" : 10 }


5. mul :- update the salary of each user by double 

> db.users.updateMany({},{$mul:{baseSalary:2}}) ---> will doble the salary of each user.


{ "acknowledged" : true, "matchedCount" : 10, "modifiedCount" : 10 }


📏 Comparison / Constraint
Operator	Type
$min	Apply upper bound  Math.min(30,60) --> used to normalize a value ,like if we have value grater then 60 it will convert that value to 60
$max	Apply lower bound Math.max(12,16)  --> save the value which is max, like the age must be 18 , it will convert the age of all the user to 18 if they are 12 13


6. $min 

we have user with age less then 18 and more then 60 normalize both

> db.users.updateMany({},{$min:{age:60}})  --> one user age was 70 now its 60
{ "acknowledged" : true, "matchedCount" : 10, "modifiedCount" : 1 }
> 


7. $max 

> db.users.updateMany({},{$max:{age:18}})  --> One uses age was 16 now its 18
{ "acknowledged" : true, "matchedCount" : 10, "modifiedCount" : 1 }


⏱️ Date / Metadata
Operator	Type
$currentDate	Set current date
$setOnInsert	Only on insert (upsert)

// add login time to each user with the current time 

8. $currentDate

> db.users.updateMany({},{$currentDate:{lastLogin:true}})
{ "acknowledged" : true, "matchedCount" : 10, "modifiedCount" : 10 }

> db.users.findOne()
{
	"lastLogin" : ISODate("2026-03-27T10:23:18.937Z")  -- curren date and time
}

 db.users.updateMany({},{$currentDate:{lastLogin:{$type:"date"}}})
{ "acknowledged" : true, "matchedCount" : 10, "modifiedCount" : 10 }
> db.users.findOne()

	"lastLogin" : ISODate("2026-03-27T10:25:21.553Z")


> db.users.updateMany({},{$currentDate:{lastLogin:{$type:"timestamp"}}})
{ "acknowledged" : true, "matchedCount" : 10, "modifiedCount" : 10 }
> db.users.findOne()

	"lastLogin" : Timestamp(1774607171, 1)



9. $setOnInsert :- This query is a canonical upsert pattern used in production systems for idempotent writes + audit fields.

It updates if the field exist , elase it create a new document.

db.users.updateOne(
  { email: "a@gmail.com" },
  {
    $set: { name: "A", updatedAt: new Date() },
    $setOnInsert: { createdAt: new Date() }
  },
  { upsert: true }
)


{
	"acknowledged" : true,
	"matchedCount" : 0,
	"modifiedCount" : 0,
	"upsertedId" : ObjectId("69c65ef8d24aaaa47e87fbde")
}



Search Phase
Find a document with email = "a@gmail.com"
Branching Behavior
If found → UPDATE
If not found → INSERT (upsert)


if document exist, just update it , not run setOnInsert, and if it not exist, create one and use setOnInsert to give createdAt date.

{
  email: "a@gmail.com",
  name: "A",
  createdAt: ISODate("2026-03-27T10:00:00Z"),
  updatedAt: ISODate("2026-03-27T10:00:00Z")
}

both the set and setOnInset aplied.






============================================================================================================================

Normal Update (Imperative) --> you tell mongodb to increase the value of this attribute

Aggregation (Declarative) --> you tell mongodb to execute this expression and recompute the value of this attribute (runs expression)

============================================================================================================================


>>>> Aggregation Operators (Expressions)

Context: aggregate() OR update pipeline [ ... ]
Nature: Declarative computation engine


Arithmetic Operators with aggrigation.

| Operator    | Type           |
| ----------- | -------------- |
| `$add`      | Addition       |
| `$subtract` | Subtraction    |
| `$multiply` | Multiplication |
| `$divide`   | Division       |
| `$mod`      | Modulus        |

aggregate()
updateMany([...]) (pipeline form)

10. It will just project the updated value not udpate the , db.

db.users.aggregate([
  {
    $project: {
      increasedAge: { $add: ["$age", 5] },
      reducedAge: { $subtract: ["$age", 5] },
      doubleAge: { $multiply: ["$age", 2] },
      halfAge: { $divide: ["$age", 2] },
      remainder: { $mod: ["$age", 3] }
    }
  }
])

if age is 20 
{
  increasedAge: 25,        --> 20+5 
  reducedAge: 15,          --> 20-5
  doubleAge: 40,           --> 20*2
  halfAge: 10,             --> 20/2
  remainder: 2             --> 20%3
}

But we want to update the age in database

11. update with aggrigation pipeline updateMany({},[{update at this stage}])

db.users.updateMany(
  {},
  [
    {
      $set: {
        age: { $add: ["$age", 5] }
      }
    }
  ]
)

> db.users.updateOne({},[{$set:{age:{$add:["$age",5]}}}])
{ "acknowledged" : true, "matchedCount" : 1, "modifiedCount" : 1 }

works for all arithmertic operatos

12. Write Aggregation Output to Collection

Mostly we use aggrigation to display the data only.

>>> $out (overwrite collection) -- replaces the full collection with new one

and

>>> $merge (safe)


these are two aggrigation stages.

----------------------------
$out real world use

Data migration (one-time)
Schema redesign
ETL batch jobs
Rebuilding collections
----------------------------


db.users.aggregate([
  {
    $project: {
      age: { $add: ["$age", 5] }
    }
  },
  { $out: "users" }
])


$merge --> if found update and if not create one 


db.users.aggregate([
  {
    $set: {
      age: { $add: ["$age", 5] }
    }
  },
  {
    $merge: "users"
  }
])

{
  $merge: {
    into: "users",
    on: "_id",
    whenMatched: "merge",     // merge fields
    whenNotMatched: "insert"  // insert new
  }
}
| Option           | Meaning       |
| ---------------- | ------------- |
| `"replace"`      | overwrite doc |
| `"merge"`        | merge fields  |
| `"keepExisting"` | ignore new    |
| `"fail"`         | throw error   |

will cover in aggrigation



🔄 Numeric Transformation

| Operator | Type           |
| -------- | -------------- |
| `$abs`   | Absolute value |
| `$round` | Round          |
| `$ceil`  | Round up       |
| `$floor` | Round down     |
| `$trunc` | Truncate       |



🔀 Conditional (Very Important)

Operator	Type
$cond	     If-else
$switch	     Multi-branch


will see in aggrigation



13.  









