# Step 1: Base image
FROM node:18-alpine

# Step 2: Set working directory
WORKDIR /usr/src/app

# Step 3: Copy package files and install dependencies
COPY package*.json ./
RUN npm install --only=production

# Step 4: Copy application source code
COPY . .

# Step 5: Expose application port
EXPOSE 3000

# Step 6: Define default start command
CMD ["npm", "start"]
