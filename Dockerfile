# Use a simple, small base image
FROM node:20-alpine AS builder

# Add a non-root user for security
RUN addgroup -g 1001 -S appuser && \
    adduser -S appuser -G appuser -u 1001

# Set working directory
WORKDIR /app

# Copy a simple script
COPY hello.sh .

# Make it executable
RUN chmod +x hello.sh

# Switch to non-root user
USER appuser

# Define the command to run
CMD ["./hello.sh"]
