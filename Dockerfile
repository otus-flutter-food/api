# Build stage
FROM dart:3.5.2 AS builder

WORKDIR /app

# Copy pubspec files first for better caching
COPY pubspec.* ./
RUN dart pub get

# Copy all source files
COPY . .

# Runtime stage - use the same dart image
FROM dart:3.5.2

WORKDIR /app

# Copy application from builder
COPY --from=builder /app /app

# Expose the application port
EXPOSE 8888

# Run the server using Dart VM (JIT mode)
CMD ["dart", "run", "bin/main.dart"]

