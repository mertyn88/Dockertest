FROM adoptopenjdk/openjdk11:alpine-jre
VOLUME /tmp
ARG JAR_FILE=build/libs/*.war
COPY ${JAR_FILE} app.war
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom","-jar","/app.war"]