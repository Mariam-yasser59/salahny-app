export const stripePublishableKey = () => process.env.STRIPE_PUBLISHABLE_KEY || '';

export const stripeSecretConfigured = () => Boolean(process.env.STRIPE_SECRET_KEY);

export const stripeReady = () => Boolean(stripePublishableKey() && stripeSecretConfigured());

export const createPaymentIntent = async ({ amount, currency = 'usd', metadata = {} }) => {
  if (!process.env.STRIPE_SECRET_KEY) return null;
  const body = new URLSearchParams({
    amount: String(Math.round(amount * 100)),
    currency,
    ...Object.fromEntries(
      Object.entries(metadata).map(([key, value]) => [`metadata[${key}]`, String(value)]),
    ),
  });
  const response = await fetch('https://api.stripe.com/v1/payment_intents', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.STRIPE_SECRET_KEY}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body,
  });
  if (!response.ok) {
    throw new Error('Could not create Stripe payment intent');
  }
  return response.json();
};

export const getPaymentIntent = async (id) => {
  if (!process.env.STRIPE_SECRET_KEY || !id) return null;
  const response = await fetch(`https://api.stripe.com/v1/payment_intents/${id}`, {
    headers: { Authorization: `Bearer ${process.env.STRIPE_SECRET_KEY}` },
  });
  if (!response.ok) {
    throw new Error('Could not verify Stripe payment intent');
  }
  return response.json();
};
