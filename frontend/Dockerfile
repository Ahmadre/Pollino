FROM dart:stable AS build

WORKDIR /app
COPY . .
RUN dart pub get
RUN flutter build web

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html