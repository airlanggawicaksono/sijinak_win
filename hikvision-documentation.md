
**Auth is HTTP Digest**. 

```bash
IP="192.168.40.181"
U="admin"
P="AyamBebek99" # Real pw
BASE="http://$IP"
AUTH=(--digest -u "$U:$P")
JH=(-H "Content-Type: application/json")
```
`
## 1) Device info

Endpoint example shown in the guide. 

```bash
curl "${AUTH[@]}" "$BASE/ISAPI/System/deviceInfo"
```

## 2) Access control capabilities

Used to check what the device supports. 

```bash
curl "${AUTH[@]}" "$BASE/ISAPI/AccessControl/capabilities"
```

## 3) Event logs (RFID taps, face, etc)

### 3.1 Event search capability 

```bash
curl "${AUTH[@]}" "$BASE/ISAPI/AccessControl/AcsEvent/capabilities?format=json"
```

### 3.2 Search events (paged) 

```bash
curl "${AUTH[@]}" "${JH[@]}" \
"$BASE/ISAPI/AccessControl/AcsEvent?format=json" \
-d '{
  "AcsEventCond": {
    "searchID": "1",
    "searchResultPosition": 0,
    "maxResults": 10,
    "major": 5,
    "minor": 0
  }
}'
```

### 3.3 Search only new events by serial number 

```bash
LAST=1000
curl "${AUTH[@]}" "${JH[@]}" \
"$BASE/ISAPI/AccessControl/AcsEvent?format=json" \
-d "{
  \"AcsEventCond\": {
    \"searchID\": \"poll\",
    \"searchResultPosition\": 0,
    \"maxResults\": 30,
    \"major\": 5,
    \"minor\": 0,
    \"beginSerialNo\": $((LAST+1))
  }
}"
```

### 3.4 Event total count by filter 

Capability

```bash
curl "${AUTH[@]}" "$BASE/ISAPI/AccessControl/AcsEventTotalNum/capabilities?format=json"
```

Count

```bash
curl "${AUTH[@]}" "${JH[@]}" \
"$BASE/ISAPI/AccessControl/AcsEventTotalNum?format=json" \
-d '{
  "AcsEventTotalNumCond": {
    "major": 5,
    "minor": 0,
    "beginSerialNo": 1,
    "endSerialNo": 100
  }
}'
```

Fields like `beginSerialNo`, `endSerialNo`, `employeeNoString` exist in the spec. 

### 3.5 Download the event picture

Your event JSON returns `pictureURL`. Just GET it with digest

```bash
PIC_URL="http://192.168.40.181/LOCALS/pic/acsLinkCap/....jpeg@WEB000000000001"
curl "${AUTH[@]}" -o event.jpg "$PIC_URL"
```

## 4) Person (student) management

Support and flows are listed here.  

Capabilities

```bash
curl "${AUTH[@]}" "$BASE/ISAPI/AccessControl/UserInfo/capabilities?format=json"
```

Count

```bash
curl "${AUTH[@]}" "$BASE/ISAPI/AccessControl/UserInfo/Count?format=json"
```

Search (paged)

```bash
curl "${AUTH[@]}" "${JH[@]}" \
"$BASE/ISAPI/AccessControl/UserInfo/Search?format=json" \
-d '{
  "UserInfoSearchCond": {
    "searchID": "u1",
    "searchResultPosition": 0,
    "maxResults": 50
  }
}'
```

Apply (upsert)

```bash
curl "${AUTH[@]}" "${JH[@]}" \
-X PUT "$BASE/ISAPI/AccessControl/UserInfo/SetUp?format=json" \
-d '{
  "UserInfo": {
    "employeeNo": "S001",
    "name": "Student Name"
  }
}'
```

Add (must not exist)

```bash
curl "${AUTH[@]}" "${JH[@]}" \
"$BASE/ISAPI/AccessControl/UserInfo/Record?format=json" \
-d '{
  "UserInfo": {
    "employeeNo": "S001",
    "name": "Student Name"
  }
}'
```

Modify (must exist)

```bash
curl "${AUTH[@]}" "${JH[@]}" \
-X PUT "$BASE/ISAPI/AccessControl/UserInfo/Modify?format=json" \
-d '{
  "UserInfo": {
    "employeeNo": "S001",
    "name": "New Name"
  }
}'
```

## 5) Card (RFID) management

Card flows and endpoints are listed here.   

Capabilities

```bash
curl "${AUTH[@]}" "$BASE/ISAPI/AccessControl/CardInfo/capabilities?format=json"
```

Count all cards or per person 

```bash
curl "${AUTH[@]}" "$BASE/ISAPI/AccessControl/CardInfo/Count?format=json"
curl "${AUTH[@]}" "$BASE/ISAPI/AccessControl/CardInfo/Count?format=json&employeeNo=S001"
```

Search (paged) 

```bash
curl "${AUTH[@]}" "${JH[@]}" \
"$BASE/ISAPI/AccessControl/CardInfo/Search?format=json" \
-d '{
  "CardInfoSearchCond": {
    "searchID": "c1",
    "searchResultPosition": 0,
    "maxResults": 50
  }
}'
```

Apply card (upsert) 

```bash
curl "${AUTH[@]}" "${JH[@]}" \
-X PUT "$BASE/ISAPI/AccessControl/CardInfo/SetUp?format=json" \
-d '{
  "CardInfo": {
    "cardNo": "12345678",
    "employeeNo": "S001"
  }
}'
```

Add card (must not exist) 

```bash
curl "${AUTH[@]}" "${JH[@]}" \
"$BASE/ISAPI/AccessControl/CardInfo/Record?format=json" \
-d '{
  "CardInfo": {
    "cardNo": "12345678",
    "employeeNo": "S001"
  }
}'
```

Modify card 

```bash
curl "${AUTH[@]}" "${JH[@]}" \
-X PUT "$BASE/ISAPI/AccessControl/CardInfo/Modify?format=json" \
-d '{
  "CardInfo": {
    "cardNo": "12345678",
    "employeeNo": "S002"
  }
}'
```

Delete card 

```bash
curl "${AUTH[@]}" "${JH[@]}" \
-X PUT "$BASE/ISAPI/AccessControl/CardInfo/Delete?format=json" \
-d '{
  "CardInfoDelCond": {
    "cardNoList": [
      { "cardNo": "12345678" }
    ]
  }
}'
```

Card number length rules 

```bash
curl "${AUTH[@]}" "$BASE/ISAPI/AccessControl/CardVerificationRule?format=json"
curl "${AUTH[@]}" -X PUT "$BASE/ISAPI/AccessControl/CardVerificationRule?format=json" -d '...'
```


The device can **push alarm or event data to your PC** after you configure an HTTP listening server. 

---

## 6) Real time push (webhook style) using HTTP listening server

Flow from Hikvision side is

1. Optional check capability of HTTP listening server
2. Configure HTTP listening server by PUT
3. Test by POST to `/httpHosts/<ID>/test`
4. Device will POST events to `http://ipAddress:portNo/url` 

### 6.1 Capability

```bash
curl "${AUTH[@]}" "$BASE/ISAPI/Event/notification/httpHosts/capabilities"
```

### 6.2 List current listening servers

Use this first so you know which IDs exist. 

```bash
curl "${AUTH[@]}" "$BASE/ISAPI/Event/notification/httpHosts"
```

### 6.3 Set listening servers (recommended, deterministic)

This uses the official **HttpHostNotificationList** message format. It includes required fields like `url`, `protocolType`, `parameterFormatType`, `ipAddress`, `portNo`, auth method, and also event filtering using `eventMode` and `EventList`. 

Example: configure host ID 1 to send only `AccessControllerEvent` to your PC.

```bash
PC_IP="192.168.40.10"
PC_PORT="9091"
PC_PATH="/hik/events"

curl "${AUTH[@]}" -H "Content-Type: application/xml" \
-X PUT "$BASE/ISAPI/Event/notification/httpHosts" \
-d "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<HttpHostNotificationList version=\"2.0\" xmlns=\"http://www.isapi.org/ver20/XMLSchema\">
  <HttpHostNotification>
    <id>1</id>
    <url>${PC_PATH}</url>
    <protocolType>HTTP</protocolType>
    <parameterFormatType>XML</parameterFormatType>
    <addressingFormatType>ipaddress</addressingFormatType>
    <ipAddress>${PC_IP}</ipAddress>
    <portNo>${PC_PORT}</portNo>
    <httpAuthenticationMethod>none</httpAuthenticationMethod>

    <eventMode>list</eventMode>
    <EventList>
      <Event>
        <type>AccessControllerEvent</type>
      </Event>
    </EventList>

    <channels>1</channels>
  </HttpHostNotification>
</HttpHostNotificationList>"
```

Notes

* `eventMode=list` + `EventList` means only selected event types are pushed. 
* If you need more filtering for access control, the subscription model allows `minorAlarm`, `minorEvent`, etc for `AccessControllerEvent`. 
* Your PC must have an HTTP endpoint that accepts POST on `${PC_PATH}` and returns HTTP 200 fast.

### 6.4 Test that Hikvision can reach your PC

There is a built in test endpoint. 

```bash
curl "${AUTH[@]}" -H "Content-Type: application/xml" \
-X POST "$BASE/ISAPI/Event/notification/httpHosts/1/test" \
-d "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<HttpHostNotification version=\"2.0\" xmlns=\"http://www.isapi.org/ver20/XMLSchema\">
  <id>1</id>
</HttpHostNotification>"
```

### 6.5 Delete all listening servers (reset)

```bash
curl "${AUTH[@]}" -X DELETE "$BASE/ISAPI/Event/notification/httpHosts"
```

The API supports DELETE for all listening servers. 

---

## 6.6 What your PC will receive (important)

The device POST payload can be

* `multipart/form-data` with parts like `Event_Type` and `Picture_Name` and may include a binary image
* or plain `text/xml`
* sometimes `text/json` 

So your desktop wrapper should handle both cases.

---

## 6.7 Alternative real time method (pull, not webhook)

If you prefer your PC to connect and keep a stream open, use `alertStream`. After calling it, the connection stays open and events keep coming. 

```bash
curl -N "${AUTH[@]}" "$BASE/ISAPI/Event/notification/alertStream"
```

---

## 7) Formal business process (your attendance app)

### 7.1 Inputs you store

Minimum fields you requested

* `rfid_card` from event (cardNo)
* `student_id` in the db.. assoicated from the rfid_card
* `device_time` from event
* `type` enum {izin, absen}
* `why` nullable text
* `return_time` nullable timestamp

### 7.2 Recommended internal states

This keeps it reliable even if internet is down

1. `tap_received`
2. `pending_choice` (popup shown)
3. `chosen` (izin or absen picked)
4. `printed` (only for izin, 3 copies)
5. `published` (sent to server, confirmed)

### 7.3 Suggested DB record shape (single table)

Use one row per tap.

* `id` uuid
* `device_id` string (example: `school-gate-01`)
* `card_no` string
* `device_time` timestamptz
* `decision` enum
* `reason` text null
* `return_time` timestamptz null
* `created_at` timestamptz
* `published_at` timestamptz null

Recommended uniqueness to avoid duplicates

* unique `(device_id, card_no, device_time)`

### 7.4 Tap in and tap out

If you have only one reader, the device usually just reports one access event. “In vs out” is normally a software rule, unless you install two readers or use different channels. The listening config supports `channels` if the device exposes them. 
