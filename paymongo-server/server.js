// Load environment variables from .env file
require('dotenv').config();

const express = require('express');
const bodyParser = require('body-parser');
const Paymongo = require('paymongo-node');

const app = express();
const port = 55901; // Change this to your preferred port


// Initialize PayMongo client
const paymongo = new Paymongo(process.env.PAYMONGO_SECRET_KEY || 'sk_test_UWP3hXVRoBAk4GuH8Q85Dvrk');

app.use(bodyParser.json());

app.post('/payment_intents', async (req, res) => {
    const { amount } = req.body;
  
    try {
      const paymentIntent = await paymongo.paymentIntents.create({
        data: {
          attributes: {
            amount: amount, // amount in cents
            currency: 'PHP',
            payment_method_types: ['gcash'],
          },
        },
      });
  
      res.json(paymentIntent);
    } catch (error) {
      console.error('Error creating payment intent:', error);
      res.status(500).json({ error: 'Payment intent creation failed.' });
    }
  });
  

// Optional: Set up a webhook endpoint
app.post('/webhook', async (req, res) => {
  const event = req.body;

  switch (event.type) {
    case 'payment_intent.succeeded':
      console.log('Payment succeeded:', event.data);
      break;
    case 'payment_intent.payment_failed':
      console.log('Payment failed:', event.data);
      break;
    default:
      console.log(`Unhandled event type ${event.type}`);
  }

  res.sendStatus(200);
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
