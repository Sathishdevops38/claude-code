import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import './App.css';

// Import pages
import HomePage from './pages/HomePage';
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import ProductsPage from './pages/ProductsPage';
import CartPage from './pages/CartPage';
import OrdersPage from './pages/OrdersPage';

interface User {
  userId: number;
  email: string;
  username: string;
  firstName: string;
  lastName: string;
}

function App() {
  const [user, setUser] = useState<User | null>(null);
  const [cart, setCart] = useState<any[]>([]);
  const [token, setToken] = useState<string | null>(localStorage.getItem('token'));

  useEffect(() => {
    // Check if user is logged in
    const storedToken = localStorage.getItem('token');
    const storedUser = localStorage.getItem('user');
    if (storedToken && storedUser) {
      setToken(storedToken);
      setUser(JSON.parse(storedUser));
    }
  }, []);

  const handleLogin = (userData: User, authToken: string) => {
    setUser(userData);
    setToken(authToken);
    localStorage.setItem('token', authToken);
    localStorage.setItem('user', JSON.stringify(userData));
  };

  const handleLogout = () => {
    setUser(null);
    setToken(null);
    setCart([]);
    localStorage.removeItem('token');
    localStorage.removeItem('user');
  };

  const addToCart = (product: any) => {
    setCart([...cart, product]);
    alert('Product added to cart!');
  };

  const removeFromCart = (productId: number) => {
    setCart(cart.filter(item => item.id !== productId));
  };

  return (
    <Router>
      <div className="app">
        <header className="header">
          <div className="navbar">
            <Link to="/" className="logo">RetailStore</Link>
            <nav className="nav">
              <Link to="/">Home</Link>
              <Link to="/products">Products</Link>
              {user ? (
                <>
                  <Link to="/orders">My Orders</Link>
                  <span className="user-info">{user.firstName} {user.lastName}</span>
                  <button onClick={handleLogout}>Logout</button>
                </>
              ) : (
                <>
                  <Link to="/login">Login</Link>
                  <Link to="/register">Register</Link>
                </>
              )}
              <Link to="/cart" className="cart-icon">
                Cart ({cart.length})
              </Link>
            </nav>
          </div>
        </header>

        <main className="main-content">
          <Routes>
            <Route path="/" element={<HomePage />} />
            <Route path="/login" element={<LoginPage onLogin={handleLogin} />} />
            <Route path="/register" element={<RegisterPage />} />
            <Route path="/products" element={<ProductsPage onAddToCart={addToCart} />} />
            <Route path="/cart" element={<CartPage cart={cart} onRemoveFromCart={removeFromCart} user={user} />} />
            <Route path="/orders" element={user ? <OrdersPage userId={user.userId} /> : <LoginPage onLogin={handleLogin} />} />
          </Routes>
        </main>

        <footer className="footer">
          <p>&copy; 2024 RetailStore. All rights reserved.</p>
        </footer>
      </div>
    </Router>
  );
}

export default App;
