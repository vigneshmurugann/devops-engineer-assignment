FROM nginx:1.27-alpine

RUN addgroup -S -g 10001 app && adduser -S -u 10001 -G app app
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY . /usr/share/nginx/html

RUN chown -R app:app /usr/share/nginx/html /var/cache/nginx /var/run /var/log/nginx /run
USER 10001
EXPOSE 8080
