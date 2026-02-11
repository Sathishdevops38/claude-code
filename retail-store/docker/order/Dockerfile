# Order Service Dockerfile
FROM maven:3.8.1-openjdk-17-slim AS builder

WORKDIR /app
COPY order-service/pom.xml .
RUN mvn dependency:download-sources
COPY order-service .
RUN mvn clean package -DskipTests

FROM openjdk:17-jdk-slim

WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8083

ENTRYPOINT ["java", "-jar", "app.jar"]
