# ============================================================
# Techbleat Global Bank Frontend - Dockerfile (Debug Version)
# Single-stage build for easier debugging
# ============================================================

FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy all source code
COPY . .

# List files before build (for debugging)
RUN ls -la

# Build the application
RUN npm run build

# List files after build to see what was created
RUN echo "=== Files after build ===" && ls -la

# Install serve globally
RUN npm install -g serve

# Expose port 3000
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production

# Try to start serve - adjust folder name if needed
CMD ["sh", "-c", "ls -la && serve -s build -l 3000 || serve -s dist -l 3000 || serve -s . -l 3000"]