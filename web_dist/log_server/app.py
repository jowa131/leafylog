"""
leafylog 에러 로그 수집 서버.

POST /api/log 로 수신한 JSON(message, stackTrace, deviceInfo)을
/data/crashes.log 파일에 한 줄씩 append한다.
"""

import json
import os
from datetime import datetime, timezone

from flask import Flask, request, jsonify

app = Flask(__name__)

LOG_PATH = os.environ.get("LOG_PATH", "/data/crashes.log")


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


@app.route("/api/log", methods=["POST"])
def receive_log():
    payload = request.get_json(silent=True)
    if not payload:
        return jsonify({"error": "JSON 본문이 필요하다."}), 400

    record = {
        "received_at": _now_iso(),
        "message": payload.get("message", ""),
        "stack_trace": payload.get("stackTrace", ""),
        "device_info": payload.get("deviceInfo", {}),
    }

    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    with open(LOG_PATH, "a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")

    return jsonify({"status": "ok"}), 200


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
