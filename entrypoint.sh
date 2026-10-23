#!/bin/bash
# Traffic Stack — all-in-one entrypoint.
# Builds a supervisor config at boot containing ONLY the viewers whose
# API key / token was supplied as a service variable, then runs them all
# inside this one container.
#
# Variables (set on the Render/Railway service, never in this repo):
#   NINEHITS_KEY          9Hits app token (dash.9hits.com -> Profile)
#   APPLICATION_KEY       Otohits application key (account -> App page)
#   FEELINGSURF_TOKEN     FeelingSurf access token (account -> Viewer page)
#   ORGANIC_SESSION_KEY   Organic Hits session key (Traffic Exchange -> Sessions)
#   ENABLE_9HITS / ENABLE_OTOHITS / ENABLE_FEELINGSURF / ENABLE_ORGANIC
#                         set any of these to "false" to force-disable a viewer
#   PORT                  provided by Render/Railway automatically

PORT="${PORT:-10000}"
CONF=/tmp/supervisord.conf
BIN=/tmp/viewers
mkdir -p "$BIN"

cat > "$CONF" <<'HDR'
[supervisord]
nodaemon=true
logfile=/tmp/supervisord.log
pidfile=/tmp/supervisord.pid

[unix_http_server]
file=/tmp/supervisor.sock

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///tmp/supervisor.sock
HDR

add_program() {
  # $1 = name, $2 = start script path
  cat >> "$CONF" <<EOF

[program:$1]
command=/bin/bash $2
autostart=true
autorestart=true
startsecs=10
stopwaitsecs=15
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF
}

ENABLED=""
SKIPPED=""

# ---------- platform port server + keep-alive (always on) ----------
printf '#!/bin/bash\nexec python3 -m http.server "%s"\n' "$PORT" > "$BIN/portserver.sh"
printf '#!/bin/bash\nexec python3 /keepalive.py\n' > "$BIN/keepalive.sh"
add_program portserver "$BIN/portserver.sh"
add_program keepalive "$BIN/keepalive.sh"

# ---------- 9Hits ----------
if [ "$ENABLE_9HITS" != "false" ] && [ -n "$NINEHITS_KEY" ]; then
  cat > "$BIN/9hits.sh" <<'EOF'
#!/bin/bash
exec /nh.sh --access-key="$NINEHITS_KEY" --note=all-in-one --hide-browser=yes --system-session
EOF
  add_program ninehits "$BIN/9hits.sh"
  ENABLED="$ENABLED 9hits"
else
  SKIPPED="$SKIPPED 9hits(no-key-or-disabled)"
fi

# ---------- Otohits ----------
if [ "$ENABLE_OTOHITS" != "false" ] && [ -n "$APPLICATION_KEY" ]; then
  cat > "$BIN/otohits.sh" <<'EOF'
#!/bin/bash
export OTO_DOCKER=true
cd /otohits
exec /otohits/run.sh
EOF
  add_program otohits "$BIN/otohits.sh"
  ENABLED="$ENABLED otohits"
else
  SKIPPED="$SKIPPED otohits(no-key-or-disabled)"
fi

# ---------- FeelingSurf ----------
FS_TOKEN="${FEELINGSURF_TOKEN:-$access_token}"
if [ "$ENABLE_FEELINGSURF" != "false" ] && [ -n "$FS_TOKEN" ]; then
  cat > "$BIN/feelingsurf.sh" <<EOF
#!/bin/bash
export access_token="$FS_TOKEN"
cd /home/fsviewer
exec /feelingsurf-run.sh
EOF
  add_program feelingsurf "$BIN/feelingsurf.sh"
  ENABLED="$ENABLED feelingsurf"
else
  SKIPPED="$SKIPPED feelingsurf(no-key-or-disabled)"
fi

# ---------- Organic Hits ----------
if [ "$ENABLE_ORGANIC" != "false" ] && [ -n "$ORGANIC_SESSION_KEY" ]; then
  mkdir -p /home/exchanger/data
  printf '["%s"]' "$ORGANIC_SESSION_KEY" > /home/exchanger/data/sessions.json
  cat > "$BIN/organichits.sh" <<'EOF'
#!/bin/bash
cd /home/exchanger
export PORT=3000
exec node src/server.js
EOF
  add_program organichits "$BIN/organichits.sh"
  ENABLED="$ENABLED organichits"
else
  SKIPPED="$SKIPPED organichits(no-key-or-disabled)"
fi

chmod +x "$BIN"/*.sh

echo "=================================================="
echo " Traffic Stack ALL-IN-ONE starting on port $PORT"
echo " Enabled viewers:${ENABLED:- none}"
echo " Skipped:${SKIPPED:- none}"
echo " 10KHits: Windows-only app - run ./windows-10khits/"
echo "          from this same repo on a Windows host."
echo "=================================================="

exec supervisord -c "$CONF"
