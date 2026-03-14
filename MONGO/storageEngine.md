# WiredTiger storage engine


WiredTger is a embedded database engine.
- general purpose toolkit.
- high performing : scalable throughput with low latency.


Why its name is WiredTiger storage engin?
WiredTiger storage engine. Within this engine, collections and indexes are stored separately, but both ultimately rely on B+Tree-based structures and disk pages.


## High-Level MongoDB Storage Architecture


```ts
Application Query
       │
       ▼
MongoDB Query Engine
       │
       ▼
Storage Engine (WiredTiger)
       │
       ▼
+---------------------------+
| WiredTiger File Manager   |
+---------------------------+
       │
       ▼
+-------------------------------+
| Collection Files (.wt)        |
| Index Files (.wt)             |
+-------------------------------+
       │
       ▼
Disk Pages (default ~4KB–32KB)
```


Note :- Collection data and index data are stored in separate files.


```
dbpath/

 ├── collection-7--123456.wt
 ├── index-3--123456.wt
 ├── index-4--123456.wt
 └── WiredTiger.wt
```

Each .wt file is a WiredTiger table.


| File              | Purpose                             |
| ----------------- | ----------------------------------- |
| `collection-*.wt` | Stores BSON documents               |
| `index-*.wt`      | Stores index keys                   |
| `WiredTiger.wt`   | Metadata catalog for storage engine |


**All of these are separate B+Tree tables managed by WiredTiger.**


```ts
MongoDB Database
        │
        ▼
Storage Engine
(WiredTiger)
        │
        ▼
┌──────────────────────────────────────┐
│ Metadata Catalog                     │
│ WiredTiger.wt                        │
│                                      │
│ maps logical objects → files         │
└──────────────────────────────────────┘
        │
        ▼
┌───────────────────┐    ┌───────────────────┐
│ Collection File    │    │ Index File        │
│ collection-7.wt    │    │ index-3.wt        │
│                    │    │                   │
│ B+Tree             │    │ B+Tree            │
│                    │    │                   │
│ Leaf → BSON docs   │    │ Leaf → key + RID  │
└───────────────────┘    └───────────────────┘
        │                         │
        └──────────────┬──────────┘
                       ▼
               Disk Pages
               (4KB – 32KB)
                       │
                       ▼
              WiredTiger Cache
                       │
                       ▼
                  Journal Logs
```


```
Collection = B+Tree of documents
Index      = B+Tree of keys
```

WiredTiger.wt  :- stored th information about the fles stored in this folder like collection and index files and redirects the query to that file.
collection-7.wt :- stors the information about collection.

collection-7.wt is not a metadata file describing the collection.
It is the actual storage file that holds the collection’s data when MongoDB uses the WiredTiger storage engine.

So its responsibility is:

```
Store the BSON documents of that collection
```

Internally it is implemented as a B+Tree table managed by WiredTiger.

#### When you create a collection:


```
db.createCollection("users")
```

MongoDB internally creates a WiredTiger table:

```
collection-7.wt
```
Mapping is stored in WiredTiger.wt metadata.
Internal structure 


```
collection-7.wt

+----------------------------------+
| File Header                      |
+----------------------------------+
| Root Page                        |
+----------------------------------+
| Internal Pages                   |
+----------------------------------+
| Leaf Pages                       |
+----------------------------------+
```

B+tree structure inside file

```
                     ROOT
                      │
          ┌───────────┴───────────┐
          │                       │
      INTERNAL NODE           INTERNAL NODE
          │                       │
      ┌───┴────┐             ┌────┴─────┐
      │        │             │          │
    LEAF     LEAF          LEAF       LEAF

```
| page type | purpose                |
| --------- | ---------------------- |
| root      | entry point            |
| internal  | navigation             |
| leaf      | store actual documents |


File Header Structure

#### First part of the file contains metadata for WiredTiger.

Typical information stored:


```
File Header
 ├── file identifier
 ├── page size configuration
 ├── checkpoint information
 ├── version information
 └── compression settings
```

Typical size:


```
~4KB
```


#### Internal pages contain keys and child pointers.

They guide navigation through the tree.


```
Internal Page

+--------------------------------------+
| Page Header                          |
+--------------------------------------+
| key: RID 2000 → child page 10        |
| key: RID 4000 → child page 14        |
| key: RID 8000 → child page 21        |
+--------------------------------------+
```


Meaning:

```
RID < 2000       → page 10
2000 ≤ RID <4000 → page 14
RID ≥ 4000       → page 21
```

RID = record it.

These pages do not store documents.
It stores the informaton of documents randes from 0 to 20000 go to this page 10.


#### Leaf Page Structure (Actual Collection Data)

It store 

```
RecordID → BSON document
```

Leaf Page


```
+---------------------------------------------------+
| Page Header                                       |
+---------------------------------------------------+
| Slot Array                                        |
|                                                   |
| slot1 → offset 120                                |
| slot2 → offset 350                                |
| slot3 → offset 700                                |
+---------------------------------------------------+
| Data Region                                       |
|                                                   |
| RID 1001 → {name:"Alex", age:25}                  |
| RID 1002 → {name:"Emma", age:30}                  |
| RID 1003 → {name:"John", age:19}                  |
+---------------------------------------------------+
| Free Space                                        |
+---------------------------------------------------+
```

```
                          ROOT
                           │
                ┌──────────┴──────────┐
                │                     │
            INTERNAL              INTERNAL
                │
         ┌──────┴──────┐
         │             │
   LEAF PAGE A     LEAF PAGE B
   RID 1–1000      RID 1001–2000
                        │
                        ▼

        +-----------------------------------+
        | Leaf Page B                       |
        +-----------------------------------+
        | RID 1001 → {name:"Alex", age:25}  |
        | RID 1002 → {name:"Emma", age:30}  |
        | RID 1003 → {name:"John", age:19}  |
        +-----------------------------------+
```


## Index

For each index it creates a different file.


When an index is created:


```ts

db.users.createIndex({ age: 1 })

```

MongoDB creates a separate WiredTiger table:

```
index-3--123456.wt
```


Example storage layout:

```
dbpath/

 ├── collection-7--123456.wt
 ├── index-3--123456.wt
 ├── index-4--123456.wt
 └── WiredTiger.wt
```


```
Index Key  →  RecordID
```
The RecordID (RID) points to the document stored in the collection file.

#### Query flow 

```ts
db.users.find({ age: 25 })
```

```

```















