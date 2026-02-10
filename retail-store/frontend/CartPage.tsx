import React, { useState } from 'react';
import { orderAPI, paymentAPI } from '../api';

interface CartPageProps {
  cart: any[];
  onRemoveFromCart: (productId: number) => void;
  user: any;
}

const CartPage: React.FC<CartPageProps> = ({ cart, onRemoveFromCart, user }) => {
  const [address, setAddress] = useState('');
  const [loading, setLoading] = useState(false);

  const total = cart.reduce((sum, item) => sum + (item.price || 0), 0);

  const handleCheckout = async () => {
    if (!user) {
      alert('Please login to checkout');
      return;
    }

    if (!address) {
      alert('Please enter shipping address');
      return;
    }

    setLoading(true);
    try {
      // Create order
      const orderResponse = await orderAPI.createOrder({
        userId: user.userId,
        items: cart.map(item => ({ productId: item.id, quantity: 1 })),
        shippingAddress: address
      });

      // Process payment
      await paymentAPI.processPayment({
        order_id: orderResponse.data.id,
        user_id: user.userId,
        amount: total,
        payment_method: 'stripe'
      });

      alert('Order placed successfully!');
      setAddress('');
    } catch (error) {
      alert('Checkout failed');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="cart-page">
      <h1>Shopping Cart</h1>
      {cart.length === 0 ? (
        <p>Your cart is empty</p>
      ) : (
        <>
          <div className="cart-items">
            {cart.map(item => (
              <div key={item.id} className="cart-item">
                <span>{item.name}</span>
                <span>${item.price}</span>
                <button onClick={() => onRemoveFromCart(item.id)}>Remove</button>
              </div>
            ))}
          </div>
          <div className="cart-total">
            <h2>Total: ${total.toFixed(2)}</h2>
            <input
              type="text"
              placeholder="Shipping Address"
              value={address}
              onChange={(e) => setAddress(e.target.value)}
            />
            <button onClick={handleCheckout} disabled={loading}>
              {loading ? 'Processing...' : 'Checkout'}
            </button>
          </div>
        </>
      )}
    </div>
  );
};

export default CartPage;
