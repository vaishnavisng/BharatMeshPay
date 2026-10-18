# =========================================================
# Stage 1: Build the Application with Maven Wrapper
# =========================================================
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app

# Copy Maven wrapper and POM first for better Docker layer caching
COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B

# Copy source code and build production fat JAR
COPY src src
RUN ./mvnw clean package -DskipTests

# =========================================================
# Stage 2: Minimal Production JRE Runtime
# =========================================================
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Non-root user for cloud security best practices
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Copy built executable jar from builder stage
COPY --from=builder /app/target/*.jar app.jar

# Cloud providers (Render, Railway, Fly.io, Cloud Run) set dynamic $PORT
ENV PORT=8080
EXPOSE 8080

# Container-aware memory allocation (limits JVM heap automatically to container RAM)
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
