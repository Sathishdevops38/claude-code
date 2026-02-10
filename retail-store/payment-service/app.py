import os
import logging
from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from dotenv import load_dotenv
from datetime import datetime
import stripe
import uuid

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configure Stripe
stripe.api_key = os.getenv('STRIPE_SECRET_KEY', 'sk_test_dummy')

# Database configuration
db_config = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'user': os.getenv('DB_USER', 'root'),
    'password': os.getenv('DB_PASSWORD', 'root'),
    'database': os.getenv('DB_NAME', 'retail_payment_db'),
    'port': int(os.getenv('DB_PORT', 3306))
}

def get_db_connection():
    """Create database connection"""
    try:
        conn = mysql.connector.connect(**db_config)
        return conn
    except mysql.connector.Error as err:
        logger.error(f"Database connection error: {err}")
        return None

def init_db():
    """Initialize database tables"""
    conn = get_db_connection()
    if conn:
        cursor = conn.cursor()

        # Create payments table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS payments (
                id INT AUTO_INCREMENT PRIMARY KEY,
                order_id BIGINT NOT NULL,
                user_id BIGINT NOT NULL,
                amount DECIMAL(10, 2) NOT NULL,
                status VARCHAR(20) NOT NULL,
                payment_method VARCHAR(50),
                transaction_id VARCHAR(100) UNIQUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
        ''')

        conn.commit()
        cursor.close()
        conn.close()
        logger.info("Database initialized successfully")

@app.route('/api/payments/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'ok', 'service': 'payment-service'}), 200

@app.route('/api/payments/process', methods=['POST'])
def process_payment():
    """Process a payment"""
    try:
        data = request.get_json()

        # Validate input
        required_fields = ['order_id', 'user_id', 'amount', 'payment_method']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400

        order_id = data['order_id']
        user_id = data['user_id']
        amount = float(data['amount'])
        payment_method = data['payment_method']

        # Validate amount
        if amount <= 0:
            return jsonify({'error': 'Invalid amount'}), 400

        transaction_id = str(uuid.uuid4())

        # Process payment with Stripe (or mock for demo)
        try:
            if payment_method == 'stripe':
                # In production, you would use Stripe API
                payment_status = 'COMPLETED'
            else:
                payment_status = 'PENDING'
        except Exception as e:
            logger.error(f"Payment processing error: {e}")
            payment_status = 'FAILED'

        # Save payment record
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            insert_query = '''
                INSERT INTO payments (order_id, user_id, amount, status, payment_method, transaction_id)
                VALUES (%s, %s, %s, %s, %s, %s)
            '''
            cursor.execute(insert_query, (order_id, user_id, amount, payment_status, payment_method, transaction_id))
            conn.commit()
            cursor.close()
            conn.close()

        return jsonify({
            'transactionId': transaction_id,
            'orderId': order_id,
            'amount': amount,
            'status': payment_status,
            'paymentMethod': payment_method,
            'timestamp': datetime.now().isoformat()
        }), 200 if payment_status == 'COMPLETED' else 400

    except Exception as e:
        logger.error(f"Error processing payment: {e}")
        return jsonify({'error': 'Payment processing failed'}), 500

@app.route('/api/payments/<transaction_id>', methods=['GET'])
def get_payment(transaction_id):
    """Get payment details"""
    try:
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor(dictionary=True)
            query = 'SELECT * FROM payments WHERE transaction_id = %s'
            cursor.execute(query, (transaction_id,))
            payment = cursor.fetchone()
            cursor.close()
            conn.close()

            if payment:
                return jsonify(payment), 200
            else:
                return jsonify({'error': 'Payment not found'}), 404
        else:
            return jsonify({'error': 'Database connection failed'}), 500

    except Exception as e:
        logger.error(f"Error retrieving payment: {e}")
        return jsonify({'error': 'Failed to retrieve payment'}), 500

@app.route('/api/payments/order/<order_id>', methods=['GET'])
def get_payment_by_order(order_id):
    """Get payment for an order"""
    try:
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor(dictionary=True)
            query = 'SELECT * FROM payments WHERE order_id = %s'
            cursor.execute(query, (order_id,))
            payment = cursor.fetchone()
            cursor.close()
            conn.close()

            if payment:
                return jsonify(payment), 200
            else:
                return jsonify({'error': 'Payment not found'}), 404
        else:
            return jsonify({'error': 'Database connection failed'}), 500

    except Exception as e:
        logger.error(f"Error retrieving payment: {e}")
        return jsonify({'error': 'Failed to retrieve payment'}), 500

@app.route('/api/payments/<int:payment_id>/refund', methods=['POST'])
def refund_payment(payment_id):
    """Refund a payment"""
    try:
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor(dictionary=True)

            # Get payment
            query = 'SELECT * FROM payments WHERE id = %s'
            cursor.execute(query, (payment_id,))
            payment = cursor.fetchone()

            if not payment:
                cursor.close()
                conn.close()
                return jsonify({'error': 'Payment not found'}), 404

            # Update status to REFUNDED
            update_query = 'UPDATE payments SET status = %s WHERE id = %s'
            cursor.execute(update_query, ('REFUNDED', payment_id))
            conn.commit()
            cursor.close()
            conn.close()

            return jsonify({
                'id': payment_id,
                'status': 'REFUNDED',
                'refundedAt': datetime.now().isoformat()
            }), 200
        else:
            return jsonify({'error': 'Database connection failed'}), 500

    except Exception as e:
        logger.error(f"Error refunding payment: {e}")
        return jsonify({'error': 'Refund failed'}), 500

if __name__ == '__main__':
    # Initialize database
    init_db()

    # Run Flask app
    port = int(os.getenv('PORT', 8084))
    app.run(debug=os.getenv('DEBUG', False), host='0.0.0.0', port=port)
