FROM maven:3.9.12-eclipse-temurin-17 AS build
WORKDIR /workspace
COPY pom.xml .
RUN mvn -B dependency:go-offline
COPY src src
RUN mvn -B package -DskipTests

FROM eclipse-temurin:17-jre-alpine
RUN addgroup -S caldova && adduser -S -G caldova -u 1001 caldova
WORKDIR /app
COPY --from=build /workspace/target/caldova-clinical-api-1.0.0.jar app.jar
USER 1001
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
    CMD wget -q -O - http://127.0.0.1:8000/live || exit 1
ENTRYPOINT ["java", "-jar", "/app/app.jar"]