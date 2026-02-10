import axios, { AxiosInstance } from 'axios';

const API_BASE_URL = 'http://localhost:8081/api';

const api: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Auth API
export const authAPI = {
  register: (email: string, password: string, firstName: string, lastName: string, username: string) =>
    api.post('/auth/register', { email, password, firstName, lastName, username }),

  login: (email: string, password: string) =>
    api.post('/auth/login', { email, password }),

  validateToken: (token: string) =>
    api.get(`/auth/validate-token/${token}`),

  getUser: (userId: number) =>
    api.get(`/auth/user/${userId}`),
};

// Product API
export const productAPI = {
  getAllProducts: () =>
    axios.get('http://localhost:8082/api/products'),

  getProductById: (id: number) =>
    axios.get(`http://localhost:8082/api/products/${id}`),

  searchProducts: (query: string) =>
    axios.get(`http://localhost:8082/api/products/search?q=${query}`),

  getProductsByCategory: (category: string) =>
    axios.get(`http://localhost:8082/api/products/category/${category}`),

  createProduct: (productData: any) =>
    axios.post('http://localhost:8082/api/products', productData),

  updateProduct: (id: number, productData: any) =>
    axios.put(`http://localhost:8082/api/products/${id}`, productData),

  deleteProduct: (id: number) =>
    axios.delete(`http://localhost:8082/api/products/${id}`),
};

// Order API
export const orderAPI = {
  createOrder: (orderData: any) =>
    axios.post('http://localhost:8083/api/orders', orderData),

  getOrder: (orderId: number) =>
    axios.get(`http://localhost:8083/api/orders/${orderId}`),

  getUserOrders: (userId: number) =>
    axios.get(`http://localhost:8083/api/orders/user/${userId}`),

  getAllOrders: () =>
    axios.get('http://localhost:8083/api/orders'),

  updateOrderStatus: (orderId: number, statusData: any) =>
    axios.put(`http://localhost:8083/api/orders/${orderId}/status`, statusData),
};

// Payment API
export const paymentAPI = {
  processPayment: (paymentData: any) =>
    axios.post('http://localhost:8084/api/payments/process', paymentData),

  getPayment: (transactionId: string) =>
    axios.get(`http://localhost:8084/api/payments/${transactionId}`),

  getPaymentByOrder: (orderId: number) =>
    axios.get(`http://localhost:8084/api/payments/order/${orderId}`),

  refundPayment: (paymentId: number) =>
    axios.post(`http://localhost:8084/api/payments/${paymentId}/refund`),
};

export default api;
