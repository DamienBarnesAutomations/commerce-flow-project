FROM node:20-slim

WORKDIR /app

# Install dependencies first (better caching)
COPY package*.json ./
RUN npm install

# Copy the rest of the code
COPY . .

# Expose the port from your compose file
EXPOSE 5175

CMD ["npm", "run", "dev"]