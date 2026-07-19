FROM bellsoft/liberica-runtime-container:jdk-21-stream-musl

COPY . /home/app/spring-petclinic
WORKDIR /home/app/spring-petclinic
RUN ./mvnw clean package -DskipTests

FROM bellsoft/liberica-runtime-container:jre-21-musl

WORKDIR /home/app
EXPOSE 8080

COPY --from=0 /home/app/spring-petclinic/target/*.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]