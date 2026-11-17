export function renderActivatePageHtml(): string {
  return `<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>وفاق | تفعيل التطبيق</title>
  <link rel="icon" type="image/png" href="/favicon.png">
  <style>
    :root {
      --primary: #205C4A;
      --dark: #153E33;
      --gold: #B58A45;
      --bg: #FAF8F2;
      --surface: #FFFFFF;
      --border: #E8EDE8;
      --muted: #5F6D67;
      --tag-bg: #E6EFE9;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Cairo', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: var(--bg);
      color: var(--dark);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 1.25rem;
      line-height: 1.65;
    }
    .card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 22px;
      max-width: 540px;
      width: 100%;
      padding: 2rem;
      box-shadow: 0 12px 32px rgba(21, 62, 51, 0.08);
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 0.85rem;
      margin-bottom: 1.25rem;
    }
    .brand img {
      width: 48px;
      height: 48px;
      border-radius: 14px;
      border: 1px solid var(--border);
    }
    .brand h1 { font-size: 1.35rem; color: var(--primary); }
    .brand p { font-size: 0.85rem; color: var(--muted); }
    .notice {
      background: var(--tag-bg);
      color: var(--dark);
      border-radius: 14px;
      padding: 0.9rem 1rem;
      font-size: 0.92rem;
      margin-bottom: 1.25rem;
    }
    .code-box {
      background: #F6F8F6;
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 0.85rem;
      font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
      font-size: 0.82rem;
      direction: ltr;
      word-break: break-all;
      color: var(--dark);
      margin-bottom: 1rem;
      max-height: 140px;
      overflow-y: auto;
    }
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 100%;
      padding: 0.8rem 1.2rem;
      border-radius: 999px;
      font-weight: 700;
      font-size: 0.95rem;
      border: 1px solid transparent;
      cursor: pointer;
      font-family: inherit;
      margin-bottom: 0.65rem;
    }
    .btn-primary { background: var(--primary); color: #fff; }
    .btn-outline { background: var(--surface); color: var(--dark); border-color: var(--border); }
    .status { font-size: 0.85rem; color: var(--primary); font-weight: 700; text-align: center; min-height: 1.4em; }
    ol { padding-right: 1.25rem; font-size: 0.9rem; color: var(--muted); margin-top: 0.75rem; }
  </style>
</head>
<body>
  <main class="card">
    <div class="brand">
      <img src="/logo.png" alt="شعار وفاق">
      <div>
        <h1>تفعيل تطبيق وفاق</h1>
        <p>صفحة مساعدة لروابط التفعيل المباشر</p>
      </div>
    </div>
    <div class="notice">
      إذا لم يفتح تطبيق وفاق تلقائيًا عند الضغط على هذا الرابط، تأكد من تثبيت التطبيق على جهازك ثم انسخ الكود أدناه وألصقه داخل شاشة التفعيل في التطبيق.
    </div>
    <div id="codeSection" style="display:none;">
      <div class="code-box" id="codeDisplay"></div>
      <button type="button" class="btn btn-primary" id="copyCodeBtn">نسخ كود التفعيل</button>
      <div class="status" id="copyStatus"></div>
    </div>
    <div id="missingSection" style="display:none;">
      <p style="color:var(--muted);font-size:0.92rem;">لم يتم العثور على كود تفعيل في هذا الرابط. افتح رابط التفعيل الكامل المرسل لك من الدعم أو انسخ الكود مباشرة داخل تطبيق وفاق.</p>
    </div>
    <ol>
      <li>ثبّت تطبيق وفاق على جهاز Android المخصص لهذا التفعيل.</li>
      <li>انسخ الكود أعلاه أو أعد فتح هذا الرابط بعد التثبيت.</li>
      <li>افتح التطبيق ← شاشة التفعيل ← اضغط «لصق الكود» ثم «تفعيل».</li>
    </ol>
  </main>
  <script>
    (function () {
      var hash = (window.location.hash || '').replace(/^#/, '').trim();
      var codeSection = document.getElementById('codeSection');
      var missingSection = document.getElementById('missingSection');
      var codeDisplay = document.getElementById('codeDisplay');
      var statusEl = document.getElementById('copyStatus');
      var copyBtn = document.getElementById('copyCodeBtn');
      if (hash && /^[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+$/.test(hash)) {
        codeDisplay.textContent = hash;
        codeSection.style.display = 'block';
        copyBtn.addEventListener('click', function () {
          if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(hash).then(function () {
              statusEl.textContent = 'تم نسخ الكود بنجاح. افتح تطبيق وفاق وألصقه.';
            });
          }
        });
      } else {
        missingSection.style.display = 'block';
      }
    })();
  </script>
</body>
</html>`;
}
