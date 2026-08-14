import json
import os
from datetime import datetime

history_path = os.path.expanduser("~/Library/Application Support/SpeedTest/history.json")

with open(history_path, 'r') as f:
    data = json.load(f)

# The time window to delete is 2026-08-14 11:40 AM to 1:06 PM PDT
# which corresponds to 18:40:00Z to 20:06:59Z
start_str = "2026-08-14T18:40:00Z"
end_str = "2026-08-14T20:06:59Z"

original_len = len(data)

filtered_data = [
    item for item in data
    if not (start_str <= item["timestamp"] <= end_str)
]

with open(history_path, 'w') as f:
    json.dump(filtered_data, f, indent=2)

print(f"Deleted {original_len - len(filtered_data)} records between 11:40 AM and 1:06 PM.")
