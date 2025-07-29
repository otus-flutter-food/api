# Build stage
FROM dart:3.5.2 AS builder

WORKDIR /app

# Copy pubspec files first for better caching
COPY pubspec.* ./
RUN dart pub get

# Copy all source files
COPY . .

# Compile the server
RUN dart compile exe bin/main.dart -o bin/server

# Runtime stage
FROM debian:bookworm-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled server and necessary files
COPY --from=builder /app/bin/server /app/bin/server
COPY --from=builder /app/config.yaml /app/config.yaml
COPY --from=builder /app/*.sh /app/

# Make scripts executable
RUN chmod +x /app/*.sh 2>/dev/null || true

# Expose the application port
EXPOSE 8888

# Run the compiled server
CMD ["/app/bin/server"]

