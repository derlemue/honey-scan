#### Attack List

This page allows you to view, aggregate, search, analyze, and export attack data captured by HFish.

![attack_list](images/20210730142413.png)

**Aggregation:**
HFish automatically aggregates repeated attacks from the same source IP against the same honeypot within a short period to reduce noise.

**Displayed Data:**
1. **Target Honeypot**: Which service was attacked.
2. **Count**: Number of attacks in this event.
3. **Target Node**: Which node received the attack.
4. **Source IP & Location**: Attacker's IP and Geo-location.
5. **Threat Intelligence**: Tags (if any) from threat intel sources.
6. **Last Attack Time**: Timestamp of the most recent activity in this event.
7. **Start Time**: Timestamp of the first activity in this event.
8. **Data Length**: Size of the payload.
9. **Details**: Full packet content or interaction logs.

**Features:**
- **Search**: Filter by IP, Scenario, Honeypot Type, Node, Time, Geography, Tags, etc.
- **Sort**: By Time or Count.
- **Export**: Export all data or specific events to CSV.
