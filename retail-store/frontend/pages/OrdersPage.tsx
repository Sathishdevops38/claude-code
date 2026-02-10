import React, { useState, useEffect } from 'react';
import { orderAPI } from '../api';

interface OrdersPageProps {
  userId: number;
}

const OrdersPage: React.FC<OrdersPageProps> = ({ userId }) => {
  const [orders, setOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchOrders();
  }, [userId]);

  const fetchOrders = async () => {
    try {
      const response = await orderAPI.getUserOrders(userId);
      setOrders(response.data);
      setLoading(false);
    } catch (error) {
      console.error('Failed to fetch orders:', error);
      setLoading(false);
    }
  };

  if (loading) return <div>Loading orders...</div>;

  return (
    <div className="orders-page">
      <h1>My Orders</h1>
      {orders.length === 0 ? (
        <p>No orders yet</p>
      ) : (
        <div className="orders-list">
          {orders.map(order => (
            <div key={order.id} className="order-card">
              <h3>Order #{order.id}</h3>
              <p>Status: <strong>{order.status}</strong></p>
              <p>Total: ${order.totalAmount}</p>
              <p>Shipping: {order.shippingAddress}</p>
              {order.trackingNumber && <p>Tracking: {order.trackingNumber}</p>}
              <div className="order-items">
                {order.items && order.items.map((item: any, index: number) => (
                  <div key={index} className="order-item">
                    {item.productName} x {item.quantity}
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default OrdersPage;
