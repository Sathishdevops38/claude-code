# Auth Service Dockerfile
FROM maven:3.8.1-openjdk-17-slim AS builder

WORKDIR /app
COPY ../../auth-service/pom.xml .
RUN mvn dependency:download-sources
COPY ../../auth-service .
RUN mvn clean package -DskipTests

FROM amazoncorretto:17-al2023-jdk

WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "app.jar"]
