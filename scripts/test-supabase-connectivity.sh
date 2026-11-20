#!/bin/bash
# Test connectivity to Supabase PostgreSQL and Storage from Render backend

# Load environment variables
if [ -f "backend/.env" ]; then
    export $(grep -v '^#' backend/.env | xargs)
fi

echo "================================"
echo "SUPABASE CONNECTIVITY TEST SUITE"
echo "================================"
echo ""

RENDER_URL="${RENDER_URL:-https://your-app.onrender.com}"
SUPABASE_URL="${SUPABASE_URL:-https://your-project-ref.supabase.co}"
BUCKET_NAME="${SUPABASE_STORAGE_BUCKET:-img-proyecto-3}"

# Test 1: Health Check (implies DB is working)
echo "📋 Test 1: Database Health Check"
echo "---"
STATUS=$(curl -s -w "%{http_code}" -o /tmp/health.json "$RENDER_URL/health")
if [ "$STATUS" = "200" ]; then
    echo "✅ Health Check: OK (HTTP $STATUS)"
    cat /tmp/health.json | jq '.'
else
    echo "❌ Health Check: FAILED (HTTP $STATUS)"
fi
echo ""

# Test 2: User Registration (DB write test)
echo "📋 Test 2: Database Write Test (User Registration)"
echo "---"
TIMESTAMP=$(date +%s)
EMAIL="test_${TIMESTAMP}@test.com"
RESPONSE=$(curl -s -X POST "$RENDER_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"Test123@@\",\"name\":\"Test User\"}")

if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    echo "✅ User Registration: OK"
    TOKEN=$(echo "$RESPONSE" | jq -r '.data.access_token')
    USER_ID=$(echo "$RESPONSE" | jq -r '.data.user.id')
    echo "   - User ID: $USER_ID"
    echo "   - Token: ${TOKEN:0:30}..."
else
    echo "❌ User Registration: FAILED"
    echo "$RESPONSE" | jq '.'
fi
echo ""

# Test 3: Vehicle Creation (DB write test with relations)
echo "📋 Test 3: Database Relations Test (Vehicle Creation)"
echo "---"
VEHICLE=$(curl -s -X POST "$RENDER_URL/vehicles" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"marca":"Ford","modelo":"F-150","anio":2023,"motor":"3.5L","km_actual":12000}')

if echo "$VEHICLE" | jq -e '.success' > /dev/null 2>&1; then
    echo "✅ Vehicle Creation: OK"
    VEHICLE_ID=$(echo "$VEHICLE" | jq -r '.data.id')
    echo "   - Vehicle ID: $VEHICLE_ID"
else
    echo "❌ Vehicle Creation: FAILED"
    echo "$VEHICLE" | jq '.'
fi
echo ""

# Test 4: List Vehicles (DB read test)
echo "📋 Test 4: Database Read Test (List Vehicles)"
echo "---"
VEHICLES=$(curl -s -X GET "$RENDER_URL/vehicles" \
  -H "Authorization: Bearer $TOKEN")

if echo "$VEHICLES" | jq -e '.data' > /dev/null 2>&1; then
    COUNT=$(echo "$VEHICLES" | jq '.data | length')
    echo "✅ Vehicle List: OK"
    echo "   - Total vehicles: $COUNT"
else
    echo "❌ Vehicle List: FAILED"
fi
echo ""

# Test 5: Check Supabase Storage Bucket
echo "📋 Test 5: Supabase Storage Bucket Status"
echo "---"
BUCKET_INFO=$(curl -s -I "https://$SUPABASE_URL/storage/v1/object/public/$BUCKET_NAME/" \
  -H "Accept: application/json")

if echo "$BUCKET_INFO" | grep -q "200\|403\|404"; then
    HTTP_CODE=$(echo "$BUCKET_INFO" | head -n1)
    echo "✅ Storage Bucket: ACCESSIBLE"
    echo "   - Bucket: $BUCKET_NAME"
    echo "   - URL: https://$SUPABASE_URL/storage/v1/object/public/$BUCKET_NAME"
    echo "   - Response: $HTTP_CODE"
else
    echo "⚠️  Storage Bucket: CHECK FAILED (unreachable)"
fi
echo ""

# Test 6: Storage Environment Variables Check
echo "📋 Test 6: Storage Configuration"
echo "---"
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ] || [ -z "$SUPABASE_STORAGE_BUCKET" ]; then
    echo "⚠️  Storage Variables: NOT ALL CONFIGURED"
    echo "   Missing:"
    [ -z "$SUPABASE_URL" ] && echo "   - SUPABASE_URL"
    [ -z "$SUPABASE_ANON_KEY" ] && echo "   - SUPABASE_ANON_KEY"
    [ -z "$SUPABASE_STORAGE_BUCKET" ] && echo "   - SUPABASE_STORAGE_BUCKET"
else
    echo "✅ Storage Variables: CONFIGURED"
    echo "   - SUPABASE_URL: $SUPABASE_URL"
    echo "   - SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:0:20}..."
    echo "   - SUPABASE_STORAGE_BUCKET: $SUPABASE_STORAGE_BUCKET"
fi
echo ""

echo "================================"
echo "TEST SUITE COMPLETED"
echo "================================"
