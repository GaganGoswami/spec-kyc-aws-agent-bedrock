#!/bin/bash

# Wait for services script
# Waits for all Docker services to be healthy before proceeding

set -e

echo "⏳ Waiting for services to be ready..."

# Function to check if a service is healthy
check_service() {
  local service=$1
  local max_attempts=30
  local attempt=0

  echo "Checking $service..."
  
  while [ $attempt -lt $max_attempts ]; do
    if docker-compose ps | grep "$service" | grep -q "healthy\|Up"; then
      echo "✅ $service is ready"
      return 0
    fi
    
    attempt=$((attempt + 1))
    echo "  Waiting for $service... (attempt $attempt/$max_attempts)"
    sleep 2
  done

  echo "❌ $service failed to become ready"
  return 1
}

# Check PostgreSQL
check_service "postgres"

# Check LocalStack
check_service "localstack"

# Check Redis
check_service "redis"

echo ""
echo "🎉 All services are ready!"
echo ""
echo "You can now:"
echo "  - Run database migrations: cd backend && alembic upgrade head"
echo "  - Start backend: cd backend && poetry run uvicorn app.main:app --reload"
echo "  - Start frontend: cd frontend && npm run dev"
echo ""
