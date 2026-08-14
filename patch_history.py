import json
import os
import datetime

history_path = os.path.expanduser("~/Library/Application Support/SpeedTestBar/history.json")

with open(history_path, 'r') as f:
    data = json.load(f)

# Sort data by timestamp ascending to easily find neighbors
data.sort(key=lambda x: x['timestamp'])

apple_store_lat = 37.78855
apple_store_lng = -122.40721

for i, entry in enumerate(data):
    ts = entry['timestamp'] # e.g. "2026-08-14T01:20:00Z" which is 6:20 PM PDT on Aug 13
    
    # We are looking for Aug 13th PDT, which is Aug 14th UTC
    if "2026-08-14T01:20:" <= ts <= "2026-08-14T01:54:": 
        # 6:20 PM to 6:54 PM PDT
        entry['latitude'] = apple_store_lat
        entry['longitude'] = apple_store_lng
        print(f"Patched {ts} with Apple Store coords")
        
    elif "2026-08-14T02:12:" in ts:
        # 7:12 PM PDT
        # Average with immediate neighbors
        if i > 0 and i < len(data) - 1:
            prev_entry = data[i-1]
            next_entry = data[i+1]
            if 'latitude' in prev_entry and 'latitude' in next_entry:
                avg_lat = (prev_entry['latitude'] + next_entry['latitude']) / 2.0
                avg_lng = (prev_entry['longitude'] + next_entry['longitude']) / 2.0
                entry['latitude'] = avg_lat
                entry['longitude'] = avg_lng
                print(f"Patched {ts} with average coords: {avg_lat}, {avg_lng}")
            else:
                print(f"Could not average for {ts}: neighbors missing location")

# Sort back to descending (newest first) as the app expects
data.sort(key=lambda x: x['timestamp'], reverse=True)

with open(history_path, 'w') as f:
    json.dump(data, f, indent=2)

print("Done updating history.json")
