# Multi-stage Dockerfile for CivicPulse Spring Boot Backend (Java 21 LTS)
# Stage 1: Build the application artifact
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /build

# Copy Gradle wrapper and configuration files first to cache dependencies
COPY gradlew .
COPY gradle gradle
COPY build.gradle.kts settings.gradle.kts ./

RUN chmod +x ./gradlew && ./gradlew dependencies --no-daemon

# Copy source code and build production jar (tests run in dedicated CI stage)
COPY src src
RUN ./gradlew bootJar --no-daemon -x test

# Stage 2: Minimal, hardened production runtime
FROM eclipse-temurin:21-jre-alpine AS runner

# Install curl for container health check
RUN apk add --no-cache curl

# Run as non-privileged system user per AGENTS.md security guidelines
RUN addgroup -S civicpulse && adduser -S civicpulse -G civicpulse

WORKDIR /app

# Copy executable jar from builder stage
COPY --from=builder /build/build/libs/civicpulse-backend-0.0.1-SNAPSHOT.jar /app/civicpulse-backend.jar
RUN chown -R civicpulse:civicpulse /app

USER civicpulse

EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=5s --retries=3 --start-period=40s \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "/app/civicpulse-backend.jar"]
