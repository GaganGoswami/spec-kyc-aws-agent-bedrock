# WebSocket API Contract

**Feature**: 001-agentic-kyc-system  
**Version**: 1.0.0  
**Date**: 2025-11-12

## Overview

The WebSocket API provides real-time updates for long-running agent operations, case status changes, and document processing events. Clients connect to a persistent WebSocket connection and receive push notifications without polling.

## Connection

### Endpoint

```
wss://api.kyc-{env}.bank.com/ws
```

### Authentication

WebSocket connections require JWT authentication via query parameter:

```
wss://api.kyc-dev.bank.com/ws?token={access_token}
```

**Token**: Use the `access_token` obtained from `/auth/login` endpoint.

### Connection Lifecycle

1. **Connect**: Client initiates WebSocket connection with valid JWT token
2. **Subscribe**: Client sends subscription messages for specific channels
3. **Receive**: Server pushes events to client based on subscriptions
4. **Heartbeat**: Server sends ping frames every 30 seconds (client responds with pong)
5. **Disconnect**: Either party can close connection (automatic reconnect with exponential backoff)

### Connection Limits

- **Max connections per user**: 5
- **Idle timeout**: 5 minutes (without any messages)
- **Max connection duration**: 12 hours (forced reconnect)

---

## Message Format

All messages use JSON format with consistent structure:

### Client → Server (Subscription)

```json
{
  "type": "subscribe" | "unsubscribe",
  "channel": "case.{case_id}" | "document.{document_id}" | "agent.{session_id}" | "user.{user_id}",
  "message_id": "uuid"
}
```

### Server → Client (Event)

```json
{
  "type": "event",
  "channel": "case.{case_id}",
  "event_name": "case.status_changed",
  "payload": {
    // Event-specific data
  },
  "timestamp": "2025-11-12T10:00:00Z",
  "event_id": "uuid"
}
```

### Server → Client (Acknowledgment)

```json
{
  "type": "ack",
  "message_id": "uuid",
  "status": "success" | "error",
  "error_message": "Channel not found"
}
```

### Server → Client (Error)

```json
{
  "type": "error",
  "error_code": "AUTH_EXPIRED",
  "message": "JWT token expired, please reconnect with fresh token",
  "timestamp": "2025-11-12T10:00:00Z"
}
```

---

## Channels

### 1. Case Channel: `case.{case_id}`

Subscribe to all events for a specific case.

**Required Permission**: `cases:read` for the specified case

**Events**:

#### `case.status_changed`

Triggered when case status transitions.

```json
{
  "type": "event",
  "channel": "case.123e4567-e89b-12d3-a456-426614174000",
  "event_name": "case.status_changed",
  "payload": {
    "case_id": "123e4567-e89b-12d3-a456-426614174000",
    "case_number": "KYC-2025-001234",
    "old_status": "OPEN",
    "new_status": "UNDER_REVIEW",
    "changed_by": {
      "id": "user-uuid",
      "name": "John Doe",
      "role": "case_officer"
    },
    "reason": "All initial documents uploaded, ready for review"
  },
  "timestamp": "2025-11-12T10:00:00Z",
  "event_id": "event-uuid"
}
```

#### `case.document_uploaded`

Triggered when new document added to case.

```json
{
  "type": "event",
  "channel": "case.123e4567-e89b-12d3-a456-426614174000",
  "event_name": "case.document_uploaded",
  "payload": {
    "case_id": "123e4567-e89b-12d3-a456-426614174000",
    "document_id": "doc-uuid",
    "document_type": "passport",
    "file_name": "passport-john-doe.pdf",
    "file_size_bytes": 2457600,
    "uploaded_by": {
      "id": "user-uuid",
      "name": "John Doe"
    }
  },
  "timestamp": "2025-11-12T10:01:00Z",
  "event_id": "event-uuid"
}
```

#### `case.screening_completed`

Triggered when screening finishes.

```json
{
  "type": "event",
  "channel": "case.123e4567-e89b-12d3-a456-426614174000",
  "event_name": "case.screening_completed",
  "payload": {
    "case_id": "123e4567-e89b-12d3-a456-426614174000",
    "screening_id": "screening-uuid",
    "screening_type": "SANCTIONS",
    "match_status": "HIT",
    "match_count": 2,
    "requires_review": true
  },
  "timestamp": "2025-11-12T10:02:00Z",
  "event_id": "event-uuid"
}
```

#### `case.risk_computed`

Triggered when AI risk assessment completes.

```json
{
  "type": "event",
  "channel": "case.123e4567-e89b-12d3-a456-426614174000",
  "event_name": "case.risk_computed",
  "payload": {
    "case_id": "123e4567-e89b-12d3-a456-426614174000",
    "risk_assessment_id": "risk-uuid",
    "risk_score": 72,
    "risk_level": "HIGH",
    "top_risk_drivers": [
      {"factor": "PEP match", "weight": 0.35},
      {"factor": "High-risk jurisdiction", "weight": 0.25}
    ],
    "confidence_score": 0.87
  },
  "timestamp": "2025-11-12T10:03:00Z",
  "event_id": "event-uuid"
}
```

#### `case.sow_reviewed`

Triggered when source of wealth review completes.

```json
{
  "type": "event",
  "channel": "case.123e4567-e89b-12d3-a456-426614174000",
  "event_name": "case.sow_reviewed",
  "payload": {
    "case_id": "123e4567-e89b-12d3-a456-426614174000",
    "sow_review_id": "sow-uuid",
    "confidence_level": "MEDIUM",
    "requires_further_review": true,
    "identified_gaps": [
      "No tax returns provided for investment income",
      "Business sale agreement missing"
    ]
  },
  "timestamp": "2025-11-12T10:04:00Z",
  "event_id": "event-uuid"
}
```

#### `case.approved`

Triggered when case approved.

```json
{
  "type": "event",
  "channel": "case.123e4567-e89b-12d3-a456-426614174000",
  "event_name": "case.approved",
  "payload": {
    "case_id": "123e4567-e89b-12d3-a456-426614174000",
    "case_number": "KYC-2025-001234",
    "approved_by": {
      "id": "user-uuid",
      "name": "Jane Doe",
      "role": "senior_officer"
    },
    "snapshot_id": "snapshot-uuid",
    "approval_timestamp": "2025-11-12T10:05:00Z"
  },
  "timestamp": "2025-11-12T10:05:00Z",
  "event_id": "event-uuid"
}
```

#### `case.rejected`

Triggered when case rejected.

```json
{
  "type": "event",
  "channel": "case.123e4567-e89b-12d3-a456-426614174000",
  "event_name": "case.rejected",
  "payload": {
    "case_id": "123e4567-e89b-12d3-a456-426614174000",
    "case_number": "KYC-2025-001234",
    "rejected_by": {
      "id": "user-uuid",
      "name": "Jane Doe",
      "role": "senior_officer"
    },
    "rejection_reasons": ["SCREENING_HIT", "HIGH_RISK"],
    "snapshot_id": "snapshot-uuid",
    "rejection_timestamp": "2025-11-12T10:05:00Z"
  },
  "timestamp": "2025-11-12T10:05:00Z",
  "event_id": "event-uuid"
}
```

---

### 2. Document Channel: `document.{document_id}`

Subscribe to processing updates for a specific document.

**Required Permission**: `documents:read` for the case containing this document

**Events**:

#### `document.processing_started`

Triggered when OCR/extraction begins.

```json
{
  "type": "event",
  "channel": "document.doc-uuid",
  "event_name": "document.processing_started",
  "payload": {
    "document_id": "doc-uuid",
    "case_id": "case-uuid",
    "processing_type": "ocr_extraction"
  },
  "timestamp": "2025-11-12T10:01:05Z",
  "event_id": "event-uuid"
}
```

#### `document.processing_progress`

Triggered periodically during long processing jobs.

```json
{
  "type": "event",
  "channel": "document.doc-uuid",
  "event_name": "document.processing_progress",
  "payload": {
    "document_id": "doc-uuid",
    "case_id": "case-uuid",
    "progress_percentage": 45,
    "current_step": "Extracting text from page 9/20"
  },
  "timestamp": "2025-11-12T10:01:30Z",
  "event_id": "event-uuid"
}
```

#### `document.processing_completed`

Triggered when processing finishes successfully.

```json
{
  "type": "event",
  "channel": "document.doc-uuid",
  "event_name": "document.processing_completed",
  "payload": {
    "document_id": "doc-uuid",
    "case_id": "case-uuid",
    "extraction_confidence": 0.92,
    "extracted_entities": {
      "name": "John Doe",
      "dob": "1980-01-15",
      "passport_number": "P123456"
    },
    "processing_duration_ms": 12345
  },
  "timestamp": "2025-11-12T10:02:00Z",
  "event_id": "event-uuid"
}
```

#### `document.processing_failed`

Triggered when processing encounters error.

```json
{
  "type": "event",
  "channel": "document.doc-uuid",
  "event_name": "document.processing_failed",
  "payload": {
    "document_id": "doc-uuid",
    "case_id": "case-uuid",
    "error_code": "UNSUPPORTED_FORMAT",
    "error_message": "Document format not supported for OCR",
    "retry_allowed": false
  },
  "timestamp": "2025-11-12T10:02:00Z",
  "event_id": "event-uuid"
}
```

---

### 3. Agent Channel: `agent.{session_id}`

Subscribe to updates from a long-running agent session.

**Required Permission**: `cases:read` for the case associated with this session

**Events**:

#### `agent.step_started`

Triggered when agent starts a new step in workflow.

```json
{
  "type": "event",
  "channel": "agent.session-uuid",
  "event_name": "agent.step_started",
  "payload": {
    "session_id": "session-uuid",
    "case_id": "case-uuid",
    "agent_type": "entity_resolution",
    "current_step": "fetch_corporate_registry",
    "step_number": 3,
    "total_steps": 5,
    "step_description": "Fetching corporate registry data for ABC Corp"
  },
  "timestamp": "2025-11-12T10:03:00Z",
  "event_id": "event-uuid"
}
```

#### `agent.step_completed`

Triggered when agent completes a step.

```json
{
  "type": "event",
  "channel": "agent.session-uuid",
  "event_name": "agent.step_completed",
  "payload": {
    "session_id": "session-uuid",
    "case_id": "case-uuid",
    "agent_type": "entity_resolution",
    "step_name": "fetch_corporate_registry",
    "step_number": 3,
    "result_summary": "Found 2 beneficial owners with >25% ownership",
    "execution_duration_ms": 3456
  },
  "timestamp": "2025-11-12T10:03:15Z",
  "event_id": "event-uuid"
}
```

#### `agent.session_completed`

Triggered when entire agent session finishes.

```json
{
  "type": "event",
  "channel": "agent.session-uuid",
  "event_name": "agent.session_completed",
  "payload": {
    "session_id": "session-uuid",
    "case_id": "case-uuid",
    "agent_type": "entity_resolution",
    "status": "SUCCESS",
    "total_duration_ms": 15678,
    "result_summary": "Identified 3 beneficial owners and 5 entity relationships"
  },
  "timestamp": "2025-11-12T10:04:00Z",
  "event_id": "event-uuid"
}
```

#### `agent.session_failed`

Triggered when agent session encounters error.

```json
{
  "type": "event",
  "channel": "agent.session-uuid",
  "event_name": "agent.session_failed",
  "payload": {
    "session_id": "session-uuid",
    "case_id": "case-uuid",
    "agent_type": "entity_resolution",
    "error_code": "EXTERNAL_API_TIMEOUT",
    "error_message": "Corporate registry API timeout after 3 retries",
    "retry_count": 3,
    "will_retry": false
  },
  "timestamp": "2025-11-12T10:04:00Z",
  "event_id": "event-uuid"
}
```

---

### 4. User Channel: `user.{user_id}`

Subscribe to notifications for the current user (assignments, mentions, tasks).

**Required Permission**: Only the authenticated user can subscribe to their own channel

**Events**:

#### `user.case_assigned`

Triggered when case assigned to user.

```json
{
  "type": "event",
  "channel": "user.user-uuid",
  "event_name": "user.case_assigned",
  "payload": {
    "user_id": "user-uuid",
    "case_id": "case-uuid",
    "case_number": "KYC-2025-001234",
    "client_name": "John Doe",
    "assigned_by": {
      "id": "manager-uuid",
      "name": "Manager Name"
    },
    "due_date": "2025-11-19",
    "priority": "HIGH"
  },
  "timestamp": "2025-11-12T10:00:00Z",
  "event_id": "event-uuid"
}
```

#### `user.review_requested`

Triggered when case assigned for review.

```json
{
  "type": "event",
  "channel": "user.user-uuid",
  "event_name": "user.review_requested",
  "payload": {
    "user_id": "user-uuid",
    "case_id": "case-uuid",
    "case_number": "KYC-2025-001234",
    "client_name": "John Doe",
    "requested_by": {
      "id": "officer-uuid",
      "name": "Case Officer Name"
    },
    "review_type": "APPROVAL",
    "due_date": "2025-11-13"
  },
  "timestamp": "2025-11-12T10:00:00Z",
  "event_id": "event-uuid"
}
```

#### `user.notification`

Generic notification for user actions.

```json
{
  "type": "event",
  "channel": "user.user-uuid",
  "event_name": "user.notification",
  "payload": {
    "user_id": "user-uuid",
    "notification_type": "SCREENING_REVIEW_REQUIRED",
    "title": "Screening match requires review",
    "message": "Case KYC-2025-001234 has a sanctions hit that needs your review",
    "action_url": "/cases/case-uuid",
    "priority": "HIGH"
  },
  "timestamp": "2025-11-12T10:00:00Z",
  "event_id": "event-uuid"
}
```

---

## Client Implementation Examples

### JavaScript (Browser)

```javascript
class KYCWebSocketClient {
  constructor(accessToken) {
    this.ws = null;
    this.accessToken = accessToken;
    this.eventHandlers = new Map();
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 10;
  }

  connect() {
    const wsUrl = `wss://api.kyc-dev.bank.com/ws?token=${this.accessToken}`;
    this.ws = new WebSocket(wsUrl);

    this.ws.onopen = () => {
      console.log('WebSocket connected');
      this.reconnectAttempts = 0;
    };

    this.ws.onmessage = (event) => {
      const message = JSON.parse(event.data);
      this.handleMessage(message);
    };

    this.ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    this.ws.onclose = (event) => {
      console.log('WebSocket closed:', event.code, event.reason);
      this.reconnect();
    };
  }

  reconnect() {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.error('Max reconnect attempts reached');
      return;
    }

    const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 30000);
    this.reconnectAttempts++;

    console.log(`Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`);
    setTimeout(() => this.connect(), delay);
  }

  subscribe(channel) {
    const message = {
      type: 'subscribe',
      channel: channel,
      message_id: crypto.randomUUID()
    };
    this.ws.send(JSON.stringify(message));
  }

  unsubscribe(channel) {
    const message = {
      type: 'unsubscribe',
      channel: channel,
      message_id: crypto.randomUUID()
    };
    this.ws.send(JSON.stringify(message));
  }

  on(eventName, handler) {
    if (!this.eventHandlers.has(eventName)) {
      this.eventHandlers.set(eventName, []);
    }
    this.eventHandlers.get(eventName).push(handler);
  }

  handleMessage(message) {
    if (message.type === 'event') {
      const handlers = this.eventHandlers.get(message.event_name) || [];
      handlers.forEach(handler => handler(message.payload));
    } else if (message.type === 'ack') {
      console.log('Subscription acknowledged:', message);
    } else if (message.type === 'error') {
      console.error('WebSocket error:', message);
    }
  }

  disconnect() {
    if (this.ws) {
      this.ws.close();
    }
  }
}

// Usage example
const client = new KYCWebSocketClient(accessToken);
client.connect();

// Subscribe to case updates
client.subscribe('case.123e4567-e89b-12d3-a456-426614174000');

// Listen for specific events
client.on('case.status_changed', (payload) => {
  console.log('Case status changed:', payload);
  updateUI(payload);
});

client.on('case.risk_computed', (payload) => {
  console.log('Risk computed:', payload);
  displayRiskScore(payload.risk_score, payload.risk_level);
});

client.on('document.processing_completed', (payload) => {
  console.log('Document processed:', payload);
  refreshDocumentList();
});
```

### Python (Backend Service)

```python
import asyncio
import websockets
import json
from typing import Callable, Dict

class KYCWebSocketClient:
    def __init__(self, access_token: str):
        self.access_token = access_token
        self.ws = None
        self.event_handlers: Dict[str, list[Callable]] = {}
        self.reconnect_attempts = 0
        self.max_reconnect_attempts = 10

    async def connect(self):
        ws_url = f"wss://api.kyc-dev.bank.com/ws?token={self.access_token}"
        try:
            async with websockets.connect(ws_url) as websocket:
                self.ws = websocket
                self.reconnect_attempts = 0
                print("WebSocket connected")
                
                await self.listen()
        except Exception as e:
            print(f"Connection error: {e}")
            await self.reconnect()

    async def reconnect(self):
        if self.reconnect_attempts >= self.max_reconnect_attempts:
            print("Max reconnect attempts reached")
            return

        delay = min(2 ** self.reconnect_attempts, 30)
        self.reconnect_attempts += 1
        print(f"Reconnecting in {delay}s (attempt {self.reconnect_attempts})")
        
        await asyncio.sleep(delay)
        await self.connect()

    async def listen(self):
        try:
            async for message in self.ws:
                data = json.loads(message)
                await self.handle_message(data)
        except websockets.ConnectionClosed:
            print("Connection closed")
            await self.reconnect()

    async def subscribe(self, channel: str):
        message = {
            "type": "subscribe",
            "channel": channel,
            "message_id": str(uuid.uuid4())
        }
        await self.ws.send(json.dumps(message))

    async def handle_message(self, message: dict):
        if message["type"] == "event":
            event_name = message["event_name"]
            handlers = self.event_handlers.get(event_name, [])
            for handler in handlers:
                await handler(message["payload"])

    def on(self, event_name: str, handler: Callable):
        if event_name not in self.event_handlers:
            self.event_handlers[event_name] = []
        self.event_handlers[event_name].append(handler)

# Usage example
async def main():
    client = KYCWebSocketClient(access_token)
    
    async def on_status_change(payload):
        print(f"Case {payload['case_number']} status: {payload['new_status']}")
    
    client.on("case.status_changed", on_status_change)
    
    await client.connect()
    await client.subscribe("case.123e4567-e89b-12d3-a456-426614174000")
    
    await asyncio.Future()  # Run forever

asyncio.run(main())
```

---

## Error Codes

| Code | Description | Action |
|------|-------------|--------|
| `AUTH_REQUIRED` | No authentication token provided | Reconnect with `?token={jwt}` |
| `AUTH_INVALID` | Invalid JWT token | Obtain new token via `/auth/login` |
| `AUTH_EXPIRED` | JWT token expired | Refresh token via `/auth/refresh`, then reconnect |
| `CHANNEL_NOT_FOUND` | Requested channel does not exist | Verify channel name format |
| `PERMISSION_DENIED` | Insufficient permissions for channel | Check user role permissions |
| `RATE_LIMIT_EXCEEDED` | Too many messages sent | Wait 60 seconds before retry |
| `MAX_CONNECTIONS_EXCEEDED` | User has >5 active connections | Close existing connections |
| `SERVER_ERROR` | Internal server error | Retry with exponential backoff |

---

## Best Practices

### Connection Management

1. **Exponential Backoff**: Reconnect with increasing delays (1s, 2s, 4s, 8s, ..., max 30s)
2. **Max Attempts**: Limit reconnection attempts to prevent infinite loops
3. **Heartbeat**: Respond to server ping frames to keep connection alive
4. **Clean Disconnect**: Call `close()` before page unload to avoid lingering connections

### Subscription Management

1. **Subscribe Early**: Subscribe to channels immediately after connection
2. **Resubscribe on Reconnect**: Reestablish subscriptions after reconnection
3. **Unsubscribe**: Remove subscriptions when leaving views to reduce server load
4. **Limit Subscriptions**: Subscribe only to active/visible resources (max ~20 per connection)

### Event Handling

1. **Idempotency**: Handle duplicate events gracefully (same `event_id` may arrive twice)
2. **Ordering**: Events may arrive out-of-order; use `timestamp` for sequencing
3. **Buffering**: Buffer events during reconnection, apply after catching up
4. **Error Recovery**: Fetch current state via REST API after reconnection to sync

### Security

1. **Token Rotation**: Reconnect with fresh token before expiry (55 minutes for 1-hour token)
2. **TLS Only**: Always use `wss://` (never `ws://`)
3. **Validate Payload**: Sanitize event payloads before rendering in UI
4. **Rate Limiting**: Respect rate limits to avoid disconnection

---

## Testing

### Manual Testing (wscat)

```bash
# Install wscat
npm install -g wscat

# Connect with authentication
wscat -c "wss://api.kyc-dev.bank.com/ws?token=eyJhbGci..."

# Subscribe to case channel
> {"type":"subscribe","channel":"case.123e4567-e89b-12d3-a456-426614174000","message_id":"test-1"}

# Wait for events
< {"type":"event","channel":"case.123e4567...","event_name":"case.status_changed",...}
```

### Automated Testing

Use Playwright or Selenium with WebSocket support:

```python
import pytest
from playwright.async_api import async_playwright

@pytest.mark.asyncio
async def test_websocket_case_events():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page()
        
        # Listen for WebSocket messages
        messages = []
        page.on("websocket", lambda ws: ws.on("framereceived", lambda frame: messages.append(frame)))
        
        # Connect to WebSocket
        await page.goto("https://app.kyc-dev.bank.com/cases/123")
        
        # Trigger case status change via REST API
        await trigger_status_change()
        
        # Wait for WebSocket event
        await page.wait_for_timeout(2000)
        
        # Assert event received
        assert any("case.status_changed" in str(m) for m in messages)
        
        await browser.close()
```

---

## Monitoring & Observability

### Metrics

- **Active Connections**: Gauge of current WebSocket connections
- **Messages Sent**: Counter of events pushed to clients
- **Subscription Count**: Gauge of active subscriptions per channel
- **Connection Duration**: Histogram of connection lifetimes
- **Message Latency**: Time from event occurrence to client delivery
- **Error Rate**: Counter of connection errors by type

### Logging

All WebSocket events logged with structured format:

```json
{
  "timestamp": "2025-11-12T10:00:00Z",
  "level": "INFO",
  "event_type": "websocket.connection_established",
  "user_id": "user-uuid",
  "connection_id": "conn-uuid",
  "ip_address": "192.168.1.100",
  "user_agent": "Mozilla/5.0..."
}
```

### Tracing

WebSocket events correlated with REST API calls via `trace_id`:

```json
{
  "trace_id": "trace-uuid",
  "span_id": "span-uuid",
  "parent_span_id": "parent-span-uuid",
  "operation": "websocket.event_push",
  "duration_ms": 12
}
```

---

## Summary

The WebSocket API provides:

- **Real-time updates** for case workflows, document processing, agent sessions
- **Low latency** push notifications (<100ms from event occurrence)
- **Scalability** via API Gateway WebSocket connections (10,000+ concurrent)
- **Reliability** with automatic reconnection and exponential backoff
- **Security** via JWT authentication and channel-level permissions

**Next Steps**: Create quickstart.md with local development setup.
