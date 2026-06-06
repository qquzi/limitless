FROM node:18-bullseye-slim

RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    make \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L https://luajit.org | tar xz \
    && cd LuaJIT-2.1.0-beta3 \
    && make \
    && make install \
    && ln -sf /usr/local/bin/luajit /usr/local/bin/lua \
    && cd .. \
    && rm -rf LuaJIT-2.1.0-beta3

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
