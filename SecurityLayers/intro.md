# Layer 1 :- Unauthorized Access to Private Routes

attack :- Unauthorized user can access private routes, or he can steal someones JWT sectet key and access the private route.

```
GET /api/private-data

```

solution :- 

1. Authenticate every request (for private routes, so that only logedin user can access private routes)
2. Validate JWT signature every time
3. Check token expiration , set expiry date or time.
4. Attach user to request, if he is authenticated or have verified JWT token, only then pass that request to the private route, and he can access only their private data so, in route find by id also.
5. Optionally implement token rotation, and refresh token. so that we not give data to the person who is not a actual user but have that access token.

Tools 

1. jsonwebtoken :- Used to cryptographically sign and verify identity tokens so the server can trust who the user is without storing session state.
2. httpOnly cookies :- Used to store authentication tokens in a way that prevents JavaScript access, mitigating XSS-based token theft.JavaScript running in the browser cannot read an httpOnly cookie.(no user can access that token by using frontend javascript)

```ts

res.cookie("token", jwtToken, {
  httpOnly: true
})

```
4. Middleware :- Used to centrally intercept requests and validate authentication before protected business logic executes.


Auth Middleware 

```ts

//jwt token auth middleware

const jwt = require("jsonwebtoken");

const authMiddleware = (req, res, next) => {
  try {
    const token = req.cookies.token; // httpOnly cookie

    if (!token) {
      return res.status(401).json({ message: "Unauthorized" });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ message: "Invalid or expired token" });
  }
};

```
Private Route

```ts

app.get("/api/private-data", authMiddleware, async (req, res) => {
  res.json({ message: "Protected data", user: req.user });
});

```

Extra Hardening

set cookie flags to make our cookie more secure with the environment.

```ts
res.cookie("token", token, {
  httpOnly: true,  //always true, so that no js can access it from frontend.
  secure: true,//Only attach this cookie if the connection is HTTPS If you will try to access it with https browser will not send the cookie.
//Ensures the cookie is only sent over HTTPS connections, preventing interception over insecure networks. Set to true in production (HTTPS only); may be false in local development without HTTPS. (HTTP is not secure , and we send data as text,, so anyone can acess row cookie data, if we send, because we send as plain test over http and https is secure because of encryption)
  sameSite: "strict", //Use "strict" when your frontend and backend are on the same domain and you want maximum CSRF protection. “Should this cookie be sent with cross-site requests?”
});


//sameSite: "strict" :- Cookie is sent only when request originates from the same site , else not send the cookie.
//sameSite: "lax" :- Cookie sent for top-level navigation (GET), Not sent for cross-site POST / fetch / iframe (user is authenticated only to get data for post and update they need cookie to send)Public web apps
//sameSite: "none" :- if sending request from unknown site , it must be secure , so secure true must be enable, use when the frontend and backend is differ, Oauth, and microservices implemented.


```
HTTPS = HTTP + TLS encryption.
Before data is sent:

Browser and server perform a TLS handshake

A symmetric session key is generated

All request data (including cookies) is encrypted

now the other user of that network see the encrypted data. 


Note :- 


```ts
app.use(cors({
  origin: "https://app.com", //Access-Control-Allow-Origin: https://app.com
//only request comes from this route is allowed.
note:- When using credentials, this cannot be * (wildcard). It must be a specific origin. 
  credentials: true //Access-Control-Allow-Credentials: true ,
//if server not allow credentials cookie not reach to server by frontned
}))
```
why credentials must be true in backend:- 

```ts

fetch(url, { credentials: "include" }) // to make browser send cookie we explicitly tell browser to send the cookie stored to this url.

```
why creadentials must be true in frontend
“If a website is calling another website, I should NOT send sensitive data like cookies automatically.” by defualt browser assumens it.

For cookies to travel cross-origin, two sides must agree.

Frontend says: “I want to send my identity.”

Backend says: “I allow you to send identity.”


if any side refuses cookie not send.


### Server must respond with

```

Access-Control-Allow-Origin: https://app.com
Access-Control-Allow-Credentials: true
Access-Control-Allow-Methods: GET,POST,PUT,DELETE
Access-Control-Allow-Headers: Content-Type, Authorization

```

# headers for server and frontend












