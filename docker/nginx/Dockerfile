FROM nginx:latest

COPY ./config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./config/nginx/conf.d /etc/nginx/conf.d
COPY ./config/nginx/proxy_params_common.conf /etc/nginx/
COPY ./config/nginx/proxy_params_websocket.conf /etc/nginx/
COPY ./config/html /usr/share/nginx/html
COPY ./config/ssl /etc/nginx/ssl