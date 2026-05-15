# Stage-1
FROM alpine/git As repo

WORKDIR /repo

RUN git clone https://github.com/nithinvarma-git/java-example-varma-jar.git

# Stage -2

FROM maven AS builder

WORKDIR /app

COPY --from=repo /repo .

RUN mvn clean package -DskipTests

# Stage -3

FROM eclipse-temurin:17-jre

WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]






