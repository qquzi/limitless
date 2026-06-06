FROM node:18-bullseye-slim

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    make \
    && rm -rf /var/lib/apt/lists/*

# Clone and compile LuaJIT straight from the official source mirror repo
RUN git clone --depth 1 https://github.com \
    && cd luajit \
    && make \
    && make install \
    && ln -sf /usr/local/bin/luajit /usr/local/bin/lua \
    && cd .. \
    && rm -rf luajit

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
