#!/bin/bash
set -e

echo "Waiting for PostgreSQL to be ready..."
while ! nc -z ${DATABASE_HOST:-postgres} ${DATABASE_PORT:-5432}; do
  sleep 1
done

echo "PostgreSQL is ready. Running migrations..."
dart pub global activate conduit 4.4.0
export PATH="$PATH:$HOME/.pub-cache/bin"

# Run migrations (will skip already applied migrations)
echo "Running database migrations..."
conduit db upgrade --connect postgres://${DATABASE_USER:-food}:${DATABASE_PASSWORD:-yaigoo2E}@${DATABASE_HOST:-postgres}:${DATABASE_PORT:-5432}/${DATABASE_NAME:-food} || {
    echo "Migration failed, but continuing (database might already be up to date)..."
}

echo "Starting the application..."
exec "$@"