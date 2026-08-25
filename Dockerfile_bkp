FROM node:18-alpine

# Set working directory
WORKDIR /usr/src/app

# Copy dependency manifests
COPY package*.json ./

# Install dependencies
RUN npm install --only=production

# Copy application files
COPY . .

# Set non-root user for security (Passes SonarQube Docker Security Gate)
USER node

# Expose port
EXPOSE 3000

# Container entrypoint
CMD ["npm", "start"]
