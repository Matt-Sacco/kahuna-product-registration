#!/bin/bash

echo "======================================"
echo "Kahuna API Test Suite"
echo "======================================"
echo ""

BASE_URL="http://localhost:8000"

echo "1. Testing Health Check..."
curl -s $BASE_URL/api/health | head -5
echo -e "\n"

echo "2. Testing API Root..."
curl -s $BASE_URL | head -5
echo -e "\n"

echo "3. Creating Client Account..."
curl -s -X POST $BASE_URL/api/create-account \
  -H "Content-Type: application/json" \
  -d '{"username":"testclient","password":"test123","role":"client"}' | head -5
echo -e "\n"

echo "4. Creating Admin Account..."
curl -s -X POST $BASE_URL/api/create-account \
  -H "Content-Type: application/json" \
  -d '{"username":"testadmin","password":"admin123","role":"admin"}' | head -5
echo -e "\n"

echo "5. Login as Client..."
LOGIN_RESPONSE=$(curl -s -X POST $BASE_URL/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testclient","password":"test123"}')
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
echo "Token received: ${TOKEN:0:20}..."
echo ""

echo "6. Register Product..."
curl -s -X POST $BASE_URL/api/register-product \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $TOKEN" \
  -d '{"serial":"KHWM8199911"}' | head -8
echo -e "\n"

echo "7. View All Products..."
curl -s $BASE_URL/api/view-products \
  -H "X-Api-Key: $TOKEN" | head -15
echo -e "\n"

echo "8. View Single Product..."
curl -s "$BASE_URL/api/view-product?serial=KHWM8199911" \
  -H "X-Api-Key: $TOKEN" | head -10
echo -e "\n"

echo "9. Login as Admin..."
ADMIN_LOGIN=$(curl -s -X POST $BASE_URL/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testadmin","password":"admin123"}')
ADMIN_TOKEN=$(echo $ADMIN_LOGIN | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
echo "Admin token received: ${ADMIN_TOKEN:0:20}..."
echo ""

echo "10. Add Product (Admin)..."
curl -s -X POST $BASE_URL/api/add-product \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: $ADMIN_TOKEN" \
  -d '{"serial":"KHTEST001","name":"Test Smart Device","warrantyLength":24}' | head -8
echo -e "\n"

echo "11. Logout..."
curl -s -X POST $BASE_URL/api/logout \
  -H "X-Api-Key: $TOKEN" | head -5
echo -e "\n"

echo "======================================"
echo "All tests completed!"
echo "======================================"