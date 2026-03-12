

## ====================== Solution =========================

## 1Solution :-

### Goal :- fetch PORT with Author.

We have to return post with author data 2 query is required per post request. 

eg :- 

request :- get post with postId. 

```
GET /posts/:id
```


Database operation per request.


```ts
post = db.posts.findOne({_id})  // fetch that post
author = db.users.findOne({_id: post.authorId})  // also fetch the author of that post
```

Time taken by each query.

| Step | Query       | Complexity            |
| ---- | ----------- | --------------------- |
| 1    | Find post   | O(log N) index lookup |
| 2    | Find author | O(log M) index lookup |


```
1 req/sec  == 2 db query
10,000 req/sec == 20,000 req/sec
```

What is bad here?

1. index traversl also takes some time.
2. query parsing also takes time.
3. and more.

Right now we are requesting for only one post but what about list of posr.

fetch 100 post with author.

```
GET /posts/?limit=100
```

```
1 req/sec == fetch 100post (1 db query) , fetch 100 author (100 db query)

10,000 req/sec == 10,000 * 1 (10,000 db request for post) , fetch 10,000 * 100 author (10,00,000 db request for author)


1 db query to fetch ---- 100 post
100 db query to fetch ---- their 100 author

================================
100 + 1 --> query

called

N+1 problem
================================

```

Code 

```ts
posts = db.posts.find({})

for each post:
   db.users.findOne()
```

### Now we have to redesign the query or schema, to optimize it.

what are the possible solutions we have, we can also use hubrid, hybrid is nothing but we collect featured of all the tool and combine it to a single tool to get best possible reqult.


#### Embedding vs referencing

Every MongoDB schema design starts with one architectural decision:


```
Should related data live together or separately?
```

That leads to two strategies:

1. **Embedding** → store related data inside the same document

2. **Referencing** → store related data in another collection and link with an id

Understanding when each fails is the real knowledge gap.

Q1) list what are the limitation of each and when to use which and what are the options provided by ODM like mongoose.


##### Embedding (Data Co-Location)

Embedding means placing related data inside the parent document.
there can be multiple ways we can place data in one document. And each has their own limitation and importance.

Q2) But why we need mebedding?

embedding decreases the disk read like ,if we place author data inside each post created by him, will result.


```
1 req/sec == 1 db query
2 req/sec == 2 db query
```

Its better then the previous , then why we are not using this.

Because its easy to read from this , but not easy to update the author detail , like changing name of author , for this, we have to make changes in all the post, it also takes, extra space at each post.

Problems 

1. take extra space. Data duplication occur. (post collection size 100MB + 30MB for author data)
2. update become time consuming.

Time complexity 


| Operation          | Complexity |
| ------------------ | ---------- |
| Read post + author | O(log N)   |
| Update author name | O(P)       |

```
P = number of posts written by the user
```

Q3) Then which one to choose? before starting 1stunderstnad its type.


##### Types of embedding.

###### 1. Full embedding


like

```json
posts
{
   title
   author: {
       id
       name
       email
       avatar
       followers
   }
}
```


Benefits

1. we can read all the author attributed
2.  so only single requery is required, less effort , more resources.
3. We are not using the join of mongodb, which is god here.

But what are the limitations.

1. update :- for any attribute update , we have to update all the post O(P)
2. Occupy more and more space, have massive duplicates, which is bad , because we cant prefer duplicates.


Q4) Then how we can select or decide which one is good? lets learn about second type.


###### 2. Partial Embedding (Snapshot Pattern)

Only store **frequently read fields**. and fiels that we Only store frequently read fields..

Like 

```ts

posts
{
   title
   authorId
   authorSnapshot: {
       name
       avatar
   }
}

```
This is **partial denormalization**.
normalization means breaking , and denormalization means , collecting.


Benefits 

1. fast read , because embedding require only one query to read a data, like post and author
2. takes less space, then full embedding , minimal duplication , (author doc take less or minimal space in post doc), so overall size decreases.
3. most scalable pattern , we can also scale it , because it provide , very fast read and can work efficiently with large no of posts.


Then what can be the limitaions of it.

1. eventually changes, if we update author name ,post still show the old name, so we need to do background update name of author in all the post.

Q4) its looking nice, should we use it?



###### 3. Array Embedding


Used when one-to-few relationships exist. Only few.


```json
posts
{
   title
   comments: [
      {userId, text},
      {userId, text}
   ]
}
```

Benefits 

1. Very fast read because we have to call only one db request and we will get list of drelated data.
2.  atomic update (update only at sinle place)

Limitaion

1. Mongodb can store only 16MB of data, its limit 16MB per document

like if we store comment in post, and if coment goes large , doc will explode, we can store data that not grow much , like address.



### When Embedding works better.

its ideal for situation.


```
relationship = one-to-few
data changes rarely
data read together
```

like 

1. address inside user, we rarely update address, and fetch data togather, and address can be more.
2. product varients , we want all in one go.
3. small comment list.












