FROM node:18-alpine

WORKDIR /app

ENV NODE_ENV=production
ENV SERVER_PORT=8080

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

EXPOSE 8080

USER node

CMD ["node", "server.js"]
