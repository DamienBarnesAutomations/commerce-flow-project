FROM node:20-slim
WORKDIR /app
COPY package.json ./
# Disabling the "progress bar" sometimes fixes hangs in Docker's terminal
RUN npm install --no-progress --loglevel warn
COPY . .
EXPOSE 5174
CMD ["npm", "run", "dev", "--", "--host"]