FROM node:18-alpine

# Set working directory
WORKDIR /usr/src/app

# Copy all application files directly to working directory
COPY . .

# Set non-root user for security
USER node

# Expose port
EXPOSE 3000

# Container entrypoint
CMD ["npm", "start"]
