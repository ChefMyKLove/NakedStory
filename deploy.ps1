# deploy.ps1
# Run from wereNaked_story/ to push the latest story to naked.chefmyklove.com/story
# Usage: .\deploy.ps1

$src   = "$PSScriptRoot\index.html"
$dest  = "$PSScriptRoot\..\naked_site\story\index.html"
$naked = "$PSScriptRoot\..\naked_site"

# ── 1. Copy dev file to naked_site ───────────────────────────────────────────
Copy-Item $src $dest -Force
Write-Host "Copied index.html → naked_site/story/"

# ── 2. Read content ───────────────────────────────────────────────────────────
$content = [System.IO.File]::ReadAllText($dest, [System.Text.Encoding]::UTF8)

# ── 3. Inject <base href="/story/"> if missing ────────────────────────────────
if ($content -notmatch '<base href="/story/">') {
    $content = $content.Replace('<head>', "<head>`n  <base href=""/story/"">")
    Write-Host "Injected: base href"
} else {
    Write-Host "base href already present"
}

# ── 4. Inject token gate if missing ──────────────────────────────────────────
if ($content -notmatch 'naked-gate') {
    $gate = @'
<div id="naked-gate" style="position:fixed;inset:0;background:#1a1410;display:flex;flex-direction:column;align-items:center;justify-content:center;z-index:2147483647;transition:opacity 0.6s ease;">
  <p style="color:rgba(200,169,106,0.9);font-family:'Cormorant Garamond',serif;font-size:1.1em;letter-spacing:0.2em;text-transform:uppercase;margin:0 0 18px;">ChefMyKLove</p>
  <p id="naked-gate-msg" style="color:rgba(255,255,255,0.6);font-family:'Cormorant Garamond',serif;font-size:0.95em;letter-spacing:0.1em;margin:0 0 20px;">Verifying access…</p>
  <a id="naked-gate-link" href="https://naked.chefmyklove.com" style="display:none;color:rgba(200,169,106,0.8);font-family:'Cormorant Garamond',serif;font-size:0.9em;letter-spacing:0.12em;text-decoration:none;border-bottom:1px solid rgba(200,169,106,0.3);padding-bottom:2px;">Support the work →</a>
</div>
<script>
(function(){
  var API = 'https://naked-production.up.railway.app';
  var token = new URLSearchParams(window.location.search).get('token');
  var gate = document.getElementById('naked-gate');
  var msg  = document.getElementById('naked-gate-msg');
  var link = document.getElementById('naked-gate-link');
  function deny()  { msg.textContent = 'Access required'; link.style.display = 'inline'; }
  function allow() { gate.style.opacity='0'; setTimeout(function(){ if(gate.parentNode) gate.parentNode.removeChild(gate); },700); }
  if (!token) { deny(); return; }
  fetch(API+'/api/verify?token='+encodeURIComponent(token))
    .then(function(r){return r.json();})
    .then(function(d){d.valid?allow():deny();})
    .catch(deny);
})();
</script>
'@
    $content = [regex]::Replace($content, '(<body[^>]*>)', ('$1' + "`n" + $gate))
    Write-Host "Injected: token gate"
} else {
    Write-Host "Token gate already present"
}

# ── 5. Write back ─────────────────────────────────────────────────────────────
[System.IO.File]::WriteAllText($dest, $content, [System.Text.Encoding]::UTF8)
Write-Host "Written to naked_site/story/index.html"

# ── 6. Commit + push ──────────────────────────────────────────────────────────
Push-Location $naked
$msg = Read-Host "`nCommit message (Enter = 'deploy: update story')"
if ([string]::IsNullOrWhiteSpace($msg)) { $msg = "deploy: update story" }
git add story/index.html
git commit -m $msg
git push
Pop-Location

Write-Host "`nLive at https://naked.chefmyklove.com/story"
