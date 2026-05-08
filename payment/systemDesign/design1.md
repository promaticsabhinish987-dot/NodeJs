## Payment gateway design.

An online plateform that securely captures payment details of user and orchestrates transactions between merchants and financial processors.


### Payment Gateway:
A payment gateway is the plateform that collects payment details from users, secures and tokenizes them , orchestrates the transaction flow, and communicates with the payment processor.

### Payment processors:

A payment processor is the financial network entity that actually talks to banks and card networks to authorize ,capture and settle the money.

processor = "The system that actually moves the money"


# more

# Payment Gateway System Design - Complete Step-by-Step Explanation

## **PART 1: UNDERSTANDING THE BASICS**

### What is a Payment Gateway vs Payment Processor?

| **Payment Gateway** | **Payment Processor** |
|-------------------|----------------------|
| Traffic controller of payments | System that actually moves money |
| Collects payment details securely | Talks to banks & card networks |
| Tokenizes & orchestrates transaction flow | Authorizes, captures & settles money |
| Example: Your system | Example: Razorpay, PayU, Stripe (backend) |

---

## **PART 2: SYSTEM REQUIREMENTS**

### Functional Requirements
1. Client can create a **payment intent**
2. Gateway creates a **temporary session page** for card details
3. **Securely handle PCI compliant data**
4. Provide **transaction status** to client

### Non-Functional Requirements
- **Scale**: 10,000 transactions per second (10k TPS)
- **Consistency > Availability** (CAP theorem - money transactions)
- **Latency**: <200ms for payment authorization
- **Security**: PCI DSS compliant

---

## **PART 3: CORE ENTITIES**
- Merchant (Client - Amazon, Flipkart)
- Transaction
- Payment Method (Visa, Mastercard)
- User/Customer
- Webhook (callback for status)
- Payment Session

---

## **PART 4: STEP-BY-STEP FLOW WITH COMPONENTS**

### 🔷 **STEP 1: Payment Intent Creation**

```
User clicks "Buy Now" → Merchant → Payment Gateway
```

| Component | Responsibility | Interaction |
|-----------|---------------|-------------|
| **API Gateway + Load Balancer** | Routes traffic, authentication, rate limiting | First point of contact for all requests |
| **Payment Intent Service** | Receives payment metadata (amount, currency, order ID) | Stores in database |
| **Payment Intent DB (PostgreSQL)** | Persistent storage of intent metadata | Returns auto-generated Payment Intent ID |

**Response**: `{ "payment_intent_id": "pi_123456" }`

---

### 🔷 **STEP 2: Create Payment Session**

```
Merchant → Payment Gateway (with payment_intent_id)
```

| Component | Responsibility | Interaction |
|-----------|---------------|-------------|
| **Checkout Session Service** | Creates short-lived session (10 min TTL) | Stores session data in Redis |
| **Redis Cache** | Fast, temporary storage for session | TTL = 10 minutes (session timeout) |
| **Load Balancer** | Distributes frontend traffic | Routes to Checkout Frontend Service |
| **Checkout Frontend Service** | Generates secure HTML payment page | Returns redirect URL |

**Response**: 
```
{
  "session_id": "sess_789",
  "redirect_url": "https://paymentgateway.com/checkout?sess_789"
}
```

**Why is this secure?** - Card details NEVER touch merchant's servers. The payment page is hosted by the payment gateway.

---

### 🔷 **STEP 3: User Enters Card Details (CRITICAL SECURITY STEP)**

```
User receives payment page → Enters card number, CVV, expiry → Clicks "Pay"
```

**⚠️ The Security Concern You Asked About:**

> *"If client sends card detail to server it's not secure"*

**✅ HOW WE ACTUALLY HANDLE IT SECURELY:**

| Security Layer | Implementation |
|----------------|----------------|
| **No merchant involvement** | Card details go directly from user's browser → Payment Gateway's server (NOT merchant) |
| **HTTPS/TLS 1.3** | Encrypted transmission |
| **PCI DSS zone** | Isolated network segment for card processing |
| **No logging** | Card details never written to logs |
| **Browser security** | CSP headers, iframe sandboxing |
| **Tokenization** | Card replaced with token before leaving secure zone |

**The Actual Flow:**
```
User Browser → (TLS encrypted) → Checkout Backend Service (PCI Zone)
```

---

### 🔷 **STEP 4: Payment Processing (Inside PCI Zone)**

| Component | Responsibility | How it works |
|-----------|---------------|--------------|
| **Checkout Backend Service** | Validates session, checks expiry | Queries Redis for session validity |
| **Redis** | Returns session data if valid & not expired | Validates payment_intent_id matches |

**Validation checks:**
1. Does session exist?
2. Has session expired? (10 min TTL)
3. Does payment intent match?

---

### 🔷 **STEP 5: Tokenization (Most Critical Security Component)**

```
Checkout Backend → Tokenization Service (PCI Zone, TLS connection)
```

| Step | Component | Action |
|------|-----------|--------|
| 1 | **Tokenization Service** | Validates card number (Luhn algorithm) |
| 2 | **Tokenization Service** | Generates fingerprint: `hash(BIN + last4 + expiry + cardholder_name)` |
| 3 | **HSM (Hardware Security Module)** | Encrypts PAN (Primary Account Number) using hardware-grade encryption |

**What is HSM?**
- Physical hardware device for cryptographic operations
- Keys never leave the HSM
- Tamper-proof (destroys keys if tampered)
- Much more secure than software encryption

**Output**: `{ "encrypted_card_token": "tok_encrypted_xyz" }`

---

### 🔷 **STEP 6: Orchestration & Routing**

| Component | Responsibility | Interaction |
|-----------|---------------|-------------|
| **Orchestrator Service** | Decides which processor to use | Queries Merchant Preference DB |
| **Merchant Preference DB** | Stores which processor each merchant prefers | Returns: "Amazon → Razorpay" |
| **Adapter Pattern** | Converts request format for specific processor | Razorpay connector, PayU connector |

**Why adapter pattern?** - Each payment processor has different API formats. Adapters normalize them.

---

### 🔷 **STEP 7: Call Payment Processor**

```
Orchestrator → Connector (Razorpay/PayU) → Processor Gateway → Bank
```

| Component | Responsibility |
|-----------|---------------|
| **Payment Transaction DB** | Stores transaction status as "SENT" |
| **Processor Gateway** | External entity, communicates with bank networks |
| **Bank** | Authorizes or declines transaction |

---

### 🔷 **STEP 8: Handle Response (Event-Driven)**

```
Processor → Callback → Kafka → Update Database
```

| Component | Responsibility |
|-----------|---------------|
| **Callback Service** | Receives immediate response from processor |
| **Kafka Broker** | Decouples services, handles high throughput |
| **Topic 1: payment.processor.callback** | Immediate status updates |
| **Topic 2: payment.processor.final** | Final settlement (24-48 hour delay) |
| **Orchestrator (as consumer)** | Reads from Kafka, updates Payment Transaction DB |

---

### 🔷 **STEP 9: Notify User**

```
Checkout Backend Service polls Payment Transaction DB → Returns status to Frontend → User sees result
```

**Polling mechanism:** Frontend continuously checks for status change.

---

### 🔷 **STEP 10: Reconciliation (Final Verification)**

| Component | Responsibility |
|-----------|---------------|
| **Reconciliation Service** | Reads final status from Kafka topic 2 |
| **Compares** | Immediate status vs Final settlement status |
| **Updates Ledger** | Creates final payment record after 24-48 hours |
| **Handles discrepancies** | If money deducted but marked failed - triggers refund |

**Why reconciliation is needed:**
- Bank may deduct money but network fails
- Processor may show success but bank declines
- Ensures 100% accuracy for money transactions

---

## **PART 5: COMPLETE INTERACTION MAP**

```
┌─────────┐    1. Payment Intent     ┌──────────────┐    2. Store Metadata    ┌────────────┐
│ Merchant│ ───────────────────────→ │Payment Intent│ ────────────────────→ │ PostgreSQL │
│ (Client)│ ←─────────────────────── │   Service    │ ←──────────────────── │ (Intent DB)│
└─────────┘    Return Intent ID      └──────────────┘                        └────────────┘
      │
      │ 3. Create Session
      ↓
┌──────────────┐    4. Store session    ┌─────────┐
│Checkout      │ ────────────────────→ │ Redis   │
│Session Service│ ←──────────────────── │ (TTL=10)│
└──────────────┘                        └─────────┘
      │
      │ 5. Return redirect URL
      ↓
┌──────────────┐
│Checkout      │ ───→ User enters card details on THIS page (not merchant)
│Frontend      │
│Service       │
└──────────────┘
      │
      │ 6. User clicks "Pay" (TLS encrypted)
      ↓
┌──────────────┐    7. Validate session    ┌─────────┐
│Checkout      │ ───────────────────────→ │ Redis   │
│Backend       │ ←─────────────────────── │         │
│Service       │                          └─────────┘
└──────────────┘
      │
      │ 8. Tokenize card (TLS, PCI Zone)
      ↓
┌──────────────┐    9. Validate + Fingerprint + HSM Encrypt
│Tokenization  │ ─────────────────────────────────────────┐
│Service       │ ←────────────────────────────────────────┘
│(PCI Zone)    │   10. Return encrypted token
└──────────────┘
      │
      │ 11. Encrypted token
      ↓
┌──────────────┐    12. Check merchant preference    ┌─────────────┐
│ Orchestrator │ ─────────────────────────────────→ │Merchant Pref│
│   Service    │ ←───────────────────────────────── │     DB      │
└──────────────┘                                    └─────────────┘
      │
      │ 13. Route via adapter
      ↓
┌──────────────┐    14. Processor call    ┌─────────────┐
│ Connector    │ ──────────────────────→ │  Processor  │
│(Razorpay/    │                         │  Gateway    │
│ PayU)        │                         │ (External)  │
└──────────────┘                         └─────────────┘
      │                                            │
      │ 15. Store initial status                   │ 16. Callback
      ↓                                            ↓
┌──────────────┐                          ┌─────────────┐
│ Payment      │ ←────────────────────── │    Kafka    │
│ Transaction  │                          │   Broker    │
│ DB           │                          └─────────────┘
└──────────────┘                                  │
      │                                            │ 17. Consumer
      │ 18. Poll status                            ↓
      │                                    ┌─────────────┐
      ↓                                    │Reconciliation│
User sees result                           │   Service   │
                                           │ (24-48 hrs) │
                                           └─────────────┘
```

---

## **PART 6: KEY SECURITY MECHANISMS SUMMARY**

| **Threat** | **Solution** |
|------------|--------------|
| Card details intercepted during transmission | TLS 1.3 + HSM encryption |
| Merchant sees card details | Payment page hosted by gateway, not merchant |
| Database breach exposes cards | Tokenization - original PAN never stored |
| Hacker steals encryption keys | HSM - keys never leave hardware |
| Session hijacking | Session ID validation + short TTL |
| Replay attacks | Session ID + timestamp validation |
| Man-in-the-middle | Certificate pinning + mutual TLS |

---

## **PART 7: WHY THIS DESIGN WORKS FOR 10k TPS**

1. **Microservices** - Each component scales independently
2. **Redis** - Sub-millisecond session retrieval
3. **Kafka** - Async processing, handles spikes
4. **Stateless services** - Easy horizontal scaling
5. **Load balancers** - Distribute traffic evenly

---

Let me know if you need me to elaborate on any specific component or security mechanism!










