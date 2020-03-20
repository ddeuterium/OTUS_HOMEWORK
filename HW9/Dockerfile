FROM alpine:3.9.4
RUN apk update  
RUN apk add nginx 
RUN adduser -D -g 'www' www 
COPY index.html /usr/share/nginx/html/index.html
COPY default.conf /etc/nginx/conf.d/default.conf

CMD ["nginx", "-g", "daemon off;"]
