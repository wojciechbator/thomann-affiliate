# Thomann Affiliate Converter

A simple, fast, static web app at `thomann.virya.music` that lets fans paste
Thomann product links, convert them to Virya affiliate links, open them in
browser tabs, and see a best-effort total cost summary.

No backend. No build step. No framework. A single `index.html` file with
inline CSS (Virya design tokens) and vanilla JS.

## What it does

1. **Paste** Thomann product links (one per line) into the textarea.
2. **Convert** — each link is validated (must be `thomann.pl` or `thomann.de`)
   and rewritten with Virya affiliate params (`offid=1&affid=4979&subid=virya_music&subid2=converter`).
3. **Open all** — opens each affiliate link in a new browser tab.
4. **Copy all** — copies all affiliate links to the clipboard.
5. **Total cost** — best-effort price extraction from each Thomann page. If
   the browser can fetch the page (CORS may block it), prices and a total
   summary appear. If not, links still work without prices.

## Local development

Just open `index.html` in a browser. No server needed.

```bash
open index.html
# or
python3 -m http.server 8080 && open http://localhost:8080
```

## Deploy

### Prerequisites

- SSH access to `virya-home` (the host serving `thomann.virya.music`)
- DNS control over `virya.music` (to create the subdomain A record)
- `lego` installed on virya-home (already present at `/usr/bin/lego`)

### 1. Create DNS A record

On your DNS provider for `virya.music`, create:

```
thomann.virya.music    A    185.164.142.202
```

Wait for propagation:

```bash
dig +short thomann.virya.music
# should return 185.164.142.202
```

### 2. Set up directories on virya-home

```bash
ssh virya-home
sudo mkdir -p /srv/thomann-affiliate
sudo mkdir -p /var/lib/thomann-affiliate/lego
sudo chown -R $USER:$USER /srv/thomann-affiliate /var/lib/thomann-affiliate
```

### 3. Issue TLS certificate

Using lego with HTTP-01 challenge (port 80 must be reachable):

```bash
ssh virya-home
sudo lego --email you@example.com \
  --http --http.port :80 \
  --path /var/lib/thomann-affiliate/lego \
  -d thomann.virya.music \
  run
```

If port 80 is already in use by nginx, use the webroot method or a temporary
port redirect. Alternatively, use DNS-01 challenge if your DNS provider is
supported by lego.

### 4. Install nginx config

```bash
ssh virya-home
sudo cp /path/to/deploy/nginx.conf /etc/nginx/sites-available/thomann-affiliate.conf
sudo ln -sf /etc/nginx/sites-available/thomann-affiliate.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 5. Deploy the app

```bash
# From your local machine:
scp index.html virya-home:/srv/thomann-affiliate/index.html
```

Or use the deploy script:

```bash
bash deploy/deploy.sh
```

### 6. Verify

```bash
curl -sI https://thomann.virya.music/ | head
# Should return 200 OK
```

### TLS renewal

Lego certificates expire after 90 days. Set up a renewal cron:

```bash
ssh virya-home
sudo crontab -e
# Add:
0 3 * * * /usr/bin/lego --email you@example.com --http --http.port :80 --path /var/lib/thomann-affiliate/lego -d thomann.virya.music renew && systemctl reload nginx
```

## Affiliate IDs

These are public (already in the [virya repo](https://github.com/CrowdRelay/virya)):

| Param  | Value          |
|--------|----------------|
| offid  | 1              |
| affid  | 4979           |
| subid  | virya_music    |
| subid2 | converter      |

`subid2=converter` distinguishes traffic from this tool vs. the gear page
(`gear`), footer (`footer`), or EPK (`epk`) in Thomann's affiliate reporting.

## Limitations

- **Price extraction is best-effort**: Thomann uses Cloudflare bot detection
  and does not send CORS headers. Client-side `fetch()` will likely be
  blocked. The total cost summary appears only when the browser can fetch
  the pages. The core affiliate conversion always works.
- **Popup blockers**: "Open all" may be blocked by the browser. If so, use
  "Copy all" and paste links manually, or open them one by one.
- **English only**: v1 is English-only. Polish can be added later.
