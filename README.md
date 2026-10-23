# Traffic Stack — All-in-One (এক repo, এক web service, সব viewer)

একটাই Docker container-এর ভিতরে 4টা traffic-exchange platform-এর viewer
একসাথে চলে, supervisor দিয়ে:

| Platform | Viewer | চাবি (service variable) |
|---|---|---|
| 9Hits | `/nh.sh` (official `9hitste/appv6`) | `NINEHITS_KEY` |
| Otohits | `/otohits/run.sh` (official `otohits/app-next`) | `APPLICATION_KEY` |
| FeelingSurf | `/home/fsviewer` (official `feelingsurf/viewer`) | `FEELINGSURF_TOKEN` |
| Organic Hits | `/home/exchanger` (official `organichits/exchanger`) | `ORGANIC_SESSION_KEY` |

**10KHits** এই repo-তেই আছে, তবে আলাদা ফোল্ডারে (`windows-10khits/`) —
কারণ ওটার exchanger শুধু Windows .exe, Linux container-এ চলেই না।
Windows host (Codespaces desktop / নিজের ল্যাপটপ) থেকে ওটা চালাতে হয়।

যে platform-এর চাবি দেওয়া হবে না, সেই viewer-টা boot-এর সময়
auto-skip হয়ে যাবে — বাকি গুলো চলতে থাকবে।

## Deploy — Render

1. Render → New → Web Service → এই repo কানেক্ট করো
2. Runtime: **Docker**, Plan: **Free**
3. Environment Variables-এ উপরের 4টা চাবি বসাও
4. Create Web Service — deploy শেষে Logs-এ দেখবে:
   `Enabled viewers: 9hits otohits feelingsurf organichits`

## Deploy — Railway

1. Railway → New Project → Deploy from GitHub repo → এই repo
2. Service → Variables-এ 4টা চাবি বসাও (`railway.json`-এ start command
   আগে থেকেই `/entrypoint.sh` সেট করা আছে)
3. Deploy → Logs-এ একই Enabled লাইন দেখবে

## Deploy — নিজের বড় host / VPS-এ (সবচেয়ে ভালো চলে)

```bash
cp .env.example .env   # চাবি গুলো বসাও
docker compose up -d --build
docker logs -f traffic-stack-all
```

## যাচাই (হয়ে গেছে কিনা)

1. Logs-এ Enabled লাইনে সব নাম আছে কিনা
2. প্রতিটা platform-এর নিজের dashboard-এ session **Online**
3. 15-20 মিনিট পর প্রতিটার **points বেড়েছে** — এটাই আসল প্রমাণ

## সৎ সতর্কতা — RAM

প্রতিটা viewer-ই একটা করে headless Chromium। 4টা একসাথে চলতে
**~5-6 GB RAM** লাগে।

- **Render Free = 512 MB, Railway Free/Trial = ~1 GB** — এত কম RAM-এ
  4টা একসাথে চালালে container OOM হয়ে crash করবে। ফ্রি ছোট service-এ
  `ENABLE_...=false` দিয়ে **1-2টা করে viewer** চালাও — একই repo
  আলাদা আলাদা service-এ deploy করে, প্রতিটায় আলাদা ENABLE সেট করে।
- RAM-ওয়ালা host পেলেই (যেমন বড় ফ্রি VM) কোনো switch ছোঁয়ার দরকার
  নেই — 4টাই একসাথে এক service-এ চলবে, যেভাবে চেয়েছিলে।

## নিরাপত্তা

এই repo-তে **কোনো আসল চাবি নেই** — সব চাবি শুধু Render/Railway-এর
service variable-এ থাকবে। আগের one-click repo গুলোর মতো public
repo-তে token বসানো হয়নি।
