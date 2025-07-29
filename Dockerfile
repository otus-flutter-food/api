# Use single stage build to ensure dependencies are properly installed
FROM dart:3.5.4

WORKDIR /app

# Install netcat for database connectivity check
RUN apt-get update && apt-get install -y netcat-traditional && rm -rf /var/lib/apt/lists/*

# Copy pubspec files first for better caching
COPY pubspec.* ./

# Get dependencies with verbose output for debugging
RUN dart pub get --no-offline --verbose

# Copy all source files
COPY . .

# Ensure dependencies are available
RUN dart pub get --no-offline

# Make entrypoint executable
COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

# Expose the application port
EXPOSE 8888

# Use entrypoint to run migrations before starting the app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["dart", "run", "bin/main.dart"]

