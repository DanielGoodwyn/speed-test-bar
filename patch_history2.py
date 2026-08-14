import json
import os

history_path = os.path.expanduser("~/Library/Application Support/SpeedTestBar/history.json")

with open(history_path, 'r') as f:
    data = json.load(f)

apple_store_lat = 37.78855
apple_store_lng = -122.40721

for entry in data:
    ts = entry['timestamp']
    # 6:54 PM PDT is 01:54 UTC
    if "2026-08-14T01:54:" in ts:
        entry['latitude'] = apple_store_lat
        entry['longitude'] = apple_store_lng
        print(f"Patched {ts} with Apple Store coords")

with open(history_path, 'w') as f:
    json.dump(data, f, indent=2)

print("Done updating history.json")
