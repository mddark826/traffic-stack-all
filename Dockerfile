# Traffic Stack — ALL-IN-ONE viewer container
# One web service runs the traffic-exchange viewers of 4 Linux-native
# platforms side by side, supervised in a single container:
#   9Hits  +  Otohits  +  FeelingSurf  +  Organic Hits
# (10KHits is a Windows-only .exe — it lives in ./windows-10khits/ in this
#  same repo and runs on a Windows host; it cannot run inside Linux Docker.)
#
# Built on the official 9Hits image (Chromium stack + /nh.sh), with the
# official app folders of the other viewers copied in:
#   otohits/app-next        -> /otohits        (entry /otohits/run.sh)
#   feelingsurf/viewer      -> /home/fsviewer  (entry /run.sh)
#   organichits/exchanger   -> /home/exchanger (node src/server.js, port 3000)
#
# Set the other keys as service variables (never in this repo):
#   APPLICATION_KEY (Otohits), FEELINGSURF_TOKEN, ORGANIC_SESSION_KEY
# Exception: the 9Hits token of the user's chosen account is baked as a
# default further below (see the NINEHITS_KEY note). A service variable
# named NINEHITS_KEY overrides it.
# A viewer whose key is missing is simply skipped at boot.

FROM otohits/app-next:latest AS otohits_src
FROM feelingsurf/viewer:stable AS feelingsurf_src
FROM organichits/exchanger:latest AS organic_src

FROM 9hitste/appv6

USER root

# supervisor = runs all viewers in one container;
# python3 = Render port-check server + keep-alive pinger.
# (Node is NOT installed from apt — the Organic Hits app needs Node 24,
#  so its own Node binary is copied from the official exchanger image below.)
RUN apt-get update && apt-get install -y --no-install-recommends \
      supervisor python3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=organic_src /usr/local/bin/node /usr/local/bin/node

# --- copy the other viewers' app folders in ---
COPY --from=otohits_src /otohits /otohits
COPY --from=feelingsurf_src /home/fsviewer /home/fsviewer
COPY --from=feelingsurf_src /run.sh /feelingsurf-run.sh
COPY --from=organic_src /home/exchanger /home/exchanger

RUN chmod +x /otohits/run.sh /feelingsurf-run.sh 2>/dev/null; \
    mkdir -p /home/exchanger/data /var/log/supervisor

ENV OTO_DOCKER=true

# 9Hits: the user's chosen account for this stack is "mddark" — its app
# token is set here as the DEFAULT (same token already public in the
# mddark826/9hits-viewer repo; the user picked this one on 2026-10-23
# and dropped the other 3 accounts from this stack).
# A service variable named NINEHITS_KEY still overrides this default.
ENV NINEHITS_KEY="535e223e8084d8c2ed8ec2b95dbe759d"

COPY entrypoint.sh /entrypoint.sh
COPY keepalive.py /keepalive.py
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
