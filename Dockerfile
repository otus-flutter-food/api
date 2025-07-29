# Use single stage build to ensure dependencies are properly installed
FROM dart:3.5.2

WORKDIR /app

# Copy pubspec files first for better caching
COPY pubspec.* ./

# Get dependencies with verbose output for debugging
RUN dart pub get --no-offline --verbose

# Copy all source files
COPY . .

# Ensure dependencies are available
RUN dart pub get --no-offline

# Expose the application port
EXPOSE 8888

# Run the server using Dart VM (JIT mode)
CMD ["dart", "run", "bin/main.dart"]

