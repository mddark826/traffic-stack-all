# 10KHits — Windows part of this same repo

10KHits' exchanger is a **Windows-only .exe** (unchanged since 2015).
It cannot run inside the Linux Docker container that hosts the other
four viewers, and running Windows .exe files under Wine in a cloud
container is unreliable (repeated page-fault crashes in past tests).

So the 5th platform runs from this same repo, on a Windows host:

1. Open your Windows host (e.g. the GitHub Codespaces Windows desktop,
   or your own laptop).
2. Download the 10KHits exchanger app from your 10KHits account
   (Traffic Exchange / Autosurf section) and sign in with your account.
3. Or run `start-10khits.bat` in this folder after placing the
   exchanger .exe next to it — it just launches the app.
4. Leave it running while the Windows host is on. Sessions earned there
   land in the same 10KHits account as your campaign.

Note: a Windows host that is off earns nothing — treat 10KHits as a
bonus lane, not part of the 24/7 cloud total.
