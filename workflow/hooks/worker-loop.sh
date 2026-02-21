#!/bin/bash
# .gemini/hooks/worker-loop.sh

# 1. Run the tests defined by the QA agent in Phase 1
npm test # or pytest, etc.

if [ $? -eq 0 ]; then
  echo '{"decision": "stop", "reason": "Tests passed. Worker loop complete."}'
else
  # 2. If tests fail, send the error back to the Worker agent
  echo '{"decision": "continue", "systemMessage": "Tests failed. Review the output and fix the code."}'
fi