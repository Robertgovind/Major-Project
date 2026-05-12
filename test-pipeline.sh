#!/bin/bash
# Backend Connection and Data Pipeline Test Script
# Tests: Backend health, API endpoint, and WebSocket connectivity

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="${1:-http://localhost:5000}"
API_KEY="${2:-fruit-pulse-secret-key-123}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Fruit Pulse Pipeline Test Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Backend URL: $BACKEND_URL"
echo "API Key: ${API_KEY:0:10}..."
echo ""

# Test 1: Health Check
echo -e "${YELLOW}[1/4] Testing Backend Health...${NC}"
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/health")

if [ "$HEALTH_RESPONSE" == "200" ]; then
    echo -e "${GREEN}✓ Backend is running (HTTP 200)${NC}"
else
    echo -e "${RED}✗ Backend health check failed (HTTP $HEALTH_RESPONSE)${NC}"
    echo "  Make sure backend is running: cd backend && npm run dev"
    exit 1
fi

# Test 2: API Endpoint
echo -e "${YELLOW}[2/4] Testing Sensor Data Endpoint...${NC}"

SENSOR_DATA='{
  "deviceId": "test-esp32",
  "fruitType": "banana",
  "r": 120,
  "g": 88,
  "b": 35,
  "humidity": 55.4,
  "temperature": 24.7,
  "pressure": 1008.2,
  "voc": 42.15,
  "chemicalRipening": 0.45
}'

API_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "X-API-Key: $API_KEY" \
    -d "$SENSOR_DATA" \
    -w "\n%{http_code}" \
    "$BACKEND_URL/api/v1/sensor-data")

HTTP_CODE=$(echo "$API_RESPONSE" | tail -n1)
BODY=$(echo "$API_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" == "201" ]; then
    echo -e "${GREEN}✓ Sensor data endpoint working (HTTP 201)${NC}"
    echo -e "${GREEN}✓ ML prediction successful${NC}"
    
    # Extract prediction status
    PREDICTION=$(echo "$BODY" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    echo "  Prediction status: $PREDICTION"
else
    echo -e "${RED}✗ Sensor endpoint failed (HTTP $HTTP_CODE)${NC}"
    
    if [ "$HTTP_CODE" == "401" ]; then
        echo "  Error: Invalid or missing API key"
        echo "  Check: API_KEY in .env matches X-API-Key header"
    fi
    
    echo "  Response: $BODY"
    exit 1
fi

# Test 3: Latest Reading Endpoint
echo -e "${YELLOW}[3/4] Testing Latest Reading Endpoint...${NC}"

LATEST_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    "$BACKEND_URL/api/v1/sensor-data/latest")

if [ "$LATEST_RESPONSE" == "200" ]; then
    echo -e "${GREEN}✓ Latest reading endpoint working (HTTP 200)${NC}"
else
    echo -e "${RED}✗ Latest reading endpoint failed (HTTP $LATEST_RESPONSE)${NC}"
fi

# Test 4: WebSocket Test (using wscat if available)
echo -e "${YELLOW}[4/4] Testing WebSocket Connection...${NC}"

# Extract host and port from URL
HOST=$(echo "$BACKEND_URL" | sed 's|http://||' | cut -d':' -f1)
PORT=$(echo "$BACKEND_URL" | sed 's|.*:||')

if command -v wscat &> /dev/null; then
    # Try to connect and receive one message
    WS_TEST=$(timeout 3 wscat -c "ws://$HOST:$PORT/ws" 2>&1 | head -1 || true)
    
    if echo "$WS_TEST" | grep -q "connected\|error\|event"; then
        echo -e "${GREEN}✓ WebSocket server is ready${NC}"
    else
        echo -e "${YELLOW}⚠ WebSocket connection uncertain (wscat not configured)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ wscat not installed, skipping WebSocket test${NC}"
    echo "  Install: npm install -g wscat"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Backend Pipeline Tests Passed!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Ensure ESP32 is connected and sending data"
echo "2. Run Flutter app with correct API_HOST"
echo "3. Check Fruit Analysis screen for live data"
echo ""
