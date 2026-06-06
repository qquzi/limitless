FROM node:18-slim

RUN apt-get update && apt-get install -y lua5.3 && ln -s /usr/bin/lua5.3 /usr/bin/lua || true

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
