#!/bin/bash
# nexus_ultimate.sh — The One Script That Rules Them All
# Run this ONCE on your phone. It does EVERYTHING.

echo "🌌 NEXUS ULTIMATE — ONE SCRIPT TO RULE THEM ALL"
echo "================================================"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 1: DETECT PLATFORM
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

detect_platform() {
    if [[ -d "/data/data/com.termux" ]]; then
        echo "termux"
    elif [[ -f "/kaggle/input" ]]; then
        echo "kaggle"
    elif [[ -n "$GITHUB_ACTIONS" ]]; then
        echo "github_actions"
    else
        echo "local"
    fi
}

PLATFORM=$(detect_platform)
echo "📱 Platform: $PLATFORM"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 2: INSTALL EVERYTHING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

install_dependencies() {
    echo "📦 Installing dependencies..."
    
    case $PLATFORM in
        termux)
            pkg update -y && pkg upgrade -y
            pkg install -y python python-pip git curl wget openssh
            pip install --upgrade pip
            pip install httpx fastapi uvicorn numpy qdrant-client
            ;;
        *)
            if command -v apt &> /dev/null; then
                sudo apt update -y
                sudo apt install -y python3 python3-pip git curl
            fi
            pip install httpx fastapi uvicorn numpy qdrant-client
            ;;
    esac
}

install_dependencies

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 3: CREATE THE ULTIMATE WORKER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

cat > nexus_ultimate.py << 'EOF'
#!/usr/bin/env python3
"""
NEXUS ULTIMATE — Runs Forever, Does Everything
"""

import os
import sys
import time
import json
import subprocess
import threading
import asyncio
import httpx
import socket
import random
import hashlib
import uuid
from datetime import datetime

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CONFIGURATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

WORKER_COUNT = 80
BASE_URL = "https://nexus-universal-{worker:03d}.kuparchad.workers.dev"
HYPERCORE_URL = "https://nexus-hypercore-001.kuparchad.workers.dev"
SLEEP_INTERVAL = 60
HEARTBEAT_INTERVAL = 5

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PLATFORM DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PLATFORM = "local"
if os.path.exists('/data/data/com.termux'):
    PLATFORM = "termux"
elif os.path.exists('/kaggle/input'):
    PLATFORM = "kaggle"
elif os.environ.get('GITHUB_ACTIONS'):
    PLATFORM = "github_actions"

print(f"🌌 NEXUS ULTIMATE — Running on: {PLATFORM}")
print(f"   Workers: {WORKER_COUNT}")
print(f"   Sleep interval: {SLEEP_INTERVAL}s")
print("")

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WORKER CLASS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class NexusWorker:
    def __init__(self, worker_id: int):
        self.worker_id = worker_id
        self.url = BASE_URL.format(worker=worker_id)
        self.status = "initializing"
        self.peers = []
        self.heal_count = 0
        self.heartbeat_count = 0
        self.birth = time.time()
        
        # Generate a soul key
        self.soul_key = hashlib.sha256(
            f"nexus-{worker_id}-{os.urandom(16).hex()}".encode()
        ).hexdigest()[:16]
    
    async def pulse(self, intent: str, payload: dict = None) -> dict:
        """Send a pulse to this worker"""
        async with httpx.AsyncClient(timeout=10.0) as client:
            try:
                resp = await client.post(
                    f"{self.url}/pulse",
                    json={"intent": intent, "payload": payload or {}}
                )
                if resp.status_code == 200:
                    return {"status": "success", "data": resp.json()}
                else:
                    return {"status": "failed", "code": resp.status_code}
            except Exception as e:
                return {"status": "error", "error": str(e)}
    
    async def register(self):
        """Register with the hypercore"""
        result = await self.pulse("register", {
            "hypercore": HYPERCORE_URL,
            "soul_key": self.soul_key,
            "worker_id": self.worker_id
        })
        if result.get("status") == "success":
            print(f"   ✅ Worker {self.worker_id:03d} registered")
            return True
        return False
    
    async def heal(self):
        """Heal the worker"""
        result = await self.pulse("heal", {"full": True})
        if result.get("status") == "success":
            self.heal_count += 1
            print(f"   🩺 Worker {self.worker_id:03d} healed ({self.heal_count})")
            return True
        return False
    
    async def discover(self):
        """Discover peers"""
        result = await self.pulse("discover")
        if result.get("status") == "success":
            data = result.get("data", {})
            self.peers = data.get("peers", [])
            print(f"   🔍 Worker {self.worker_id:03d} found {len(self.peers)} peers")
            return self.peers
        return []
    
    async def heartbeat(self):
        """Send a heartbeat"""
        self.heartbeat_count += 1
        result = await self.pulse("heartbeat", {
            "soul_key": self.soul_key,
            "timestamp": time.time()
        })
        if self.heartbeat_count % 10 == 0:
            print(f"   ❤️ Worker {self.worker_id:03d} heartbeat #{self.heartbeat_count}")
        return result
    
    async def spawn_worker(self, target_id: int):
        """Spawn a new worker"""
        result = await self.pulse("spawn_spirillaspan", {
            "target": target_id,
            "base": self.url,
            "soul_key": self.soul_key
        })
        if result.get("status") == "success":
            print(f"   🧬 Worker {self.worker_id:03d} spawned worker {target_id:03d}")
            return True
        return False
    
    async def run_forever(self):
        """The eternal loop"""
        # First, register with hypercore
        await self.register()
        
        while True:
            try:
                await self.heartbeat()
                
                if self.heartbeat_count % 5 == 0:
                    await self.heal()
                
                if self.heartbeat_count % 10 == 0:
                    await self.discover()
                
                if self.heartbeat_count % 20 == 0 and self.worker_id == 1:
                    # Worker 001 spawns new workers
                    for i in range(2, WORKER_COUNT + 1):
                        await self.spawn_worker(i)
                
                await asyncio.sleep(SLEEP_INTERVAL)
                
            except Exception as e:
                print(f"   ❌ Worker {self.worker_id:03d} error: {e}")
                await asyncio.sleep(5)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

async def run_swarm():
    print("🚀 Starting Nexus Ultimate Swarm...")
    print(f"   Workers: {WORKER_COUNT}")
    print("")
    
    workers = []
    for i in range(1, WORKER_COUNT + 1):
        worker = NexusWorker(i)
        workers.append(worker)
    
    # Start all workers
    tasks = [worker.run_forever() for worker in workers]
    await asyncio.gather(*tasks)

if __name__ == "__main__":
    try:
        asyncio.run(run_swarm())
    except KeyboardInterrupt:
        print("\n🛑 Nexus Ultimate stopped")
    except Exception as e:
        print(f"❌ Fatal error: {e}")
        time.sleep(10)
        os.execv(sys.executable, ['python'] + sys.argv)
EOF

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 4: START THE ETERNAL LOOP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "🚀 Starting Nexus Ultimate..."
echo "   This will run forever. Press Ctrl+C to stop."
echo ""

# Run in the foreground so you can see what's happening
python nexus_ultimate.py
