import os, time, urllib.request

def url():
    u = os.environ.get("RENDER_EXTERNAL_URL")
    if u:
        return u
    d = os.environ.get("RAILWAY_PUBLIC_DOMAIN")
    return "https://" + d if d else None

while True:
    u = url()
    if u:
        try:
            urllib.request.urlopen(u, timeout=30).read()
        except Exception:
            pass
    time.sleep(600)
