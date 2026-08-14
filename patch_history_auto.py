import json
import os

history_path = os.path.expanduser("~/Library/Application Support/SpeedTestBar/history.json")

with open(history_path, 'r') as f:
    data = json.load(f)

data.sort(key=lambda x: x['timestamp'])

# Find all items missing latitude
for i, entry in enumerate(data):
    if entry.get('latitude') is None:
        # Find nearest valid before
        before = None
        for j in range(i-1, -1, -1):
            if data[j].get('latitude') is not None:
                before = data[j]
                break
        
        # Find nearest valid after
        after = None
        for j in range(i+1, len(data)):
            if data[j].get('latitude') is not None:
                after = data[j]
                break
                
        if before and after:
            avg_lat = (before['latitude'] + after['latitude']) / 2.0
            avg_lng = (before['longitude'] + after['longitude']) / 2.0
            entry['latitude'] = avg_lat
            entry['longitude'] = avg_lng
            print(f"Patched {entry['timestamp']} using interpolation.")
        elif before:
            entry['latitude'] = before['latitude']
            entry['longitude'] = before['longitude']
            print(f"Patched {entry['timestamp']} using previous location.")
        elif after:
            entry['latitude'] = after['latitude']
            entry['longitude'] = after['longitude']
            print(f"Patched {entry['timestamp']} using next location.")

data.sort(key=lambda x: x['timestamp'], reverse=True)

with open(history_path, 'w') as f:
    json.dump(data, f, indent=2)

print("Done patching.")
