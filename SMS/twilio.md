```javascript

const express=require('express');
const app=express();
const port=3000;
const twilio=require('twilio');

// Middleware to parse JSON bodies
app.use(express.json());

// Twilio configuration
const accountSid='abcd1234abcd1234abcd1234abcd1234'; // Your Account SID from www.twilio.com/console
const authToken='abcd1234abcd1234abcd1234abcd1234'; // Your Auth Token from www.twilio.com/console
const client=new twilio(accountSid,authToken);

app.get('/',(req,res)=>{
    res.send('Hello World!');
});

app.post("/send-sms",async (req,res)=>{
const {to, message}=req.body;

try{
    const sms=await client.messages.create({
        body:message,
        from:'+12408720065', // Your Twilio number
        to:to
    });
    res.status(200).send({success:true, sid:sms.sid});
}
catch (error) {
    console.error("Error sending SMS:", error);
    res.status(500).send({success:false, error:error.message});
}
});

app.listen(port,()=>{
    console.log(`Server is running at http://localhost:${port}`);
});

```
