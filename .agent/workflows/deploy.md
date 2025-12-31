---
description: Deploy to lemue-sec
---
// turbo-all
1. Push changes to git
git push
2. SSH to remote and deploy
ssh root@lemue-sec "cd honey-scan && git pull && docker compose up -d --build"
