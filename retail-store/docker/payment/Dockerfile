# Payment Service Dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY payment-service/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY payment-service .

EXPOSE 8084

CMD ["gunicorn", "--bind", "0.0.0.0:8084", "app:app"]
