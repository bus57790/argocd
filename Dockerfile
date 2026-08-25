FROM node:18-alpine

WORKDIR /usr/src/app

# Explicitly copy package.json first
COPY package.json ./

# Install dependencies if present
RUN npm install --only=production || true

# Copy remaining project files
COPY . .

USER node

EXPOSE 3000

CMD ["node", "app.js"]
