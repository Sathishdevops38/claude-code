import React from 'react';

interface HomePageProps {}

const HomePage: React.FC<HomePageProps> = () => {
  return (
    <div className="home-page">
      <div className="hero">
        <h1>Welcome to RetailStore</h1>
        <p>Your one-stop shop for quality products</p>
        <a href="/products" className="cta-button">Shop Now</a>
      </div>

      <section className="features">
        <h2>Why Choose Us?</h2>
        <div className="features-grid">
          <div className="feature">
            <h3>Fast Delivery</h3>
            <p>Get your orders delivered quickly and safely</p>
          </div>
          <div className="feature">
            <h3>Secure Payment</h3>
            <p>Multiple payment options with secure transactions</p>
          </div>
          <div className="feature">
            <h3>Quality Products</h3>
            <p>All products carefully selected for quality</p>
          </div>
          <div className="feature">
            <h3>24/7 Support</h3>
            <p>Customer support available round the clock</p>
          </div>
        </div>
      </section>

      <section className="categories">
        <h2>Popular Categories</h2>
        <div className="categories-grid">
          <div className="category">Electronics</div>
          <div className="category">Fashion</div>
          <div className="category">Home & Garden</div>
          <div className="category">Sports</div>
        </div>
      </section>
    </div>
  );
};

export default HomePage;
