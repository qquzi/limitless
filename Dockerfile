FROM node:18-bullseye-slim

RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    ca-certificates \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L -o luau.zip https://github.com \
    && unzip luau.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/luau \
    && ln -s /usr/local/bin/luau /usr/local/bin/lua \
    && rm luau.zip

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
