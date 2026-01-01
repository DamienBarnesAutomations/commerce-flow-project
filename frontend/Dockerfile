FROM node:20-alpine

WORKDIR /app

# Install dependencies first (better caching)
COPY package*.json ./
RUN npm install

# Copy the rest of the files
COPY . .

# Expose Vite's default port
EXPOSE 5173

# Run Vite with --host to allow Docker access
CMD ["npm", "run", "dev", "--", "--host"]