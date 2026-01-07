#### API Configuration

Manage your API Key and view code samples for 7 programming languages.
Supported Actions:
1. **Get Attack Sources**
2. **Get Attack Details**
3. **Get Compromised Credentials (Brute-force)**

![api_page](images/20210730173725.png)

### API Usage Examples

#### 1. Get Attack Sources

**Endpoint**: `POST https://[Server_IP]/api/v1/attack/ip?api_key=[YOUR_KEY]`

**Payload**:
```json
{
  "start_time": 0,
  "end_time": 0,
  "intranet": 0,
  "threat_label": ["Scanner"]
}
```

**cURL Example**:
```bash
curl --location --request POST 'https://Server_IP/api/v1/attack/ip?api_key=YOUR_API_KEY' \
--header 'Content-Type: application/json' \
--data '{
  "start_time": 0,
  "end_time": 0,
  "intranet": 0,
  "threat_label": ["Scanner"]
}'
```

#### 2. Get Attack Details

**Endpoint**: `POST https://[Server_IP]/api/v1/attack/detail?api_key=[YOUR_KEY]`
*(Note: Endpoint path might vary, check UI for exact path. Based on context usually `.../attack/detail` or similar)*

**Payload**:
```json
{
  "start_time": 0,
  "end_time": 0,
  "page_no": 1,
  "page_size": 100,
  "threat_label": ["Scanner"],
  "client_id": [],
  "service_name": [],
  "info_confirm": "1"
}
```

#### 3. Get Compromised Credentials

**Endpoint**: `POST https://[Server_IP]/api/v1/attack/account?api_key=[YOUR_KEY]`

**Payload**:
```json
{
  "start_time": 0,
  "end_time": 0,
  "attack_ip": []
}
```

*Refer to the UI for Python, Go, Java, JS, PHP, and Shell code samples.*
