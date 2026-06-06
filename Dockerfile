FROM alpine:3.18

RUN apk add --no-cache \
    luajit \
    nodejs \
    npm \
    bash

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# Link Luajit explicitly to the standard lua binary alias
RUN ln -sf /usr/bin/luajit /usr/bin/lua

EXPOSE 3000

CMD ["node", "server.js"]
