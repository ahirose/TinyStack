import os

worker_host = os.environ.get("TINYSTACK_LLM_HOST", "127.0.0.1")
worker_port = int(os.environ.get("TINYSTACK_LLM_PORT", "8001"))
