import json
import os

history_path = os.path.expanduser("~/Library/Application Support/SpeedTestBar/history.json")

with open(history_path, 'r') as f:
    data = json.load(f)

# Sort ascending so [i-1] is previous test, [i+1] is next test
data.sort(key=lambda x: x['timestamp'])

for i, entry in enumerate(data):
    ts = entry['timestamp']
    # 9:15 PM PDT is 04:15 UTC
    if "2026-08-14T04:15:" in ts:
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

# Sort back to descending (newest first)
data.sort(key=lambda x: x['timestamp'], reverse=True)

with open(history_path, 'w') as f:
    json.dump(data, f, indent=2)

print("Done updating history.json")
