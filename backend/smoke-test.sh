#!/bin/bash
# Full smoke test for the Cember API (Phases A-C). Requires: docker compose up -d, then
# ASPNETCORE_ENVIRONMENT=Development dotnet run --project src/Cember.Api running on :5080.
set -e
BASE="http://localhost:5080/api/v1"
cd "$(dirname "${BASH_SOURCE[0]}")"

echo "=== health ==="
curl -sf "$BASE/health"
echo ""

echo "=== 1. Register host ==="
REG=$(curl -s -X POST "$BASE/auth/host/register" -H "Content-Type: application/json" -d '{"displayName":"Zeynep"}')
API_KEY=$(echo "$REG" | grep -o '"apiKey":"[^"]*"' | cut -d'"' -f4)
echo "apiKey=$API_KEY"

echo "=== 2. Create circle ==="
CIRCLE=$(curl -s -X POST "$BASE/circles" -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" -d '{"name":"Test Etkinligi","eventDate":"2026-09-20"}')
CIRCLE_ID=$(echo "$CIRCLE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo "circleId=$CIRCLE_ID"

echo "=== 3. Create invite ==="
INVITE=$(curl -s -X POST "$BASE/circles/$CIRCLE_ID/invite" -H "Authorization: Bearer $API_KEY")
TOKEN=$(echo "$INVITE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
echo "token=$TOKEN"

echo "=== 4. Invite preview (anonymous) ==="
curl -sf "$BASE/invite/$TOKEN" > /dev/null && echo "OK"

echo "=== 5. Join as guest ==="
JOIN=$(curl -s -X POST "$BASE/invite/$TOKEN/join" -H "Content-Type: application/json" -d '{"displayName":"Test Misafir"}')
GUEST_TOKEN=$(echo "$JOIN" | grep -o '"guestSessionToken":"[^"]*"' | cut -d'"' -f4)
echo "guestSessionToken set"

echo "=== 6. Guest uploads 3 photos ==="
UPLOAD=$(curl -s -X POST "$BASE/circles/$CIRCLE_ID/photos" -H "Authorization: Bearer $GUEST_TOKEN" \
  -F "files=@testdata/test1.jpg;type=image/jpeg" \
  -F "files=@testdata/test2.jpg;type=image/jpeg" \
  -F "files=@testdata/test3.jpg;type=image/jpeg")
echo "$UPLOAD" | grep -o '"errors":\[[^]]*\]'
PHOTO_ID=$(echo "$UPLOAD" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
THUMB_URL=$(echo "$UPLOAD" | grep -o '"thumbnailUrl":"[^"]*"' | head -1 | cut -d'"' -f4)
echo "photoId=$PHOTO_ID"

echo "=== 7. Thumbnail is fetchable ==="
curl -sf -o /dev/null "$THUMB_URL" && echo "OK 200"

echo "=== 8. Reaction toggles on/off/on ==="
curl -s -X POST "$BASE/photos/$PHOTO_ID/reactions" -H "Authorization: Bearer $API_KEY"
echo ""
curl -s -X POST "$BASE/photos/$PHOTO_ID/reactions" -H "Authorization: Bearer $API_KEY"
echo ""
curl -s -X POST "$BASE/photos/$PHOTO_ID/reactions" -H "Authorization: Bearer $API_KEY"
echo ""

echo "=== 9. Add + list comment ==="
curl -s -X POST "$BASE/photos/$PHOTO_ID/comments" -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" -d '{"body":"Harika kare!"}'
echo ""

echo "=== 10. Export zip as host ==="
curl -sf "$BASE/circles/$CIRCLE_ID/export.zip" -H "Authorization: Bearer $API_KEY" -o /tmp/cember_export_test.zip
unzip -l /tmp/cember_export_test.zip | tail -3

echo "=== 11. Disable guest downloads, guest export -> 403 ==="
curl -s -X PATCH "$BASE/circles/$CIRCLE_ID" -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" -d '{"allowGuestDownloads": false}' > /dev/null
CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/circles/$CIRCLE_ID/export.zip" -H "Authorization: Bearer $GUEST_TOKEN")
echo "guest export status: $CODE (expected 403)"

echo "=== 12. Profile stats ==="
curl -s "$BASE/me" -H "Authorization: Bearer $API_KEY"
echo ""

echo "=== 13. Create locked circle (isOpenJoin:false) ==="
LOCKED=$(curl -s -X POST "$BASE/circles" -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" -d '{"name":"Kilitli Test","eventDate":null,"isOpenJoin":false}')
LOCKED_ID=$(echo "$LOCKED" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
DETAIL=$(curl -s "$BASE/circles/$LOCKED_ID" -H "Authorization: Bearer $API_KEY")
echo "$DETAIL" | grep -o '"isOpenJoin":[a-z]*'

echo "=== 14. Delete request with zero participants -> immediate delete ==="
DEL0=$(curl -s -X POST "$BASE/circles/$LOCKED_ID/deletion-request" -H "Authorization: Bearer $API_KEY")
echo "$DEL0" | grep -o '"deleted":[a-z]*'
CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/circles/$LOCKED_ID" -H "Authorization: Bearer $API_KEY")
echo "get after delete: $CODE (expected 404)"

echo "=== 15. Circle with two eligible guest voters ==="
CIRCLE2=$(curl -s -X POST "$BASE/circles" -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" -d '{"name":"Oylama Testi","eventDate":null,"isOpenJoin":true}')
CIRCLE2_ID=$(echo "$CIRCLE2" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
INVITE2=$(curl -s -X POST "$BASE/circles/$CIRCLE2_ID/invite" -H "Authorization: Bearer $API_KEY")
TOKEN2=$(echo "$INVITE2" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

JOIN_A=$(curl -s -X POST "$BASE/invite/$TOKEN2/join" -H "Content-Type: application/json" -d '{"displayName":"Oylayan A"}')
GUEST_A=$(echo "$JOIN_A" | grep -o '"guestSessionToken":"[^"]*"' | cut -d'"' -f4)
JOIN_B=$(curl -s -X POST "$BASE/invite/$TOKEN2/join" -H "Content-Type: application/json" -d '{"displayName":"Oylayan B"}')
GUEST_B=$(echo "$JOIN_B" | grep -o '"guestSessionToken":"[^"]*"' | cut -d'"' -f4)

curl -s -X POST "$BASE/circles/$CIRCLE2_ID/photos" -H "Authorization: Bearer $GUEST_A" -F "files=@testdata/test1.jpg;type=image/jpeg" > /dev/null
curl -s -X POST "$BASE/circles/$CIRCLE2_ID/photos" -H "Authorization: Bearer $GUEST_B" -F "files=@testdata/test2.jpg;type=image/jpeg" > /dev/null

echo "=== 16. Request deletion -> pending, requires 2 approvals ==="
REQ=$(curl -s -X POST "$BASE/circles/$CIRCLE2_ID/deletion-request" -H "Authorization: Bearer $API_KEY")
echo "$REQ" | grep -o '"isPending":[a-z]*\|"eligibleVoterCount":[0-9]*\|"requiredApprovals":[0-9]*\|"currentApprovals":[0-9]*'

echo "=== 17. Guest A approves -> still pending, currentApprovals:1 ==="
VOTE_A=$(curl -s -X POST "$BASE/circles/$CIRCLE2_ID/deletion-request/vote" -H "Authorization: Bearer $GUEST_A" -H "Content-Type: application/json" -d '{"approve":true}')
echo "$VOTE_A" | grep -o '"isPending":[a-z]*\|"currentApprovals":[0-9]*\|"deleted":[a-z]*'

echo "=== 18. Guest B approves -> deleted ==="
VOTE_B=$(curl -s -X POST "$BASE/circles/$CIRCLE2_ID/deletion-request/vote" -H "Authorization: Bearer $GUEST_B" -H "Content-Type: application/json" -d '{"approve":true}')
echo "$VOTE_B" | grep -o '"deleted":[a-z]*'
CODE2=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/circles/$CIRCLE2_ID" -H "Authorization: Bearer $API_KEY")
echo "get after delete: $CODE2 (expected 404)"

echo "=== 19. Cancel-request path ==="
CIRCLE3=$(curl -s -X POST "$BASE/circles" -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" -d '{"name":"Iptal Testi","eventDate":null,"isOpenJoin":true}')
CIRCLE3_ID=$(echo "$CIRCLE3" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
INVITE3=$(curl -s -X POST "$BASE/circles/$CIRCLE3_ID/invite" -H "Authorization: Bearer $API_KEY")
TOKEN3=$(echo "$INVITE3" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
JOIN_C=$(curl -s -X POST "$BASE/invite/$TOKEN3/join" -H "Content-Type: application/json" -d '{"displayName":"Oylayan C"}')
GUEST_C=$(echo "$JOIN_C" | grep -o '"guestSessionToken":"[^"]*"' | cut -d'"' -f4)
curl -s -X POST "$BASE/circles/$CIRCLE3_ID/photos" -H "Authorization: Bearer $GUEST_C" -F "files=@testdata/test3.jpg;type=image/jpeg" > /dev/null
curl -s -X POST "$BASE/circles/$CIRCLE3_ID/deletion-request" -H "Authorization: Bearer $API_KEY" > /dev/null
curl -s -X DELETE "$BASE/circles/$CIRCLE3_ID/deletion-request" -H "Authorization: Bearer $API_KEY" -o /dev/null -w "cancel status: %{http_code}\n"
STATUS3=$(curl -s "$BASE/circles/$CIRCLE3_ID/deletion-request" -H "Authorization: Bearer $API_KEY")
echo "$STATUS3" | grep -o '"isPending":[a-z]*'
CODE3=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/circles/$CIRCLE3_ID" -H "Authorization: Bearer $API_KEY")
echo "circle still exists: $CODE3 (expected 200)"

echo "=== SMOKE TEST PASSED ==="
