FROM node:24.4


# Set working directory
WORKDIR /workspaces/compta-project/


# Copy package.json and package-lock.json first to leverage Docker cache
COPY package*.json ./


# Copy the rest of the application code
COPY . .

# Expose application port (change if needed)

EXPOSE 5173

# Start the application (change if needed)
CMD ["npm", "run", "dev"]