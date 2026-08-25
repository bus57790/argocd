FROM node:18-alpine

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install --only=production || true

COPY . .

EXPOSE 3000

# Call Node directly on your entry file instead of npm start
CMD ["node", "app.js"]

