#!/usr/bin/env python3
"""nt-deploy GUI — ultra-light control panel (stdlib only, zero dependencies).
Start with:  nt-gui [port]   (launched by nt-deploy.sh with NT_SCRIPT and NT_PROJECT).
Binds to 127.0.0.1 only and runs a strict whitelist of nt-deploy commands.
Light theme inspired by next-forge / shadcn/ui."""
import json, os, re, subprocess, sys, shutil, urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HOME     = os.path.expanduser("~")
CFG_DIR  = os.path.join(HOME, ".nt-tools")
SETTINGS = os.path.join(CFG_DIR, "settings")
CONFIG   = os.path.join(CFG_DIR, "config")
SCRIPT   = os.environ.get("NT_SCRIPT", os.path.join(CFG_DIR, "nt-deploy.sh"))
PROJECT  = os.environ.get("NT_PROJECT", "anteprima")
PORT     = int(sys.argv[1]) if len(sys.argv) > 1 else 7700

WHITELIST = {"clients", "list", "projects", "snapshots", "check", "audit",
             "open", "qr", "stats", "rollback", "rm", "config", "analytics"}
CONFIRM   = {"rollback", "rm"}
ANSI = re.compile(r"\x1b\[[0-9;]*m")
SAFE = re.compile(r"^[A-Za-z0-9._:/?=&%@ -]+$")
SECRET_KEYS = {"NT_PSI_KEY", "NT_CF_TOKEN", "NT_CF_BEACON"}
KEYS = ["NT_PROJECT", "NT_PSI_KEY", "NT_CF_TOKEN", "NT_CF_ACCOUNT",
        "NT_CF_SITETAG", "NT_CF_BEACON", "NT_AUTO_UPDATE"]

def read_settings():
    vals = {}
    if os.path.exists(SETTINGS):
        for ln in open(SETTINGS):
            m = re.match(r'\s*([A-Z_]+)="?\$\{\1:-(.*?)\}"?\s*$', ln) or re.match(r'\s*([A-Z_]+)="?(.*?)"?\s*$', ln)
            if m:
                vals[m.group(1)] = m.group(2)
    if os.path.exists(CONFIG):
        for ln in open(CONFIG):
            m = re.match(r'\s*NT_PROJECT=(.*?)\s*$', ln)
            if m:
                vals["NT_PROJECT"] = m.group(1).strip('"')
    return vals

def write_settings(updates):
    cur = read_settings()
    for k, v in updates.items():
        if k in KEYS and v != "":
            cur[k] = v
    os.makedirs(CFG_DIR, exist_ok=True)
    # NT_PROJECT → config (used by project resolution)
    if cur.get("NT_PROJECT"):
        with open(CONFIG, "w") as f:
            f.write(f'NT_PROJECT={cur["NT_PROJECT"]}\n')
    # the rest → settings (env still wins thanks to ${VAR:-value})
    with open(SETTINGS, "w") as f:
        f.write("# nt-deploy settings — managed by the GUI\n")
        for k in KEYS:
            if k == "NT_PROJECT":
                continue
            v = cur.get(k, "")
            if v != "":
                f.write(f'{k}="${{{k}:-{v}}}"\n')
    return cur

def masked():
    cur = read_settings()
    out = {}
    for k in KEYS:
        v = cur.get(k, "")
        if k in SECRET_KEYS and v:
            out[k] = "set"          # never expose secrets to the page
        elif k in SECRET_KEYS:
            out[k] = ""
        else:
            out[k] = v
    return out

def run(cmd, args, project):
    if cmd not in WHITELIST:
        return 400, f"command not allowed: {cmd}"
    argv = [SCRIPT]
    if project and SAFE.match(project):
        argv += ["-p", project]
    argv.append(cmd)
    for a in args:
        if a and SAFE.match(a):
            argv.append(a)
    if cmd in CONFIRM:
        argv.append("-y")
    try:
        out = subprocess.run(argv, capture_output=True, text=True, timeout=120,
                             env={**os.environ, "NT_PROJECT": project or PROJECT})
        return 200, ANSI.sub("", (out.stdout or "") + (out.stderr or "")).strip() or "(no output)"
    except subprocess.TimeoutExpired:
        return 504, "timeout (command took too long)"
    except Exception as e:
        return 500, str(e)

def qr_svg(url):
    if shutil.which("qrencode"):
        try:
            r = subprocess.run(["qrencode", "-o", "-", "-t", "SVG", "-m", "1", url],
                               capture_output=True, timeout=10)
            if r.returncode == 0 and r.stdout:
                return r.stdout, "image/svg+xml"
        except Exception:
            pass
    return None, None

PAGE = r"""<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>nt-deploy · console</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Geist:wght@400;500;600;700&family=Geist+Mono:wght@400;500&display=swap" rel="stylesheet">
<style>
:root{
 --bg:#ffffff;--fg:#09090b;--card:#ffffff;--muted:#f4f4f5;--muted-fg:#71717a;
 --border:#e4e4e7;--input:#e4e4e7;--primary:#18181b;--primary-fg:#fafafa;
 --accent:#6d4aff;--accent-fg:#ffffff;--ring:#a1a1aa;--green:#16a34a;--red:#dc2626;--radius:.6rem;
}
*{box-sizing:border-box;margin:0}
body{font-family:Geist,system-ui,sans-serif;background:var(--bg);color:var(--fg);font-size:14px;line-height:1.5}
.mono{font-family:"Geist Mono",ui-monospace,monospace}
header{position:sticky;top:0;z-index:10;display:flex;align-items:center;gap:14px;padding:12px 22px;
 background:rgba(255,255,255,.8);backdrop-filter:blur(8px);border-bottom:1px solid var(--border)}
.logo{display:flex;align-items:center;gap:9px;font-weight:700;letter-spacing:-.01em}
.logo i{display:grid;place-items:center;width:30px;height:30px;border-radius:8px;background:var(--primary);color:#fff;font-style:normal}
.tabs{display:flex;gap:4px;background:var(--muted);padding:4px;border-radius:var(--radius)}
.tab{border:0;background:transparent;color:var(--muted-fg);font:inherit;font-weight:500;padding:6px 14px;border-radius:.45rem;cursor:pointer}
.tab.on{background:#fff;color:var(--fg);box-shadow:0 1px 2px rgba(0,0,0,.06)}
.sp{flex:1}
.proj{display:flex;align-items:center;gap:8px;font-size:13px;color:var(--muted-fg)}
.proj b{color:var(--fg)}
main{max-width:1080px;margin:0 auto;padding:24px 22px 60px}
.grid{display:grid;grid-template-columns:300px 1fr;gap:20px}
@media(max-width:780px){.grid{grid-template-columns:1fr}}
.card{background:var(--card);border:1px solid var(--border);border-radius:var(--radius);box-shadow:0 1px 2px rgba(0,0,0,.04)}
.card h2{font-size:15px;font-weight:600;padding:16px 18px 0}
.card .desc{color:var(--muted-fg);font-size:13px;padding:2px 18px 0}
.card .body{padding:16px 18px}
.btn{border:1px solid var(--border);background:#fff;color:var(--fg);font:inherit;font-weight:500;font-size:13px;
 padding:8px 13px;border-radius:.5rem;cursor:pointer;transition:.15s;display:inline-flex;align-items:center;gap:7px}
.btn:hover{background:var(--muted)}
.btn.pri{background:var(--primary);color:var(--primary-fg);border-color:var(--primary)}.btn.pri:hover{opacity:.9}
.btn.acc{background:var(--accent);color:#fff;border-color:var(--accent)}.btn.acc:hover{opacity:.9}
.btn.des{color:var(--red);border-color:#fecaca}.btn.des:hover{background:#fef2f2}
.row{display:flex;flex-wrap:wrap;gap:8px}
.list{list-style:none;padding:0;margin:0;display:flex;flex-direction:column;gap:2px}
.list li{padding:8px 10px;border-radius:.45rem;cursor:pointer;display:flex;align-items:center;gap:8px;color:var(--fg)}
.list li:hover{background:var(--muted)}.list li.on{background:var(--muted);font-weight:500}
.list li .dot{width:7px;height:7px;border-radius:50%;background:var(--green)}
.muted{color:var(--muted-fg)}.lbl{font-size:13px;font-weight:500;margin:14px 0 5px;display:block}
input,select{width:100%;font:inherit;font-size:13px;padding:8px 11px;border:1px solid var(--input);border-radius:.5rem;background:#fff;color:var(--fg)}
input:focus,select:focus{outline:2px solid var(--ring);outline-offset:-1px}
pre{background:#fafafa;border:1px solid var(--border);border-radius:.5rem;padding:14px;white-space:pre-wrap;
 word-break:break-word;max-height:46vh;overflow:auto;font-family:"Geist Mono",monospace;font-size:12.5px;color:#27272a;min-height:90px}
.badge{display:inline-flex;align-items:center;gap:5px;font-size:11px;font-weight:600;padding:3px 9px;border-radius:100px;background:var(--muted);color:var(--muted-fg)}
.badge.ok{background:#f0fdf4;color:var(--green)}
.qr{display:grid;place-items:center;padding:14px;border:1px dashed var(--border);border-radius:.5rem;background:#fafafa;min-height:120px}
.qr img,.qr svg{width:200px;height:200px}
.sep{height:1px;background:var(--border);margin:16px 0}
.hide{display:none}
.hint{font-size:12px;color:var(--muted-fg);margin-top:5px}
.toast{position:fixed;left:50%;bottom:26px;transform:translateX(-50%) translateY(30px);background:var(--primary);color:#fff;
 padding:10px 18px;border-radius:.6rem;opacity:0;transition:.25s;font-size:13px;z-index:50}
.toast.show{opacity:1;transform:translateX(-50%) translateY(0)}
</style></head><body>
<header>
 <div class="logo"><i>⚡</i> nt-deploy <span class="muted" style="font-weight:400">console</span></div>
 <div class="tabs"><button class="tab on" data-t="dash">Dashboard</button><button class="tab" data-t="set">Settings</button></div>
 <span class="sp"></span>
 <span class="proj">project <b id="proj"></b></span>
</header>
<main>
 <!-- DASHBOARD -->
 <section id="dash" class="grid">
  <div class="card"><h2>Clients</h2><div class="desc">Active branches in this project</div>
   <div class="body"><ul class="list" id="clients"><li class="muted">loading…</li></ul>
    <div class="sep"></div>
    <div class="row"><button class="btn" onclick="cmd('projects')">Projects</button>
     <button class="btn" onclick="cmd('list')">Deployments</button></div>
   </div>
  </div>
  <div class="card"><h2>Actions <span class="muted" id="sel"></span></h2>
   <div class="desc">Pick a client, then run an action</div>
   <div class="body">
    <div class="row">
     <button class="btn acc" onclick="act('audit')">🔬 PageSpeed</button>
     <button class="btn" onclick="act('check')">🩺 Check</button>
     <button class="btn" onclick="act('open')">🌐 Open</button>
     <button class="btn" onclick="showQR()">🔳 QR</button>
     <button class="btn" onclick="act('snapshots')">📸 Snapshots</button>
     <button class="btn" onclick="act('rollback')">⏪ Rollback</button>
     <button class="btn des" onclick="act('rm')">🗑 Delete</button>
    </div>
    <div class="qr hide" id="qrBox"></div>
    <pre id="out">Select a client or use the project buttons.</pre>
   </div>
  </div>
 </section>

 <!-- SETTINGS -->
 <section id="set" class="hide">
  <div class="card" style="max-width:640px;margin:0 auto">
   <h2>Settings</h2><div class="desc">Stored in ~/.nt-tools — leave secret fields blank to keep the current value</div>
   <div class="body">
    <label class="lbl">Default project</label>
    <input id="s_NT_PROJECT" placeholder="my-project">
    <div class="hint">Used as <span class="mono">&lt;name&gt;.pages.dev</span></div>

    <div class="sep"></div>
    <label class="lbl">PageSpeed API key <span id="b_NT_PSI_KEY"></span></label>
    <input id="s_NT_PSI_KEY" type="password" placeholder="free key from console.cloud.google.com">
    <div class="hint">Removes the anonymous 429 quota limit on <span class="mono">nt-audit</span></div>

    <div class="sep"></div>
    <label class="lbl">Web Analytics — beacon token <span id="b_NT_CF_BEACON"></span></label>
    <input id="s_NT_CF_BEACON" type="password" placeholder="token used by nt-analytics inject">
    <label class="lbl">Analytics API token <span id="b_NT_CF_TOKEN"></span></label>
    <input id="s_NT_CF_TOKEN" type="password" placeholder="API token (Analytics:Read)">
    <div class="row" style="gap:12px;margin-top:8px">
     <div style="flex:1"><label class="lbl">Account ID</label><input id="s_NT_CF_ACCOUNT" placeholder="account id"></div>
     <div style="flex:1"><label class="lbl">Site tag</label><input id="s_NT_CF_SITETAG" placeholder="site tag"></div>
    </div>

    <div class="sep"></div>
    <label class="lbl">Auto-update</label>
    <select id="s_NT_AUTO_UPDATE"><option value="0">Off — notify only</option><option value="1">On — update automatically</option></select>

    <div class="sep"></div>
    <div class="row"><button class="btn pri" onclick="saveSettings()">Save settings</button>
     <button class="btn" onclick="loadSettings()">Reset</button></div>
   </div>
  </div>
 </section>
</main>
<div class="toast" id="toast"></div>
<script>
let project="",sel="";
const $=id=>document.getElementById(id),out=$("out");
function toast(t){const x=$("toast");x.textContent=t;x.classList.add("show");setTimeout(()=>x.classList.remove("show"),1800);}
document.querySelectorAll(".tab").forEach(b=>b.onclick=()=>{
 document.querySelectorAll(".tab").forEach(x=>x.classList.remove("on"));b.classList.add("on");
 $("dash").classList.toggle("hide",b.dataset.t!="dash");$("set").classList.toggle("hide",b.dataset.t!="set");
 if(b.dataset.t=="set")loadSettings();});
async function api(cmd,args=[]){out.textContent="⏳ "+cmd+" "+args.join(" ");$("qrBox").classList.add("hide");
 const r=await fetch("/api/run",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({cmd,args,project})});
 out.textContent=await r.text();}
function cmd(c){api(c);}
function act(c){if(!sel){out.textContent="Pick a client first.";return;}
 if((c=="rollback"||c=="rm")&&!confirm(c+" on '"+sel+"' — are you sure?"))return;api(c,[sel]);}
function showQR(){const c=sel||"main";const box=$("qrBox");box.classList.remove("hide");
 box.innerHTML='<img alt="QR" src="/api/qr?client='+encodeURIComponent(c)+'&project='+encodeURIComponent(project)+'">';
 out.textContent="QR for "+(sel||"production");}
async function loadState(){const s=await(await fetch("/api/state")).json();project=s.project;$("proj").textContent=s.project;loadClients();}
async function loadClients(){const r=await fetch("/api/run",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({cmd:"clients",args:[],project})});
 const t=await r.text();const names=[...t.matchAll(/•\s*([a-z0-9-]+)/g)].map(m=>m[1]);
 const ul=$("clients");ul.innerHTML="";
 if(!names.length){ul.innerHTML='<li class="muted">no clients yet</li>';return;}
 names.forEach(n=>{const li=document.createElement("li");li.innerHTML='<span class="dot"></span>'+n;
  li.onclick=()=>{sel=n;$("sel").textContent="· "+n;[...ul.children].forEach(x=>x.classList.remove("on"));li.classList.add("on");};ul.appendChild(li);});}
async function loadSettings(){const s=await(await fetch("/api/settings")).json();
 ["NT_PROJECT","NT_CF_ACCOUNT","NT_CF_SITETAG"].forEach(k=>$("s_"+k).value=s[k]||"");
 $("s_NT_AUTO_UPDATE").value=s.NT_AUTO_UPDATE||"0";
 ["NT_PSI_KEY","NT_CF_TOKEN","NT_CF_BEACON"].forEach(k=>{$("s_"+k).value="";
  $("b_"+k).innerHTML=s[k]=="set"?'<span class="badge ok">configured</span>':'<span class="badge">not set</span>';});}
async function saveSettings(){const body={};
 ["NT_PROJECT","NT_PSI_KEY","NT_CF_TOKEN","NT_CF_ACCOUNT","NT_CF_SITETAG","NT_CF_BEACON","NT_AUTO_UPDATE"].forEach(k=>body[k]=$("s_"+k).value);
 const r=await fetch("/api/settings",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(body)});
 if(r.ok){const s=await r.json();project=s.NT_PROJECT||project;$("proj").textContent=project;toast("Settings saved ✓");loadSettings();}else toast("Save failed");}
loadState();
</script></body></html>"""

class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def _send(self, code, body, ctype="text/plain; charset=utf-8"):
        b = body.encode() if isinstance(body, str) else body
        self.send_response(code); self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(b))); self.end_headers(); self.wfile.write(b)
    def do_GET(self):
        u = urllib.parse.urlparse(self.path); q = urllib.parse.parse_qs(u.query)
        if u.path == "/" or u.path.startswith("/index"):
            self._send(200, PAGE, "text/html; charset=utf-8")
        elif u.path == "/api/state":
            self._send(200, json.dumps({"project": PROJECT}), "application/json")
        elif u.path == "/api/settings":
            self._send(200, json.dumps(masked()), "application/json")
        elif u.path == "/api/qr":
            client = (q.get("client", ["main"])[0]); proj = (q.get("project", [PROJECT])[0])
            url = f"https://{proj}.pages.dev" if client in ("main", "") else f"https://{client}.{proj}.pages.dev"
            svg, ctype = qr_svg(url)
            if svg:
                self._send(200, svg, ctype)
            else:
                self.send_response(302)
                self.send_header("Location", "https://api.qrserver.com/v1/create-qr-code/?size=240x240&data=" + urllib.parse.quote(url))
                self.end_headers()
        else:
            self._send(404, "not found")
    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        try:
            data = json.loads(self.rfile.read(n) or b"{}")
        except Exception:
            return self._send(400, "invalid json")
        if self.path == "/api/run":
            code, body = run(str(data.get("cmd", "")), list(data.get("args", []))[:4], str(data.get("project", "")))
            self._send(code, body)
        elif self.path == "/api/settings":
            cur = write_settings({k: str(v) for k, v in data.items()})
            self._send(200, json.dumps({"NT_PROJECT": cur.get("NT_PROJECT", "")}), "application/json")
        else:
            self._send(404, "not found")

if __name__ == "__main__":
    print(f"nt-deploy GUI · http://localhost:{PORT} · project {PROJECT}")
    try:
        ThreadingHTTPServer(("127.0.0.1", PORT), H).serve_forever()
    except KeyboardInterrupt:
        print("\nstopped.")
