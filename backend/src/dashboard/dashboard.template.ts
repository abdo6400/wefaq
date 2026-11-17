export function renderDashboardHtml(): string {
  return `<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>وفاق | لوحة الإدارة والتحكم</title>
  <link rel="icon" type="image/png" href="/favicon.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --primary: #205C4A;
      --dark: #153E33;
      --gold: #B58A45;
      --bg: #FAF8F2;
      --surface: #FFFFFF;
      --border: #E8EDE8;
      --chip-border: #DDE5DF;
      --muted: #5F6D67;
      --tag-bg: #E6EFE9;
      --chip-bg: #EEF4F0;
      --gold-bg: #F5ECDD;
      --notice-bg: #F3EBDD;
      --tip-bg: #F0F4EF;
      --danger: #9B2C2C;
      --danger-bg: #FDECEC;
      --success: #1E6B47;
      --success-bg: #E4F4EB;
      --shadow: 0 6px 18px rgba(21, 62, 51, 0.06);
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    html, body {
      overflow-x: clip;
      max-width: 100%;
    }
    body {
      font-family: 'Cairo', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background-color: var(--bg);
      color: var(--dark);
      line-height: 1.6;
      min-height: 100vh;
      -webkit-tap-highlight-color: transparent;
    }
    button, input, select, textarea { font-family: inherit; }
    code {
      font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
      direction: ltr;
      unicode-bidi: isolate;
    }

    /* Buttons */
    .btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 0.4rem;
      padding: 0.54rem 1.08rem;
      border-radius: 999px;
      font-weight: 700;
      font-size: 0.88rem;
      cursor: pointer;
      border: 1px solid transparent;
      text-decoration: none;
      transition: background 0.16s, border-color 0.16s, color 0.16s, transform 0.12s;
      white-space: nowrap;
    }
    .btn:active { transform: scale(0.985); }
    .btn-primary { background-color: var(--primary); color: #fff; }
    .btn-primary:hover { background-color: var(--dark); }
    .btn-outline {
      background-color: var(--surface);
      color: var(--dark);
      border-color: var(--chip-border);
    }
    .btn-outline:hover { background-color: var(--tip-bg); border-color: var(--primary); }
    .btn-gold {
      background-color: var(--gold-bg);
      color: #7D5B24;
      border-color: #E5D4B6;
    }
    .btn-gold:hover { background-color: #EFE0C6; }
    .btn-danger {
      background-color: var(--danger-bg);
      color: var(--danger);
      border-color: #F4C7C7;
    }
    .btn-danger:hover { background-color: #FAD8D8; }
    .btn-sm { padding: 0.36rem 0.82rem; font-size: 0.8rem; }
    .btn-block { width: 100%; }
    .btn:disabled { opacity: 0.55; cursor: not-allowed; }

    /* Pills & Badges */
    .pill {
      display: inline-flex;
      align-items: center;
      gap: 0.3rem;
      padding: 0.22rem 0.72rem;
      border-radius: 999px;
      font-size: 0.77rem;
      font-weight: 700;
      background: var(--tag-bg);
      color: var(--primary);
    }
    .pill-gold { background: var(--gold-bg); color: #845E21; }
    .pill-muted { background: var(--tip-bg); color: var(--muted); }
    .pill-danger { background: var(--danger-bg); color: var(--danger); }
    .pill-success { background: var(--success-bg); color: var(--success); }
    .pill-id {
      background: #F4F6F4;
      color: var(--dark);
      font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
      direction: ltr;
      unicode-bidi: isolate;
      font-weight: 600;
    }

    /* Form Controls */
    .input, .select, .textarea {
      width: 100%;
      padding: 0.65rem 0.92rem;
      border-radius: 12px;
      border: 1px solid #D0DDD4;
      background: #FFFFFF;
      color: var(--dark);
      font-size: 0.92rem;
      outline: none;
      transition: border-color 0.15s, background 0.15s, box-shadow 0.15s;
    }
    .input:hover, .select:hover, .textarea:hover { border-color: #AFC4B6; }
    .input:focus, .select:focus, .textarea:focus {
      border-color: var(--primary);
      background: #FFFFFF;
      box-shadow: 0 0 0 3px rgba(32, 92, 74, 0.1);
    }
    .input[readonly] { background: #F5F7F5; color: var(--muted); }
    .textarea { resize: vertical; min-height: 86px; line-height: 1.65; }
    .form-group { margin-bottom: 1rem; }
    .form-label {
      display: block;
      font-weight: 700;
      font-size: 0.87rem;
      margin-bottom: 0.36rem;
      color: var(--dark);
    }
    .form-hint { font-size: 0.77rem; color: var(--muted); margin-top: 0.28rem; line-height: 1.45; }
    .form-row { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 1rem; }
    .form-row > * { min-width: 0; }
    @media (max-width: 680px) { .form-row { grid-template-columns: minmax(0, 1fr); gap: 0.78rem; } }
    .form-box {
      background: #F8FAF8;
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 1rem 1.05rem;
      margin-bottom: 1rem;
    }
    .form-box-title {
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 0.5rem;
      font-size: 0.93rem;
      font-weight: 800;
      color: var(--primary);
      margin-bottom: 0.75rem;
    }
    .preset-grid {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 0.5rem;
      margin-bottom: 0.9rem;
    }
    @media (max-width: 480px) {
      .preset-grid { gap: 0.38rem; }
      .preset-card { padding: 0.52rem 0.45rem; text-align: center; align-items: center; }
      .preset-card strong { font-size: 0.78rem; }
      .preset-card span { font-size: 0.67rem; }
    }
    .preset-card {
      border: 1px solid var(--border);
      background: var(--surface);
      border-radius: 12px;
      padding: 0.62rem 0.75rem;
      text-align: right;
      cursor: pointer;
      transition: all 0.15s;
      display: flex;
      flex-direction: column;
      gap: 0.15rem;
    }
    .preset-card:hover { border-color: var(--primary); transform: translateY(-1px); }
    .preset-card.active {
      border-color: var(--primary);
      background: var(--tip-bg);
      box-shadow: 0 3px 10px rgba(32, 92, 74, 0.1);
    }
    .preset-card strong { font-size: 0.85rem; color: var(--dark); }
    .preset-card span { font-size: 0.74rem; color: var(--muted); font-weight: 600; }
    .checkbox-group { display: flex; gap: 1rem; flex-wrap: wrap; padding-top: 0.2rem; }
    .checkbox-label {
      display: inline-flex;
      align-items: center;
      gap: 0.45rem;
      font-weight: 600;
      cursor: pointer;
      font-size: 0.9rem;
    }
    .form-error {
      background: var(--danger-bg);
      color: var(--danger);
      border: 1px solid #F4C7C7;
      border-radius: 12px;
      padding: 0.68rem 0.9rem;
      font-size: 0.87rem;
      margin-bottom: 0.9rem;
      display: none;
    }
    .form-error.visible { display: block; }

    /* Sign-In Screen */
    .login-shell {
      min-height: 100vh;
      display: none;
      align-items: center;
      justify-content: center;
      padding: 1.5rem;
      background:
        radial-gradient(circle at 12% 15%, rgba(181, 138, 69, 0.12), transparent 36%),
        radial-gradient(circle at 88% 82%, rgba(32, 92, 74, 0.12), transparent 40%),
        var(--bg);
    }
    .login-shell.active { display: flex; }
    .login-card {
      width: 100%;
      max-width: 460px;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 26px;
      overflow: hidden;
      box-shadow: 0 22px 50px rgba(21, 62, 51, 0.12);
    }
    .login-hero {
      background: linear-gradient(135deg, var(--dark) 0%, var(--primary) 100%);
      color: #fff;
      padding: 2rem 1.75rem 1.65rem;
      text-align: center;
      position: relative;
    }
    .login-logo {
      width: 64px;
      height: 64px;
      border-radius: 18px;
      background: #fff;
      padding: 4px;
      object-fit: cover;
      margin: 0 auto 0.85rem;
      display: block;
      box-shadow: 0 8px 20px rgba(0, 0, 0, 0.18);
    }
    .login-hero h1 { font-size: 1.45rem; font-weight: 800; margin-bottom: 0.25rem; }
    .login-hero p { font-size: 0.9rem; color: #E6EFE9; }
    .login-body { padding: 1.65rem 1.75rem 1.85rem; }
    .password-wrap {
      position: relative;
      display: flex;
      align-items: center;
    }
    .password-wrap .input { padding-left: 4.5rem; }
    .toggle-vis-btn {
      position: absolute;
      left: 0.5rem;
      background: var(--tag-bg);
      color: var(--primary);
      border: none;
      border-radius: 8px;
      padding: 0.25rem 0.6rem;
      font-size: 0.76rem;
      font-weight: 700;
      cursor: pointer;
    }
    .dev-login-box {
      margin-top: 1rem;
      padding: 0.85rem 1rem;
      background: var(--gold-bg);
      border: 1px solid #E5D4B6;
      border-radius: 14px;
      font-size: 0.84rem;
      color: #6B4D1E;
      display: none;
      flex-direction: column;
      gap: 0.55rem;
    }
    .dev-login-box.visible { display: flex; }

    /* Workspace Sidebar & Content Shell */
    .app-shell { display: none; min-height: 100vh; }
    .app-shell.active { display: flex; flex-direction: row; align-items: stretch; }
    .sidebar-backdrop {
      display: none;
      position: fixed;
      inset: 0;
      background: rgba(21, 62, 51, 0.45);
      z-index: 45;
    }
    .sidebar-backdrop.open { display: block; }
    .sidebar {
      width: 278px;
      flex-shrink: 0;
      background: var(--surface);
      border-left: 1px solid var(--border);
      position: sticky;
      top: 0;
      height: 100vh;
      overflow-y: auto;
      display: flex;
      flex-direction: column;
      padding: 1.15rem 0.9rem;
      gap: 0.95rem;
      z-index: 50;
    }
    .sidebar-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 0.65rem;
      padding-bottom: 0.9rem;
      border-bottom: 1px solid var(--border);
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 0.72rem;
      text-decoration: none;
      color: var(--dark);
      min-width: 0;
    }
    .brand-logo {
      width: 42px;
      height: 42px;
      border-radius: 12px;
      object-fit: cover;
      border: 1px solid var(--border);
      box-shadow: 0 2px 6px rgba(21, 62, 51, 0.1);
      flex-shrink: 0;
    }
    .brand-title { font-size: 1.15rem; font-weight: 800; color: var(--primary); line-height: 1.2; }
    .brand-sub { font-size: 0.76rem; color: var(--muted); font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .sidebar-nav {
      display: flex;
      flex-direction: column;
      gap: 0.28rem;
      flex: 1;
    }
    .nav-group-label {
      font-size: 0.72rem;
      font-weight: 800;
      color: var(--muted);
      padding: 0.55rem 0.65rem 0.2rem;
      letter-spacing: 0.01em;
    }
    .tab-btn {
      width: 100%;
      border: 1px solid transparent;
      background: transparent;
      color: var(--dark);
      padding: 0.65rem 0.8rem;
      border-radius: 12px;
      font-weight: 700;
      font-size: 0.9rem;
      cursor: pointer;
      text-align: right;
      transition: all 0.16s;
      display: flex;
      align-items: center;
      gap: 0.68rem;
    }
    .tab-btn:hover { background: var(--bg); border-color: var(--border); transform: translateX(-2px); }
    .tab-btn.active {
      background: var(--primary);
      color: #fff;
      border-color: var(--primary);
      border-right: 4px solid var(--gold);
      box-shadow: 0 6px 14px rgba(32, 92, 74, 0.22);
    }
    .nav-icon {
      width: 28px;
      height: 28px;
      border-radius: 8px;
      background: var(--chip-bg);
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-size: 0.95rem;
      flex-shrink: 0;
    }
    .tab-btn.active .nav-icon { background: rgba(255, 255, 255, 0.18); }
    .nav-meta { display: flex; flex-direction: column; align-items: flex-start; min-width: 0; }
    .nav-sub { font-size: 0.72rem; font-weight: 600; opacity: 0.75; line-height: 1.25; }
    .tab-btn.active .nav-sub { opacity: 0.9; }
    .sidebar-footer {
      margin-top: auto;
      padding-top: 0.85rem;
      border-top: 1px solid var(--border);
      display: flex;
      flex-direction: column;
      gap: 0.5rem;
    }
    .sidebar-badges { display: flex; flex-direction: column; gap: 0.35rem; margin-bottom: 0.25rem; }
    .sidebar-links { display: grid; grid-template-columns: 1fr 1fr; gap: 0.4rem; }
    .workspace-area {
      flex: 1;
      min-width: 0;
      display: flex;
      flex-direction: column;
      min-height: 100vh;
    }
    .workspace-topbar {
      background: rgba(255, 255, 255, 0.94);
      backdrop-filter: blur(8px);
      border-bottom: 1px solid var(--border);
      padding: 0.8rem 1.4rem;
      position: sticky;
      top: 0;
      z-index: 35;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 0.85rem;
      flex-wrap: wrap;
    }
    .topbar-title-wrap { display: flex; align-items: center; gap: 0.75rem; min-width: 0; }
    .topbar-title { font-size: 1.12rem; font-weight: 800; color: var(--dark); line-height: 1.2; }
    .topbar-sub { font-size: 0.8rem; color: var(--muted); font-weight: 600; }
    .sidebar-toggle-btn { display: none; }
    .sidebar-close-btn { display: none; }
    .mobile-bottom-nav { display: none; }

    @media (max-width: 960px) {
      .app-shell.active { flex-direction: column; }
      .sidebar {
        position: fixed;
        top: 0;
        right: 0;
        bottom: 0;
        width: 292px;
        max-width: 86vw;
        height: 100dvh;
        overscroll-behavior: contain;
        transform: translateX(100%);
        transition: transform 0.22s ease;
        box-shadow: -8px 0 32px rgba(21, 62, 51, 0.22);
      }
      .sidebar.open { transform: translateX(0); }
      .sidebar-toggle-btn { display: inline-flex; }
      .sidebar-close-btn { display: inline-flex; }
      .workspace-topbar { padding: 0.68rem 0.95rem; }
      .mobile-bottom-nav {
        display: grid;
        grid-template-columns: repeat(5, minmax(0, 1fr));
        gap: 0.15rem;
        position: fixed;
        bottom: 0;
        left: 0;
        right: 0;
        background: rgba(255, 255, 255, 0.97);
        backdrop-filter: blur(10px);
        border-top: 1px solid var(--border);
        box-shadow: 0 -6px 20px rgba(21, 62, 51, 0.08);
        padding: 0.35rem 0.3rem calc(0.35rem + env(safe-area-inset-bottom));
        z-index: 40;
      }
      .mobile-nav-btn {
        border: none;
        background: transparent;
        color: var(--muted);
        border-radius: 12px;
        padding: 0.32rem 0.2rem;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 0.12rem;
        font-size: 0.67rem;
        font-weight: 700;
        cursor: pointer;
        min-height: 48px;
        transition: background 0.15s, color 0.15s;
      }
      .mobile-nav-btn .mnav-ico { font-size: 1.08rem; line-height: 1.1; }
      .mobile-nav-btn.active {
        background: var(--tip-bg);
        color: var(--primary);
        font-weight: 800;
      }
    }

    main {
      max-width: 1140px;
      width: 100%;
      margin: 1.25rem auto 2.5rem;
      padding: 0 1.35rem;
      flex: 1;
      display: flex;
      flex-direction: column;
      gap: 1.15rem;
      min-width: 0;
    }
    @media (max-width: 960px) {
      main { margin-bottom: 5.25rem; }
    }
    .tab-panel { display: none; flex-direction: column; gap: 1.15rem; }
    .tab-panel.active { display: flex; }

    .banner {
      background: var(--notice-bg);
      border: 1px solid #E5D3B3;
      border-radius: 14px;
      padding: 0.85rem 1.1rem;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 0.85rem;
      flex-wrap: wrap;
      font-size: 0.88rem;
      color: #6B4D1E;
    }
    .banner-info { background: var(--tip-bg); border-color: var(--chip-border); color: var(--dark); }
    .banner-success { background: var(--success-bg); border-color: #B7E1C8; color: var(--dark); }
    .panel {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 18px;
      padding: 1.25rem;
      box-shadow: var(--shadow);
    }
    .panel-title {
      font-size: 1.08rem;
      font-weight: 800;
      color: var(--dark);
      margin-bottom: 0.25rem;
    }
    .panel-sub { font-size: 0.85rem; color: var(--muted); margin-bottom: 1rem; }

    /* Stats & Grid */
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(170px, 1fr));
      gap: 0.85rem;
    }
    .stat-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 0.95rem 1.1rem;
      box-shadow: var(--shadow);
      cursor: pointer;
      transition: border-color 0.15s, transform 0.15s;
      text-align: right;
    }
    .stat-card:hover { border-color: var(--primary); transform: translateY(-1px); }
    .stat-card.active { border-color: var(--primary); background: var(--tip-bg); }
    .stat-label { color: var(--muted); font-size: 0.82rem; font-weight: 700; }
    .stat-value { font-size: 1.58rem; font-weight: 800; color: var(--primary); line-height: 1.25; margin-top: 0.15rem; }
    .stat-meta { font-size: 0.76rem; color: var(--muted); margin-top: 0.15rem; }

    .filters-grid {
      display: grid;
      grid-template-columns: 2fr repeat(4, minmax(125px, 1fr)) auto auto;
      gap: 0.65rem;
      align-items: center;
    }
    .filters-grid-activities {
      grid-template-columns: 2fr 1fr 1fr 1fr auto;
    }
    @media (max-width: 1020px) {
      .filters-grid, .filters-grid-activities { grid-template-columns: repeat(2, minmax(0, 1fr)); }
      .filters-grid .search-wrap { grid-column: 1 / -1; }
      .filters-grid .filter-reset-btn { grid-column: 1 / -1; }
    }
    .two-col { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 1.15rem; align-items: start; }
    .two-col > * { min-width: 0; }
    .lic-issue-grid { grid-template-columns: minmax(0, 1.12fr) minmax(0, 0.88fr); }
    .lic-output-panel { position: sticky; top: 4.5rem; }
    .lic-filter-bar { display: flex; gap: 0.5rem; align-items: center; flex-wrap: wrap; }
    .lic-filter-bar .input { width: 220px; }
    .lic-filter-bar .select { width: 140px; }
    @media (max-width: 900px) {
      .two-col, .lic-issue-grid { grid-template-columns: minmax(0, 1fr); gap: 0.9rem; }
      .lic-output-panel { position: static; }
    }

    .list-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 0.75rem;
      margin-bottom: 0.85rem;
    }
    .meta-pills { display: flex; align-items: center; gap: 0.45rem; flex-wrap: wrap; }
    .questions-list { display: flex; flex-direction: column; gap: 0.85rem; }
    .item-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 1rem 1.15rem;
      box-shadow: 0 2px 10px rgba(21, 62, 51, 0.03);
      display: flex;
      flex-direction: column;
      gap: 0.58rem;
      transition: border-color 0.15s, background 0.15s, box-shadow 0.15s;
    }
    .item-card:hover { border-color: #C3D5C9; box-shadow: 0 6px 18px rgba(21, 62, 51, 0.06); }
    .item-card.status-approved { border-right: 4px solid var(--primary); }
    .item-card.status-draft { border-right: 4px solid var(--gold); }
    .item-card.is-selected { background: #F3FBF5; border-color: var(--primary); }
    .pill-copy { cursor: pointer; transition: background 0.14s; }
    .pill-copy:hover { background: #DEE7E0; }
    .seg-bar {
      display: inline-flex;
      background: var(--bg);
      border: 1px solid var(--border);
      border-radius: 999px;
      padding: 0.18rem;
      gap: 0.2rem;
    }
    .seg-btn {
      border: none;
      background: transparent;
      color: var(--muted);
      padding: 0.32rem 0.72rem;
      border-radius: 999px;
      font-size: 0.8rem;
      font-weight: 700;
      cursor: pointer;
      white-space: nowrap;
      transition: all 0.14s;
    }
    .seg-btn:hover { color: var(--dark); }
    .seg-btn.active { background: var(--surface); color: var(--primary); box-shadow: 0 1px 4px rgba(21,62,51,0.1); }
    .bulk-bar {
      background: var(--tip-bg);
      border: 1px solid var(--chip-border);
      border-radius: 14px;
      padding: 0.7rem 0.95rem;
      display: none;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 0.65rem;
      margin-bottom: 0.85rem;
    }
    .bulk-bar.visible { display: flex; }
    .q-table-wrap {
      overflow-x: auto;
      border: 1px solid var(--border);
      border-radius: 14px;
      background: var(--surface);
    }
    .q-table {
      width: 100%;
      border-collapse: collapse;
      font-size: 0.88rem;
      text-align: right;
    }
    .q-table th {
      background: #F5F8F6;
      color: var(--muted);
      font-weight: 800;
      font-size: 0.78rem;
      padding: 0.7rem 0.75rem;
      border-bottom: 1px solid var(--border);
      white-space: nowrap;
    }
    .q-table td {
      padding: 0.72rem 0.75rem;
      border-bottom: 1px solid #EEF2EF;
      vertical-align: top;
    }
    .q-table tr:last-child td { border-bottom: none; }
    .q-table tr:hover td { background: #FAFDFB; }
    .q-table tr.is-selected td { background: #F1FAF4; }
    .q-check { width: 17px; height: 17px; accent-color: var(--primary); cursor: pointer; flex-shrink: 0; }
    .q-index { font-size: 0.76rem; font-weight: 800; color: var(--muted); }
    .item-top {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 0.75rem;
      flex-wrap: wrap;
    }
    .item-actions { display: flex; gap: 0.42rem; flex-wrap: wrap; }
    .question-text { font-size: 1.06rem; font-weight: 700; color: var(--dark); }
    .question-clarification {
      font-size: 0.9rem;
      color: var(--muted);
      background: var(--bg);
      border-right: 3px solid var(--gold);
      padding: 0.45rem 0.8rem;
      border-radius: 8px;
    }
    .pagination {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 1rem;
      flex-wrap: wrap;
      padding-top: 0.9rem;
      margin-top: 0.5rem;
      border-top: 1px solid var(--border);
    }
    .empty-state { text-align: center; padding: 2.5rem 1rem; color: var(--muted); }

    /* Dynamic Array Builders & Code Output */
    .array-list { display: flex; flex-direction: column; gap: 0.5rem; margin-bottom: 0.5rem; }
    .array-row { display: flex; gap: 0.45rem; align-items: center; }
    .code-output {
      background: #142A23;
      color: #EBF5EF;
      border-radius: 14px;
      padding: 0.95rem 1rem;
      font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
      font-size: 0.8rem;
      direction: ltr;
      word-break: break-word;
      overflow-wrap: anywhere;
      max-width: 100%;
      line-height: 1.5;
      max-height: 150px;
      overflow-y: auto;
    }
    .preset-row { display: flex; flex-wrap: wrap; gap: 0.45rem; margin-bottom: 0.9rem; }
    .switch-card {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 0.75rem;
      padding: 0.78rem 0.92rem;
      background: var(--bg);
      border: 1px solid var(--border);
      border-radius: 13px;
      margin-bottom: 0.6rem;
    }
    .switch-card > div { min-width: 0; flex: 1; }
    .switch-card strong { display: block; font-size: 0.9rem; line-height: 1.35; }
    .switch-card span { display: block; font-size: 0.77rem; color: var(--muted); line-height: 1.4; margin-top: 0.1rem; }
    .switch-card input[type="checkbox"] {
      appearance: none;
      -webkit-appearance: none;
      width: 46px;
      height: 26px;
      border-radius: 999px;
      background: #CBD6CE;
      position: relative;
      cursor: pointer;
      flex-shrink: 0;
      transition: background 0.18s ease;
    }
    .switch-card input[type="checkbox"]::after {
      content: '';
      position: absolute;
      top: 3px;
      left: 3px;
      width: 20px;
      height: 20px;
      border-radius: 50%;
      background: #FFFFFF;
      box-shadow: 0 2px 5px rgba(21, 62, 51, 0.22);
      transition: transform 0.18s ease;
    }
    .switch-card input[type="checkbox"]:checked { background: var(--primary); }
    .switch-card input[type="checkbox"]:checked::after { transform: translateX(20px); }

    /* Modals */
    .modal-backdrop {
      position: fixed;
      inset: 0;
      background: rgba(21, 62, 51, 0.48);
      display: none;
      align-items: center;
      justify-content: center;
      padding: 1rem;
      z-index: 100;
    }
    .modal-backdrop.open { display: flex; }
    .modal {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 22px;
      max-width: 650px;
      width: 100%;
      max-height: 92vh;
      overflow-y: auto;
      padding: 1.5rem;
      box-shadow: 0 24px 55px rgba(21, 62, 51, 0.22);
    }
    .modal-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1rem;
      padding-bottom: 0.75rem;
      border-bottom: 1px solid var(--border);
    }
    .modal-title { font-size: 1.18rem; font-weight: 800; color: var(--dark); }
    .modal-footer {
      display: flex;
      justify-content: flex-end;
      gap: 0.6rem;
      margin-top: 1.15rem;
      padding-top: 0.9rem;
      border-top: 1px solid var(--border);
    }

    .toast {
      position: fixed;
      bottom: 1.25rem;
      left: 1.25rem;
      background: var(--dark);
      color: #fff;
      padding: 0.75rem 1.2rem;
      border-radius: 12px;
      font-weight: 700;
      font-size: 0.88rem;
      box-shadow: 0 10px 26px rgba(21, 62, 51, 0.28);
      opacity: 0;
      pointer-events: none;
      transform: translateY(10px);
      transition: opacity 0.2s, transform 0.2s;
      z-index: 160;
    }
    .toast.show { opacity: 1; transform: translateY(0); }

    .cms-studio {
      display: grid;
      grid-template-columns: 264px minmax(0, 1fr);
      gap: 1.1rem;
      align-items: start;
    }
    .cms-studio > * { min-width: 0; max-width: 100%; }
    @media (max-width: 980px) {
      .cms-studio { grid-template-columns: minmax(0, 1fr); gap: 0.85rem; }
    }
    .cms-side-menu {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 18px;
      padding: 0.8rem;
      box-shadow: var(--shadow);
      position: sticky;
      top: 4.5rem;
      display: flex;
      flex-direction: column;
      gap: 0.35rem;
      min-width: 0;
      max-width: 100%;
    }
    .cms-side-scroll {
      display: flex;
      flex-direction: column;
      gap: 0.35rem;
      min-width: 0;
    }
    .studio-bottom-save {
      margin-top: 1.15rem;
      padding-top: 1rem;
      border-top: 1px solid var(--border);
    }
    @media (max-width: 980px) {
      .cms-side-menu {
        position: static;
        padding: 0.72rem;
        gap: 0.55rem;
      }
      .cms-side-scroll {
        flex-direction: row;
        overflow-x: auto;
        scrollbar-width: none;
        padding-bottom: 0.1rem;
        gap: 0.45rem;
        -webkit-overflow-scrolling: touch;
      }
      .cms-side-scroll::-webkit-scrollbar { display: none; }
      .cms-side-scroll .cms-side-btn {
        flex: 0 0 auto;
        width: auto;
        padding: 0.44rem 0.72rem;
        border-radius: 999px;
        border-color: var(--border);
        background: var(--bg);
      }
      .cms-side-scroll .cms-side-btn.active {
        border-right-width: 1px;
        background: var(--primary);
        border-color: var(--primary);
        color: #fff;
      }
      .cms-side-scroll .cms-side-btn.active .cms-side-num {
        background: rgba(255, 255, 255, 0.22);
        color: #fff;
      }
      .cms-side-scroll .cms-side-sub { display: none; }
      .cms-side-footer {
        margin-top: 0;
        padding-top: 0.5rem;
      }
      .cms-side-footer .studio-top-submit { display: none; }
      .cms-side-footer.app-config-side-footer { display: none; }
      .studio-bottom-save {
        position: sticky;
        bottom: calc(3.85rem + env(safe-area-inset-bottom));
        background: rgba(255, 255, 255, 0.97);
        backdrop-filter: blur(8px);
        padding: 0.7rem 0.85rem;
        margin: 0.9rem -0.78rem -0.88rem;
        border-radius: 0 0 16px 16px;
        box-shadow: 0 -8px 20px rgba(21, 62, 51, 0.08);
        z-index: 25;
      }
    }
    .cms-side-label {
      font-size: 0.74rem;
      font-weight: 800;
      color: var(--muted);
      padding: 0.25rem 0.45rem 0.35rem;
    }
    .cms-side-btn {
      width: 100%;
      border: 1px solid transparent;
      background: transparent;
      color: var(--dark);
      padding: 0.6rem 0.65rem;
      border-radius: 12px;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 0.6rem;
      text-align: right;
      transition: all 0.15s;
    }
    .cms-side-btn:hover { background: var(--bg); border-color: var(--border); }
    .cms-side-btn.active {
      background: var(--tip-bg);
      border-color: var(--primary);
      border-right: 4px solid var(--gold);
      color: var(--primary);
    }
    .cms-side-num {
      width: 24px;
      height: 24px;
      border-radius: 8px;
      background: var(--chip-bg);
      color: var(--primary);
      font-size: 0.78rem;
      font-weight: 800;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }
    .cms-side-btn.active .cms-side-num {
      background: var(--primary);
      color: #fff;
    }
    .cms-side-meta { display: flex; flex-direction: column; min-width: 0; flex: 1; }
    .cms-side-title { font-size: 0.86rem; font-weight: 800; line-height: 1.25; }
    .cms-side-sub { font-size: 0.72rem; color: var(--muted); font-weight: 600; }
    .cms-side-footer {
      margin-top: 0.45rem;
      padding-top: 0.7rem;
      border-top: 1px solid var(--border);
      display: flex;
      flex-direction: column;
      gap: 0.45rem;
    }
    .cms-pane { display: none; }
    .cms-pane.active { display: block; }
    .cms-pane-head {
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 0.75rem;
      padding-bottom: 0.9rem;
      margin-bottom: 1rem;
      border-bottom: 1px solid var(--border);
    }
    .cms-card-item {
      background: var(--bg);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 0.85rem 0.95rem;
      margin-bottom: 0.65rem;
      display: flex;
      flex-direction: column;
      gap: 0.55rem;
    }
    .cms-card-head {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 0.5rem;
      flex-wrap: wrap;
    }
    .cms-section-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(min(270px, 100%), 1fr));
      gap: 0.85rem;
    }
    .cms-section-box {
      background: var(--bg);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 0.9rem;
    }

    /* Wefaq Shimmer Loading */
    @keyframes wefaqShimmer {
      0% { background-position: 200% 0; }
      100% { background-position: -200% 0; }
    }
    .shimmer-block {
      background: linear-gradient(105deg, #EDEAE1 20%, #FBF9F4 48%, #E5EFE9 68%, #EDEAE1 85%);
      background-size: 200% 100%;
      animation: wefaqShimmer 1.3s ease-in-out infinite;
      border-radius: 10px;
    }
    .shimmer-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 1.1rem 1.2rem;
      display: flex;
      flex-direction: column;
      gap: 0.65rem;
    }
    .shimmer-stat {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 0.95rem 1.1rem;
      display: flex;
      flex-direction: column;
      gap: 0.5rem;
    }
    .shimmer-line { height: 14px; width: 100%; }
    .shimmer-line.short { width: 42%; height: 11px; }
    .shimmer-line.med { width: 72%; height: 15px; }
    .shimmer-line.num { width: 48%; height: 26px; border-radius: 8px; }
    .shimmer-pills { display: flex; gap: 0.45rem; flex-wrap: wrap; }
    .shimmer-pill { width: 82px; height: 22px; border-radius: 999px; }

    .boot-shell { display: none; min-height: 100vh; }
    .boot-shell.active { display: flex; flex-direction: row; align-items: stretch; }
    .boot-sidebar {
      width: 278px;
      flex-shrink: 0;
      background: var(--surface);
      border-left: 1px solid var(--border);
      padding: 1.25rem 0.95rem;
      display: flex;
      flex-direction: column;
      gap: 0.75rem;
    }
    @media (max-width: 960px) { .boot-sidebar { display: none; } }

    footer {
      text-align: center;
      color: var(--muted);
      font-size: 0.82rem;
      padding: 1.25rem 1rem;
      border-top: 1px solid var(--border);
      background: var(--surface);
    }
    @media (max-width: 960px) {
      footer { padding-bottom: calc(5.2rem + env(safe-area-inset-bottom)); }
    }
    @media (max-width: 680px) {
      main { padding: 0 0.65rem; margin: 0.8rem auto 5.2rem; gap: 0.78rem; }
      .panel { padding: 0.88rem 0.78rem; border-radius: 16px; }
      .form-box { padding: 0.78rem 0.72rem; border-radius: 13px; margin-bottom: 0.78rem; }
      .form-group { margin-bottom: 0.82rem; }
      .input, .select, .textarea { font-size: 16px; min-height: 44px; padding: 0.58rem 0.82rem; }
      .btn { min-height: 40px; }
      .btn-sm { min-height: 36px; padding: 0.36rem 0.72rem; }
      .topbar-sub { display: none; }
      .topbar-title { font-size: 1rem; }
      .workspace-topbar { gap: 0.5rem; }
      .stats-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 0.58rem; }
      .stat-card { padding: 0.75rem 0.8rem; border-radius: 14px; }
      .stat-value { font-size: 1.32rem; }
      .stat-label { font-size: 0.78rem; }
      .cms-pane-head { flex-direction: column; align-items: stretch; gap: 0.55rem; padding-bottom: 0.72rem; margin-bottom: 0.82rem; }
      .cms-pane-head .meta-pills { display: grid; grid-template-columns: 1fr 1fr; gap: 0.45rem; }
      .cms-pane-head > .btn { width: 100%; }
      #cmsSampleTopicTabs {
        flex-wrap: nowrap;
        overflow-x: auto;
        scrollbar-width: none;
        max-width: 100%;
        padding-bottom: 0.15rem;
      }
      #cmsSampleTopicTabs::-webkit-scrollbar { display: none; }
      #cmsSampleTopicTabs .btn { flex-shrink: 0; }
      .list-header { gap: 0.55rem; margin-bottom: 0.72rem; }
      .item-card { padding: 0.88rem 0.82rem; border-radius: 14px; }
      .item-top { gap: 0.55rem; }
      .question-text { font-size: 0.98rem; }
      .seg-bar { max-width: 100%; overflow-x: auto; scrollbar-width: none; }
      .seg-bar::-webkit-scrollbar { display: none; }
      .array-row { flex-wrap: nowrap; gap: 0.35rem; }
      .array-row .input { flex: 1 1 0; min-width: 0; }
      .array-row .btn { flex-shrink: 0; padding-inline: 0.62rem; }
      .cms-card-item { padding: 0.72rem; }
      .cms-card-item .array-row input[data-field="icon"] { flex: 0 0 56px; width: 56px; text-align: center; }
      .lic-filter-bar { width: 100%; }
      .lic-filter-bar .input { flex: 1 1 160px; width: auto; }
      .lic-filter-bar .select { flex: 1 1 120px; width: auto; }
      .bulk-bar { flex-direction: column; align-items: stretch; }
      .bulk-bar .meta-pills:last-child { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 0.4rem; }
      .modal-backdrop { align-items: flex-end; padding: 0; }
      .modal {
        border-radius: 22px 22px 0 0;
        max-height: 92dvh;
        padding: 1.15rem 1rem calc(1.15rem + env(safe-area-inset-bottom));
      }
      .modal-footer { gap: 0.5rem; }
      .modal-footer .btn { flex: 1; }
      .toast {
        bottom: calc(4.8rem + env(safe-area-inset-bottom));
        left: 0.85rem;
        right: 0.85rem;
        text-align: center;
      }
      .login-shell { padding: 0.9rem; }
      .login-hero { padding: 1.45rem 1.25rem 1.3rem; }
      .login-body { padding: 1.25rem; }
    }
  </style>
</head>
<body>
  <!-- Boot Shimmer Shell (shown while checking session cookie) -->
  <div class="boot-shell active" id="bootShell" aria-label="جاري تحميل لوحة الإدارة">
    <aside class="boot-sidebar">
      <div style="display:flex;align-items:center;gap:0.7rem;padding-bottom:0.85rem;border-bottom:1px solid var(--border);">
        <div class="shimmer-block" style="width:42px;height:42px;border-radius:12px;"></div>
        <div style="flex:1;display:flex;flex-direction:column;gap:0.35rem;">
          <div class="shimmer-block shimmer-line med"></div>
          <div class="shimmer-block shimmer-line short"></div>
        </div>
      </div>
      <div class="shimmer-block" style="height:44px;border-radius:12px;"></div>
      <div class="shimmer-block" style="height:44px;border-radius:12px;"></div>
      <div class="shimmer-block" style="height:44px;border-radius:12px;"></div>
      <div class="shimmer-block" style="height:44px;border-radius:12px;"></div>
      <div class="shimmer-block" style="height:44px;border-radius:12px;"></div>
    </aside>
    <div class="workspace-area">
      <div class="workspace-topbar">
        <div style="display:flex;flex-direction:column;gap:0.4rem;flex:1;min-width:0;max-width:240px;">
          <div class="shimmer-block shimmer-line med"></div>
          <div class="shimmer-block shimmer-line"></div>
        </div>
        <div class="shimmer-block" style="width:110px;height:34px;border-radius:999px;"></div>
      </div>
      <main>
        <div class="stats-grid">
          <div class="shimmer-stat"><div class="shimmer-block shimmer-line short"></div><div class="shimmer-block shimmer-line num"></div></div>
          <div class="shimmer-stat"><div class="shimmer-block shimmer-line short"></div><div class="shimmer-block shimmer-line num"></div></div>
          <div class="shimmer-stat"><div class="shimmer-block shimmer-line short"></div><div class="shimmer-block shimmer-line num"></div></div>
          <div class="shimmer-stat"><div class="shimmer-block shimmer-line short"></div><div class="shimmer-block shimmer-line num"></div></div>
        </div>
        <div class="shimmer-card">
          <div class="shimmer-pills"><div class="shimmer-block shimmer-pill"></div><div class="shimmer-block shimmer-pill"></div></div>
          <div class="shimmer-block shimmer-line med"></div>
          <div class="shimmer-block shimmer-line"></div>
        </div>
        <div class="shimmer-card">
          <div class="shimmer-pills"><div class="shimmer-block shimmer-pill"></div><div class="shimmer-block shimmer-pill"></div></div>
          <div class="shimmer-block shimmer-line med"></div>
          <div class="shimmer-block shimmer-line"></div>
        </div>
      </main>
    </div>
  </div>

  <!-- Sign-In Gate -->
  <section class="login-shell" id="loginShell">
    <div class="login-card">
      <div class="login-hero">
        <img src="/logo.png" alt="شعار وفاق" class="login-logo">
        <h1>لوحة إدارة وفاق</h1>
        <p>سجّل الدخول لإدارة الأسئلة، الأنشطة، التطبيق، وأكواد التفعيل</p>
      </div>
      <div class="login-body">
        <div class="form-error" id="loginError"></div>
        <form id="loginForm">
          <div class="form-group">
            <label class="form-label" for="loginUsername">اسم المستخدم</label>
            <input type="text" id="loginUsername" class="input" dir="ltr" value="admin" autocomplete="username" required>
          </div>
          <div class="form-group">
            <label class="form-label" for="loginPassword">كلمة المرور أو رمز الإدارة</label>
            <div class="password-wrap">
              <input type="password" id="loginPassword" class="input" dir="ltr" autocomplete="current-password" placeholder="••••••••••••">
              <button type="button" class="toggle-vis-btn" id="toggleLoginVisBtn">إظهار</button>
            </div>
            <div class="form-hint">تُحفظ الجلسة عبر ملف تعريف ارتباط آمن (HttpOnly) بدون تخزين في المتصفح.</div>
          </div>
          <button type="submit" class="btn btn-primary btn-block" id="loginSubmitBtn">تسجيل الدخول</button>
        </form>
        <div class="dev-login-box" id="devLoginBox">
          <div><strong>وضع التطوير المحلي:</strong> لم يتم ضبط متغير <code>ADMIN_API_TOKEN</code> أو <code>ADMIN_PASSWORD</code> بعد.</div>
          <button type="button" class="btn btn-gold btn-sm" id="devQuickLoginBtn">دخول سريع للتطوير المحلي</button>
        </div>
      </div>
    </div>
  </section>

  <!-- Authenticated Admin Workspace -->
  <div class="app-shell" id="appShell">
    <div class="sidebar-backdrop" id="sidebarBackdrop"></div>
    <aside class="sidebar" id="sidebarNav" aria-label="القائمة الجانبية">
      <div class="sidebar-header">
        <a href="/dashboard" class="brand">
          <img src="/logo.png" alt="شعار وفاق" class="brand-logo">
          <div style="min-width:0;">
            <div class="brand-title">وفاق · الإدارة</div>
            <div class="brand-sub" id="sessionUserLabel">مرحبًا بك</div>
          </div>
        </a>
        <button type="button" class="btn btn-outline btn-sm sidebar-close-btn" id="sidebarCloseBtn" aria-label="إغلاق القائمة">✕</button>
      </div>

      <nav class="sidebar-nav" aria-label="أقسام الإدارة">
        <div class="nav-group-label">المحتوى والتفاعل</div>
        <button type="button" class="tab-btn active" data-tab="questions">
          <span class="nav-icon">💬</span>
          <span class="nav-meta"><span>بنك الأسئلة</span><span class="nav-sub">إضافة، استيراد واعتماد</span></span>
        </button>
        <button type="button" class="tab-btn" data-tab="activities">
          <span class="nav-icon">🧩</span>
          <span class="nav-meta"><span>الأنشطة والمواقف</span><span class="nav-sub">سيناريوهات وترتيب أولويات</span></span>
        </button>

        <div class="nav-group-label">الموقع والتطبيق</div>
        <button type="button" class="tab-btn" data-tab="siteCms">
          <span class="nav-icon">🎨</span>
          <span class="nav-meta"><span>محتوى الموقع (CMS)</span><span class="nav-sub">الواجهة، المميزات والأسئلة</span></span>
        </button>
        <button type="button" class="tab-btn" data-tab="appConfig">
          <span class="nav-icon">📞</span>
          <span class="nav-meta"><span>التطبيق وقنوات التواصل</span><span class="nav-sub">واتساب، إشعارات وإصدارات</span></span>
        </button>

        <div class="nav-group-label">التراخيص والأمان</div>
        <button type="button" class="tab-btn" data-tab="licenses">
          <span class="nav-icon">🗝️</span>
          <span class="nav-meta"><span>أكواد التفعيل والمفاتيح</span><span class="nav-sub">توقيع Ed25519 والأجهزة</span></span>
        </button>
      </nav>

      <div class="sidebar-footer">
        <div class="sidebar-badges">
          <span class="pill pill-muted" id="revisionBadge">جاري التحميل...</span>
          <span class="pill" id="storageBadge">...</span>
        </div>
        <div class="sidebar-links">
          <a href="/v1/question-catalog" target="_blank" rel="noopener" class="btn btn-outline btn-sm">JSON الكتالوج</a>
          <a href="/v1/questions/export?format=contract" class="btn btn-outline btn-sm">تصدير الأسئلة</a>
        </div>
        <button type="button" class="btn btn-danger btn-sm btn-block" id="logoutBtn">تسجيل الخروج</button>
      </div>
    </aside>

    <div class="workspace-area">
      <header class="workspace-topbar">
        <div class="topbar-title-wrap">
          <button type="button" class="btn btn-outline btn-sm sidebar-toggle-btn" id="sidebarToggleBtn" aria-label="فتح القائمة الجانبية">☰ الأقسام</button>
          <div>
            <div class="topbar-title" id="activeTabHeading">بنك الأسئلة</div>
            <div class="topbar-sub" id="activeTabSub">إدارة الأسئلة الفردية واستيراد الدفعات والمراجعة قبل النشر</div>
          </div>
        </div>
        <div class="meta-pills">
          <a href="https://wefaq-site.vercel.app" target="_blank" rel="noopener" id="headerSiteLink" class="btn btn-gold btn-sm">🌐 عرض الموقع</a>
        </div>
      </header>

      <main>
      <div class="banner" id="noticeBanner" style="display:none;">
        <div id="noticeText"></div>
        <div class="meta-pills">
          <a href="/v1/questions/export?format=asset" class="btn btn-outline btn-sm">تنزيل questions_v1.json</a>
        </div>
      </div>

      <!-- TAB 1: Questions Bank -->
      <section class="tab-panel active" id="tab-questions">
        <div class="stats-grid" id="statsGrid"></div>

        <div class="panel">
          <div class="list-header" style="margin-bottom:0.85rem;">
            <div>
              <div class="panel-title">تصفية وإضافة الأسئلة</div>
              <div class="panel-sub" style="margin-bottom:0;">إدارة الأسئلة الفردية أو استيراد مجموعة أسئلة دفعة واحدة</div>
            </div>
            <div class="meta-pills">
              <button type="button" class="btn btn-gold btn-sm" id="bulkImportBtn">+ استيراد دفعة أسئلة</button>
              <button type="button" class="btn btn-primary btn-sm" id="addQuestionBtn">+ إضافة سؤال</button>
            </div>
          </div>

          <div class="filters-grid">
            <div class="search-wrap">
              <input type="search" id="searchInput" class="input" placeholder="ابحث بنص السؤال، التوضيح، أو المعرف...">
            </div>
            <select id="topicFilter" class="select">
              <option value="">كل المجالات</option>
              <option value="communication">التواصل وإدارة الخلافات</option>
              <option value="dailyLife">الحياة اليومية والمسؤوليات</option>
              <option value="familyRelations">الأهل والحدود الأسرية</option>
              <option value="finances">المالية والتطلعات المشتركة</option>
              <option value="coreValues">القيم والمبادئ والتربية</option>
            </select>
            <select id="depthFilter" class="select">
              <option value="">كل المستويات</option>
              <option value="introductory">تمهيدي</option>
              <option value="deeper">أعمق</option>
            </select>
            <select id="modeFilter" class="select">
              <option value="">كل الأوضاع</option>
              <option value="together">معًا</option>
              <option value="phone">مكالمة هاتفية</option>
            </select>
            <select id="devFilter" class="select">
              <option value="">كل الحالات</option>
              <option value="true">مسودة تطوير</option>
              <option value="false">معتمد للنشر</option>
            </select>
            <select id="limitFilter" class="select" aria-label="عدد النتائج بالصفحة">
              <option value="25">25 / صفحة</option>
              <option value="50">50 / صفحة</option>
              <option value="100">100 / صفحة</option>
            </select>
            <button type="button" id="resetFiltersBtn" class="btn btn-outline filter-reset-btn">إعادة ضبط</button>
          </div>
        </div>

        <div class="panel">
          <div class="list-header">
            <div class="meta-pills">
              <label style="display:inline-flex;align-items:center;gap:0.45rem;cursor:pointer;">
                <input type="checkbox" id="selectPageCheckbox" class="q-check" title="تحديد أسئلة هذه الصفحة">
                <span style="font-weight:800;font-size:1.04rem;">قائمة الأسئلة</span>
              </label>
              <span class="pill pill-muted" id="filteredCountBadge">0 سؤال</span>
              <div class="seg-bar" role="group" aria-label="تصفية حسب الحالة">
                <button type="button" class="seg-btn active" data-dev-tab="">الكل</button>
                <button type="button" class="seg-btn" data-dev-tab="false">معتمد للنشر</button>
                <button type="button" class="seg-btn" data-dev-tab="true">مسودة تطوير</button>
              </div>
            </div>
            <div class="meta-pills">
              <button type="button" class="btn btn-gold btn-sm" id="approveFilteredBtn" style="display:none;">✓ اعتماد كل مسودات التصفية</button>
              <div class="seg-bar" role="group" aria-label="طريقة العرض">
                <button type="button" class="seg-btn active" data-view-mode="cards">بطاقات</button>
                <button type="button" class="seg-btn" data-view-mode="table">جدول</button>
              </div>
            </div>
          </div>

          <div class="bulk-bar" id="bulkSelectionBar">
            <div class="meta-pills">
              <strong id="bulkSelectedCount" style="font-size:0.9rem;color:var(--dark);">تم تحديد 0</strong>
            </div>
            <div class="meta-pills">
              <button type="button" class="btn btn-primary btn-sm" id="bulkApproveSelectedBtn">اعتماد المحدد</button>
              <button type="button" class="btn btn-gold btn-sm" id="bulkDraftSelectedBtn">تحويل لمسودة</button>
              <button type="button" class="btn btn-danger btn-sm" id="bulkDeleteSelectedBtn">حذف المحدد</button>
              <button type="button" class="btn btn-outline btn-sm" id="bulkClearSelectionBtn">إلغاء التحديد</button>
            </div>
          </div>

          <div class="questions-list" id="questionsList">
            <div class="shimmer-card"><div class="shimmer-pills"><div class="shimmer-block shimmer-pill"></div><div class="shimmer-block shimmer-pill"></div></div><div class="shimmer-block shimmer-line med"></div><div class="shimmer-block shimmer-line short"></div></div>
            <div class="shimmer-card"><div class="shimmer-pills"><div class="shimmer-block shimmer-pill"></div><div class="shimmer-block shimmer-pill"></div></div><div class="shimmer-block shimmer-line med"></div><div class="shimmer-block shimmer-line short"></div></div>
          </div>
          <div class="pagination" id="paginationBar">
            <button type="button" class="btn btn-outline btn-sm" id="prevPageBtn">السابق</button>
            <span id="pageIndicator" style="font-size:0.88rem;color:var(--muted);font-weight:600;"></span>
            <button type="button" class="btn btn-outline btn-sm" id="nextPageBtn">التالي</button>
          </div>
        </div>
      </section>

      <!-- TAB 2: Activities & Scenarios -->
      <section class="tab-panel" id="tab-activities">
        <div class="stats-grid" id="activitiesStatsGrid"></div>

        <div class="panel">
          <div class="list-header" style="margin-bottom:0.85rem;">
            <div>
              <div class="panel-title">إدارة الأنشطة والمواقف الحوارية</div>
              <div class="panel-sub" style="margin-bottom:0;">أضف بطاقات «لو حصل كده؟» وتمارين «رتّب أولوياتك» وتزامنها مع التطبيق</div>
            </div>
            <div class="meta-pills">
              <a href="/v1/activities/export" class="btn btn-outline btn-sm">تصدير الأنشطة JSON</a>
              <button type="button" class="btn btn-primary btn-sm" id="addActivityBtn">+ إضافة نشاط جديد</button>
            </div>
          </div>

          <div class="filters-grid filters-grid-activities">
            <div class="search-wrap">
              <input type="search" id="actSearchInput" class="input" placeholder="ابحث في العنوان أو الموقف أو المحاور...">
            </div>
            <select id="actTypeFilter" class="select">
              <option value="">كل الأنواع</option>
              <option value="scenario">سيناريو للنقاش</option>
              <option value="priorityOrdering">ترتيب أولويات</option>
            </select>
            <select id="actTopicFilter" class="select">
              <option value="">كل المجالات</option>
              <option value="communication">التواصل وإدارة الخلافات</option>
              <option value="dailyLife">الحياة اليومية والمسؤوليات</option>
              <option value="familyRelations">الأهل والحدود الأسرية</option>
              <option value="finances">المالية والتطلعات المشتركة</option>
              <option value="coreValues">القيم والمبادئ والتربية</option>
            </select>
            <select id="actDevFilter" class="select">
              <option value="">كل الحالات</option>
              <option value="true">مسودة تطوير</option>
              <option value="false">معتمد للنشر</option>
            </select>
            <button type="button" id="resetActFiltersBtn" class="btn btn-outline filter-reset-btn">إعادة ضبط</button>
          </div>
        </div>

        <div class="panel">
          <div class="list-header">
            <div class="meta-pills">
              <span style="font-weight:800;font-size:1.04rem;">الأنشطة المتاحة</span>
              <span class="pill pill-muted" id="activitiesCountBadge">0 نشاط</span>
            </div>
          </div>
          <div class="questions-list" id="activitiesList">
            <div class="shimmer-card"><div class="shimmer-pills"><div class="shimmer-block shimmer-pill"></div><div class="shimmer-block shimmer-pill"></div></div><div class="shimmer-block shimmer-line med"></div><div class="shimmer-block shimmer-line short"></div></div>
            <div class="shimmer-card"><div class="shimmer-pills"><div class="shimmer-block shimmer-pill"></div><div class="shimmer-block shimmer-pill"></div></div><div class="shimmer-block shimmer-line med"></div><div class="shimmer-block shimmer-line short"></div></div>
          </div>
        </div>
      </section>

      <!-- TAB 3: App & Contact Us Management (Side-Menu Studio) -->
      <section class="tab-panel" id="tab-appConfig">
        <form id="appConfigForm">
          <div class="cms-studio">
            <aside class="cms-side-menu" aria-label="أقسام التطبيق والتواصل">
              <div class="list-header" style="margin-bottom:0.25rem;padding:0 0.3rem;">
                <span class="cms-side-label" style="padding:0;">إدارة التطبيق والتواصل</span>
              </div>

              <div class="cms-side-scroll">
                <button type="button" class="cms-side-btn active" data-app-sec="channels">
                  <span class="cms-side-num">1</span>
                  <span class="cms-side-meta">
                    <span class="cms-side-title">قنوات التواصل المباشر</span>
                    <span class="cms-side-sub">واتساب، تيليجرام، البريد والساعات</span>
                  </span>
                </button>

                <button type="button" class="cms-side-btn" data-app-sec="contactForm">
                  <span class="cms-side-num">2</span>
                  <span class="cms-side-meta">
                    <span class="cms-side-title">نموذج التواصل والرسالة</span>
                    <span class="cms-side-sub">أسباب التواصل والمعاينة الحية</span>
                  </span>
                </button>

                <button type="button" class="cms-side-btn" data-app-sec="banner">
                  <span class="cms-side-num">3</span>
                  <span class="cms-side-meta">
                    <span class="cms-side-title">إشعار التطبيق (Banner)</span>
                    <span class="cms-side-sub">رسالة التنبيه بالرئيسية</span>
                  </span>
                </button>

                <button type="button" class="cms-side-btn" data-app-sec="release">
                  <span class="cms-side-num">4</span>
                  <span class="cms-side-meta">
                    <span class="cms-side-title">ميزات وإصدار التطبيق</span>
                    <span class="cms-side-sub">الأقسام ورابط تنزيل APK</span>
                  </span>
                </button>
              </div>

              <div class="cms-side-footer app-config-side-footer">
                <button type="submit" class="btn btn-primary btn-block studio-top-submit" id="saveAppConfigBtn">حفظ الإعدادات والتواصل</button>
              </div>
            </aside>

            <div class="panel">
              <!-- App Pane 1: Channels -->
              <div class="cms-pane active" id="app-pane-channels">
                <div class="cms-pane-head">
                  <div>
                    <div class="panel-title">1. قنوات التواصل والدعم (بدون دفع)</div>
                    <div class="panel-sub" style="margin-bottom:0;">تظهر تلقائيًا في شاشة الدعم بالتطبيق وقسم «تواصل معنا» بالموقع</div>
                  </div>
                  <button type="button" class="btn btn-outline btn-sm" data-app-next="contactForm">التالي: نموذج التواصل ←</button>
                </div>

                <div class="form-box">
                  <div class="form-box-title">تطبيقات المراسلة المباشرة</div>
                  <div class="form-row">
                    <div class="form-group">
                      <label class="form-label" for="cfgWhatsapp">رقم واتساب الدولي (أرقام فقط)</label>
                      <input type="text" id="cfgWhatsapp" class="input" dir="ltr" placeholder="2010xxxxxxxx">
                      <div class="form-hint">اتركه فارغًا لنسخ الرسالة أو فتح واتساب دون رقم محدد.</div>
                    </div>
                    <div class="form-group">
                      <label class="form-label" for="cfgWhatsappDisplay">عنوان زر واتساب</label>
                      <input type="text" id="cfgWhatsappDisplay" class="input" placeholder="فتح في واتساب">
                    </div>
                  </div>
                  <div class="form-row" style="margin-bottom:0;">
                    <div class="form-group" style="margin-bottom:0;">
                      <label class="form-label" for="cfgTelegramUrl">رابط تيليجرام (HTTPS اختياري)</label>
                      <input type="url" id="cfgTelegramUrl" class="input" dir="ltr" placeholder="https://t.me/wefaq_support">
                    </div>
                    <div class="form-group" style="margin-bottom:0;">
                      <label class="form-label" for="cfgTelegramDisplay">عنوان زر تيليجرام</label>
                      <input type="text" id="cfgTelegramDisplay" class="input" placeholder="تواصل عبر تيليجرام">
                    </div>
                  </div>
                </div>

                <div class="form-box" style="margin-bottom:0;">
                  <div class="form-box-title">معلومات الاتصال والموقع الرسمي</div>
                  <div class="form-row">
                    <div class="form-group">
                      <label class="form-label" for="cfgEmail">بريد الدعم الفني</label>
                      <input type="email" id="cfgEmail" class="input" dir="ltr" placeholder="support@wefaq.app">
                    </div>
                    <div class="form-group">
                      <label class="form-label" for="cfgPhoneDisplay">رقم الهاتف للعرض (اختياري)</label>
                      <input type="text" id="cfgPhoneDisplay" class="input" dir="ltr" placeholder="+20 100 000 0000">
                    </div>
                  </div>
                  <div class="form-row" style="margin-bottom:0;">
                    <div class="form-group" style="margin-bottom:0;">
                      <label class="form-label" for="cfgSupportHours">ساعات العمل</label>
                      <input type="text" id="cfgSupportHours" class="input">
                    </div>
                    <div class="form-group" style="margin-bottom:0;">
                      <label class="form-label" for="cfgWebsiteUrl">رابط الموقع التعريفي (HTTPS)</label>
                      <input type="url" id="cfgWebsiteUrl" class="input" dir="ltr" placeholder="https://wefaq-site.vercel.app">
                    </div>
                  </div>
                </div>
              </div>

              <!-- App Pane 2: Contact Form Builder -->
              <div class="cms-pane" id="app-pane-contactForm">
                <div class="cms-pane-head">
                  <div>
                    <div class="panel-title">2. نموذج التواصل وصياغة الرسالة</div>
                    <div class="panel-sub" style="margin-bottom:0;">تحكم في الخيارات والنصوص الظاهرة للزائر عند مراسلة الفريق</div>
                  </div>
                  <div class="meta-pills">
                    <button type="button" class="btn btn-outline btn-sm" data-app-next="channels">→ السابق</button>
                    <button type="button" class="btn btn-outline btn-sm" data-app-next="banner">التالي: الإشعار ←</button>
                  </div>
                </div>

                <div class="two-col">
                  <div>
                    <div class="form-box">
                      <div class="form-box-title">قائمة «سبب التواصل» بالموقع</div>
                      <div id="cfgReasonsList" class="array-list"></div>
                      <button type="button" class="btn btn-outline btn-sm" id="cfgAddReasonBtn">+ إضافة سبب تواصل</button>
                    </div>
                    <div class="form-box" style="margin-bottom:0;">
                      <div class="form-box-title">تلميحات الحقول وصندوق المعاينة</div>
                      <div class="form-row">
                        <div class="form-group">
                          <label class="form-label" for="cfgNamePlaceholder">تلميح حقل الاسم</label>
                          <input type="text" id="cfgNamePlaceholder" class="input">
                        </div>
                        <div class="form-group">
                          <label class="form-label" for="cfgPreviewHeading">عنوان صندوق المعاينة</label>
                          <input type="text" id="cfgPreviewHeading" class="input">
                        </div>
                      </div>
                      <div class="form-group">
                        <label class="form-label" for="cfgNotesPlaceholder">تلميح حقل التفاصيل</label>
                        <input type="text" id="cfgNotesPlaceholder" class="input">
                      </div>
                      <div class="form-group" style="margin-bottom:0;">
                        <label class="form-label" for="cfgPreviewHint">وصف صندوق معاينة الرسالة</label>
                        <input type="text" id="cfgPreviewHint" class="input">
                      </div>
                    </div>
                  </div>

                  <div>
                    <div class="form-box">
                      <div class="form-box-title">الرسالة الافتراضية وتنويه عدم الدفع</div>
                      <div class="form-group">
                        <label class="form-label" for="cfgContactTemplate">السطر الافتتاحي لرسالة التواصل</label>
                        <textarea id="cfgContactTemplate" class="textarea" style="min-height:74px;"></textarea>
                      </div>
                      <div class="form-group" style="margin-bottom:0;">
                        <label class="form-label" for="cfgSiteNotice">تنويه الشفافية وعدم الدفع</label>
                        <textarea id="cfgSiteNotice" class="textarea" style="min-height:70px;"></textarea>
                      </div>
                    </div>
                    <div class="form-box" style="margin-bottom:0;">
                      <div class="form-box-title">معاينة حية للرسالة المولّدة</div>
                      <div class="code-output" id="cfgContactLivePreview" style="direction:rtl;text-align:right;white-space:pre-line;background:#F3F7F4;color:var(--dark);border:1px solid var(--border);"></div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- App Pane 3: In-App Banner -->
              <div class="cms-pane" id="app-pane-banner">
                <div class="cms-pane-head">
                  <div>
                    <div class="panel-title">3. إشعار مباشر داخل التطبيق (Banner)</div>
                    <div class="panel-sub" style="margin-bottom:0;">يظهر أعلى الصفحة الرئيسية في تطبيق الهاتف عند تفعيله</div>
                  </div>
                  <div class="meta-pills">
                    <button type="button" class="btn btn-outline btn-sm" data-app-next="contactForm">→ السابق</button>
                    <button type="button" class="btn btn-outline btn-sm" data-app-next="release">التالي: الميزات ←</button>
                  </div>
                </div>

                <div class="form-box" style="margin-bottom:0;">
                  <div class="switch-card">
                    <div>
                      <strong>تفعيل الإشعار في التطبيق</strong>
                      <span>يعرض رسالة تنبيه أو إعلان للمستخدمين</span>
                    </div>
                    <input type="checkbox" id="cfgAnnEnabled">
                  </div>
                  <div class="form-row">
                    <div class="form-group">
                      <label class="form-label" for="cfgAnnStyle">نمط الإشعار</label>
                      <select id="cfgAnnStyle" class="select">
                        <option value="info">معلوماتي (أخضر هادئ)</option>
                        <option value="warning">تنبيه (ذهبي)</option>
                        <option value="success">بشارة / تحديث (أخضر)</option>
                      </select>
                    </div>
                    <div class="form-group">
                      <label class="form-label" for="cfgAnnTitle">عنوان مختصر</label>
                      <input type="text" id="cfgAnnTitle" class="input" placeholder="مثال: تحديث جديد للأسئلة">
                    </div>
                  </div>
                  <div class="form-group">
                    <label class="form-label" for="cfgAnnMessage">نص الإشعار</label>
                    <textarea id="cfgAnnMessage" class="textarea" style="min-height:84px;" placeholder="محتوى الإشعار الظاهر في التطبيق..."></textarea>
                  </div>
                  <div id="annPreviewBox" class="banner banner-info" style="display:none;margin-top:0.5rem;">
                    <div><strong id="annPreviewTitle"></strong> <span id="annPreviewMsg"></span></div>
                  </div>
                </div>
              </div>

              <!-- App Pane 4: Features & Release -->
              <div class="cms-pane" id="app-pane-release">
                <div class="cms-pane-head">
                  <div>
                    <div class="panel-title">4. إدارة الميزات وإصدار التطبيق</div>
                    <div class="panel-sub" style="margin-bottom:0;">تفعيل أقسام التطبيق وتحديد أحدث إصدار ورابط التنزيل</div>
                  </div>
                  <button type="button" class="btn btn-outline btn-sm" data-app-next="banner">→ السابق</button>
                </div>

                <div class="two-col">
                  <div class="form-box" style="margin-bottom:0;">
                    <div class="form-box-title">التحكم في ميزات التطبيق</div>
                    <div class="switch-card">
                      <div><strong>ميزة «سؤال سريع»</strong><span>زر اختيار سؤال عشوائي من الرئيسية</span></div>
                      <input type="checkbox" id="cfgFeatSpark" checked>
                    </div>
                    <div class="switch-card">
                      <div><strong>قسم الأنشطة والمواقف</strong><span>لو حصل كده؟ + رتّب أولوياتك</span></div>
                      <input type="checkbox" id="cfgFeatActivities" checked>
                    </div>
                    <div class="switch-card">
                      <div><strong>تمرين استكشاف الأسلوب (DISC)</strong><span>نشاط تأمل شخصي مؤقت</span></div>
                      <input type="checkbox" id="cfgFeatDisc" checked>
                    </div>
                    <div class="switch-card" style="margin-bottom:0;">
                      <div><strong>نموذج الملاحظات والتبليغ</strong><span>حفظ ملاحظات المستخدم محليًا</span></div>
                      <input type="checkbox" id="cfgFeatFeedback" checked>
                    </div>
                  </div>

                  <div class="form-box" style="margin-bottom:0;">
                    <div class="form-box-title">إصدار التطبيق ورابط التحميل</div>
                    <div class="form-row">
                      <div class="form-group">
                        <label class="form-label" for="cfgLatestVer">أحدث إصدار للتطبيق</label>
                        <input type="text" id="cfgLatestVer" class="input" dir="ltr" placeholder="0.1.0+15">
                      </div>
                      <div class="form-group">
                        <label class="form-label" for="cfgMinVer">أقل إصدار مدعوم</label>
                        <input type="text" id="cfgMinVer" class="input" dir="ltr" placeholder="0.1.0+1">
                      </div>
                    </div>
                    <div class="form-group">
                      <label class="form-label" for="cfgDownloadUrl">رابط تنزيل التطبيق (HTTPS اختياري)</label>
                      <input type="url" id="cfgDownloadUrl" class="input" dir="ltr" placeholder="https://github.com/abdo6400/wefaq/releases/latest/download/app-release.apk">
                      <div class="form-hint">الأسهل للتنزيل المباشر: GitHub Releases أو Google Play أو Firebase App Distribution (مخزن Blob الحالي Private).</div>
                    </div>
                    <div class="form-group" style="margin-bottom:0;">
                      <label class="form-label" for="cfgReleaseNotes">ملاحظات الإصدار</label>
                      <textarea id="cfgReleaseNotes" class="textarea" style="min-height:76px;"></textarea>
                    </div>
                  </div>
                </div>
              </div>

              <div class="studio-bottom-save">
                <div class="form-error" id="appConfigError"></div>
                <button type="submit" class="btn btn-primary btn-block" id="saveAppConfigBottomBtn">حفظ جميع إعدادات التطبيق وقنوات التواصل</button>
              </div>
            </div>
          </div>
        </form>
      </section>

      <!-- TAB 4: Complete Branding Website CMS -->
      <section class="tab-panel" id="tab-siteCms">
        <form id="siteCmsForm">
          <div class="cms-studio">
            <!-- CMS Sub-Side Menu -->
            <aside class="cms-side-menu" aria-label="أقسام محتوى الموقع">
              <div class="list-header" style="margin-bottom:0.25rem;padding:0 0.3rem;">
                <span class="cms-side-label" style="padding:0;">أقسام الموقع التعريفي</span>
                <span class="pill pill-muted" id="cmsRevisionBadge" style="font-size:0.72rem;">مراجعة #1</span>
              </div>

              <div class="cms-side-scroll">
                <button type="button" class="cms-side-btn active" data-cms-sec="hero">
                  <span class="cms-side-num">1</span>
                  <span class="cms-side-meta">
                    <span class="cms-side-title">الهوية والواجهة والفوتر</span>
                    <span class="cms-side-sub">العنوان، الشارات ومعاينة التطبيق</span>
                  </span>
                </button>

                <button type="button" class="cms-side-btn" data-cms-sec="sections">
                  <span class="cms-side-num">2</span>
                  <span class="cms-side-meta">
                    <span class="cms-side-title">الأقسام وإظهارها</span>
                    <span class="cms-side-sub">تفعيل وعناوين كل قسم</span>
                  </span>
                </button>

                <button type="button" class="cms-side-btn" data-cms-sec="cards">
                  <span class="cms-side-num">3</span>
                  <span class="cms-side-meta">
                    <span class="cms-side-title">البطاقات والخطوات</span>
                    <span class="cms-side-sub" id="cmsCountCardsSub">المميزات والأنشطة والبدء</span>
                  </span>
                </button>

                <button type="button" class="cms-side-btn" data-cms-sec="samples">
                  <span class="cms-side-num">4</span>
                  <span class="cms-side-meta">
                    <span class="cms-side-title">نماذج الأسئلة بالموقع</span>
                    <span class="cms-side-sub">استيراد وتعديل 5 محاور</span>
                  </span>
                </button>

                <button type="button" class="cms-side-btn" data-cms-sec="faq">
                  <span class="cms-side-num">5</span>
                  <span class="cms-side-meta">
                    <span class="cms-side-title">الأسئلة الشائعة (FAQ)</span>
                    <span class="cms-side-sub" id="cmsCountFaqSub">إدارة الأسئلة والأجوبة</span>
                  </span>
                </button>

                <button type="button" class="cms-side-btn" data-cms-sec="boundaries">
                  <span class="cms-side-num">6</span>
                  <span class="cms-side-meta">
                    <span class="cms-side-title">حدود النظام والخصوصية</span>
                    <span class="cms-side-sub">ما هو وفاق + privacy.html</span>
                  </span>
                </button>
              </div>

              <div class="cms-side-footer">
                <button type="submit" class="btn btn-primary btn-block studio-top-submit" id="saveSiteCmsBtn">حفظ ونشر محتوى الموقع</button>
                <div class="sidebar-links">
                  <a href="https://wefaq-site.vercel.app" target="_blank" rel="noopener" id="cmsOpenSiteLink" class="btn btn-gold btn-sm">فتح الموقع</a>
                  <button type="button" class="btn btn-outline btn-sm" id="cmsReloadBtn">تحديث</button>
                </div>
              </div>
            </aside>

            <!-- Active CMS Editor Panel -->
            <div class="panel">
              <!-- Pane 1: Hero & Branding -->
              <div class="cms-pane active" id="cms-pane-hero">
                <div class="cms-pane-head">
                  <div>
                    <div class="panel-title">1. الهوية والعنوان الرئيسي (Hero) والفوتر</div>
                    <div class="panel-sub" style="margin-bottom:0;">عدّل النصوص الأساسية في أعلى الموقع التعريفي وشاشة المعاينة</div>
                  </div>
                  <button type="button" class="btn btn-outline btn-sm" data-cms-next="sections">التالي: الأقسام ←</button>
                </div>
                <div class="two-col">
                  <div>
                    <div class="form-row">
                      <div class="form-group">
                        <label class="form-label" for="cmsBrandName">اسم العلامة (Navbar / الشعار)</label>
                        <input type="text" id="cmsBrandName" class="input">
                      </div>
                      <div class="form-group">
                        <label class="form-label" for="cfgBrandBadge">الشارة الترحيبية (Hero Badge)</label>
                        <input type="text" id="cfgBrandBadge" class="input">
                      </div>
                    </div>
                    <div class="form-group">
                      <label class="form-label" for="cmsPageTitle">عنوان صفحة المتصفح (Title)</label>
                      <input type="text" id="cmsPageTitle" class="input">
                    </div>
                    <div class="form-group">
                      <label class="form-label" for="cfgBrandTitle">العنوان الرئيسي (Hero Title)</label>
                      <input type="text" id="cfgBrandTitle" class="input">
                    </div>
                    <div class="form-group">
                      <label class="form-label" for="cfgBrandSubtitle">الوصف التعريفي أسفل العنوان</label>
                      <textarea id="cfgBrandSubtitle" class="textarea" style="min-height:82px;"></textarea>
                    </div>
                    <div class="form-row">
                      <div class="form-group">
                        <label class="form-label" for="cmsPrimaryCta">زر الدعوة الأساسي</label>
                        <input type="text" id="cmsPrimaryCta" class="input">
                      </div>
                      <div class="form-group">
                        <label class="form-label" for="cmsSecondaryCta">زر الدعوة الثانوي</label>
                        <input type="text" id="cmsSecondaryCta" class="input">
                      </div>
                    </div>
                    <div class="form-row">
                      <div class="form-group">
                        <label class="form-label" for="cmsDownloadCta">زر تنزيل التطبيق (يظهر عند وضع رابط)</label>
                        <input type="text" id="cmsDownloadCta" class="input">
                      </div>
                      <div class="form-group">
                        <label class="form-label" for="cmsFooterText">نص التذييل (Footer)</label>
                        <input type="text" id="cmsFooterText" class="input">
                      </div>
                    </div>
                  </div>

                  <div>
                    <div class="panel-title" style="font-size:0.98rem;">شارات الثقة في الواجهة الترحيبية</div>
                    <div id="cmsTrustPillsList" class="array-list"></div>
                    <button type="button" class="btn btn-outline btn-sm" id="cmsAddTrustPillBtn" style="margin-bottom:1rem;">+ إضافة شارة ثقة</button>

                    <div class="panel-title" style="font-size:0.98rem;">معاينة شاشة الهاتف الجانبية</div>
                    <div class="form-group">
                      <label class="form-label" for="cmsMockupTitle">عنوان الترحيب داخل المعاينة</label>
                      <input type="text" id="cmsMockupTitle" class="input">
                    </div>
                    <div class="form-group">
                      <label class="form-label" for="cmsMockupSubtitle">الوصف القصير</label>
                      <input type="text" id="cmsMockupSubtitle" class="input">
                    </div>
                    <div class="form-group">
                      <label class="form-label" for="cmsMockupQuestion">سؤال البطاقة النموذجية</label>
                      <input type="text" id="cmsMockupQuestion" class="input">
                    </div>
                    <div class="form-group">
                      <label class="form-label" for="cmsMockupClarify">توضيح السؤال</label>
                      <input type="text" id="cmsMockupClarify" class="input">
                    </div>
                  </div>
                </div>
              </div>

              <!-- Pane 2: Section Visibility & Headers -->
              <div class="cms-pane" id="cms-pane-sections">
                <div class="cms-pane-head">
                  <div>
                    <div class="panel-title">2. إظهار أو إخفاء أقسام الموقع وعناوينها</div>
                    <div class="panel-sub" style="margin-bottom:0;">تحكم في ظهور كل قسم بالموقع وقائمة التنقل مع تخصيص عناوينه</div>
                  </div>
                  <div class="meta-pills">
                    <button type="button" class="btn btn-outline btn-sm" data-cms-next="hero">→ السابق</button>
                    <button type="button" class="btn btn-outline btn-sm" data-cms-next="cards">التالي: البطاقات ←</button>
                  </div>
                </div>
                <div class="cms-section-grid">
                  <div class="cms-section-box">
                    <div class="switch-card"><div><strong>قسم المميزات (لماذا وفاق)</strong><span>تظهر به بطاقات المميزات</span></div><input type="checkbox" id="cmsShowFeatures" checked></div>
                    <div class="form-group"><label class="form-label" for="cmsFeaturesBadge">الشارة</label><input type="text" id="cmsFeaturesBadge" class="input"></div>
                    <div class="form-group"><label class="form-label" for="cmsFeaturesTitle">العنوان</label><input type="text" id="cmsFeaturesTitle" class="input"></div>
                    <div class="form-group"><label class="form-label" for="cmsFeaturesSubtitle">الوصف</label><input type="text" id="cmsFeaturesSubtitle" class="input"></div>
                  </div>
                  <div class="cms-section-box">
                    <div class="switch-card"><div><strong>قسم متصفح نماذج الأسئلة</strong><span>تفاعلي حسب المحاور</span></div><input type="checkbox" id="cmsShowExplorer" checked></div>
                    <div class="form-group"><label class="form-label" for="cmsExplorerBadge">الشارة</label><input type="text" id="cmsExplorerBadge" class="input"></div>
                    <div class="form-group"><label class="form-label" for="cmsExplorerTitle">العنوان</label><input type="text" id="cmsExplorerTitle" class="input"></div>
                    <div class="form-group"><label class="form-label" for="cmsExplorerSubtitle">الوصف</label><input type="text" id="cmsExplorerSubtitle" class="input"></div>
                  </div>
                  <div class="cms-section-box">
                    <div class="switch-card"><div><strong>قسم الأنشطة والتفاعلات</strong><span>لو حصل كده ورتب أولوياتك</span></div><input type="checkbox" id="cmsShowActivities" checked></div>
                    <div class="form-group"><label class="form-label" for="cmsActivitiesBadge">الشارة</label><input type="text" id="cmsActivitiesBadge" class="input"></div>
                    <div class="form-group"><label class="form-label" for="cmsActivitiesTitle">العنوان</label><input type="text" id="cmsActivitiesTitle" class="input"></div>
                    <div class="form-group"><label class="form-label" for="cmsActivitiesSubtitle">الوصف</label><input type="text" id="cmsActivitiesSubtitle" class="input"></div>
                  </div>
                  <div class="cms-section-box">
                    <div class="switch-card"><div><strong>قسم كيف تبدأ؟</strong><span>خطوات التفعيل والاستخدام</span></div><input type="checkbox" id="cmsShowHowItWorks" checked></div>
                    <div class="form-group"><label class="form-label" for="cmsHowBadge">الشارة</label><input type="text" id="cmsHowBadge" class="input"></div>
                    <div class="form-group"><label class="form-label" for="cmsHowTitle">العنوان</label><input type="text" id="cmsHowTitle" class="input"></div>
                    <div class="form-group"><label class="form-label" for="cmsHowSubtitle">الوصف</label><input type="text" id="cmsHowSubtitle" class="input"></div>
                  </div>
                  <div class="cms-section-box">
                    <div class="switch-card"><div><strong>قسم تواصل معنا</strong><span>نموذج التواصل المباشر بدون دفع</span></div><input type="checkbox" id="cmsShowContact" checked></div>
                    <div class="form-group"><label class="form-label" for="cmsContactBadge">الشارة</label><input type="text" id="cmsContactBadge" class="input"></div>
                    <div class="form-group"><label class="form-label" for="cmsContactTitle">العنوان</label><input type="text" id="cmsContactTitle" class="input"></div>
                    <div class="form-group"><label class="form-label" for="cmsContactSubtitle">الوصف</label><input type="text" id="cmsContactSubtitle" class="input"></div>
                  </div>
                  <div class="cms-section-box">
                    <div class="switch-card"><div><strong>قسم الأسئلة الشائعة</strong><span>قائمة الأسئلة والأجوبة</span></div><input type="checkbox" id="cmsShowFaq" checked></div>
                    <div class="form-group"><label class="form-label" for="cmsFaqBadge">الشارة</label><input type="text" id="cmsFaqBadge" class="input"></div>
                    <div class="form-group"><label class="form-label" for="cmsFaqTitle">العنوان</label><input type="text" id="cmsFaqTitle" class="input"></div>
                    <div class="switch-card" style="margin-top:0.8rem;"><div><strong>قسم الحدود والشفافية</strong><span>ما هو وفاق / ما ليس وفاق</span></div><input type="checkbox" id="cmsShowBoundaries" checked></div>
                  </div>
                </div>
              </div>

              <!-- Pane 3: Cards & Steps -->
              <div class="cms-pane" id="cms-pane-cards">
                <div class="cms-pane-head">
                  <div>
                    <div class="panel-title">3. بطاقات المميزات، بطاقات الأنشطة، وخطوات البدء</div>
                    <div class="panel-sub" style="margin-bottom:0;">أضف أو رتّب أو عدّل البطاقات الظاهرة للزوار</div>
                  </div>
                  <div class="meta-pills">
                    <button type="button" class="btn btn-outline btn-sm" data-cms-next="sections">→ السابق</button>
                    <button type="button" class="btn btn-outline btn-sm" data-cms-next="samples">التالي: النماذج ←</button>
                  </div>
                </div>
                <div class="two-col">
                  <div>
                    <div class="list-header">
                      <div class="panel-title" style="font-size:0.98rem;">بطاقات «لماذا وفاق؟» (حتى 8)</div>
                      <button type="button" class="btn btn-outline btn-sm" id="cmsAddFeatureCardBtn">+ إضافة ميزة</button>
                    </div>
                    <div id="cmsFeaturesCardsList"></div>
                  </div>
                  <div>
                    <div class="list-header">
                      <div class="panel-title" style="font-size:0.98rem;">بطاقات الأنشطة (حتى 6)</div>
                      <button type="button" class="btn btn-outline btn-sm" id="cmsAddActivityCardBtn">+ إضافة نشاط</button>
                    </div>
                    <div id="cmsActivitiesCardsList" style="margin-bottom:1.1rem;"></div>

                    <div class="list-header">
                      <div class="panel-title" style="font-size:0.98rem;">خطوات البدء (حتى 5)</div>
                      <button type="button" class="btn btn-outline btn-sm" id="cmsAddStepBtn">+ إضافة خطوة</button>
                    </div>
                    <div id="cmsStepsList"></div>
                  </div>
                </div>
              </div>

              <!-- Pane 4: Sample Questions Showcase -->
              <div class="cms-pane" id="cms-pane-samples">
                <div class="cms-pane-head">
                  <div>
                    <div class="panel-title">4. نماذج الأسئلة المعروضة لزوار الموقع</div>
                    <div class="panel-sub" style="margin-bottom:0;">خصّص الأمثلة لكل محور أو استورد أسئلة معتمدة من بنك الأسئلة</div>
                  </div>
                  <div class="meta-pills">
                    <button type="button" class="btn btn-outline btn-sm" data-cms-next="cards">→ السابق</button>
                    <button type="button" class="btn btn-outline btn-sm" data-cms-next="faq">التالي: الشائعة ←</button>
                  </div>
                </div>
                <div class="list-header">
                  <div class="meta-pills" id="cmsSampleTopicTabs">
                    <button type="button" class="btn btn-primary btn-sm" data-cms-topic="communication">التواصل</button>
                    <button type="button" class="btn btn-outline btn-sm" data-cms-topic="dailyLife">الحياة اليومية</button>
                    <button type="button" class="btn btn-outline btn-sm" data-cms-topic="familyRelations">الأهل</button>
                    <button type="button" class="btn btn-outline btn-sm" data-cms-topic="finances">المالية</button>
                    <button type="button" class="btn btn-outline btn-sm" data-cms-topic="coreValues">القيم</button>
                  </div>
                  <div class="meta-pills">
                    <button type="button" class="btn btn-gold btn-sm" id="cmsPullSamplesBtn">استيراد 3 أسئلة معتمدة من البنك</button>
                    <button type="button" class="btn btn-outline btn-sm" id="cmsAddSampleBtn">+ إضافة نموذج</button>
                  </div>
                </div>
                <div id="cmsSamplesList"></div>
              </div>

              <!-- Pane 5: FAQ -->
              <div class="cms-pane" id="cms-pane-faq">
                <div class="cms-pane-head">
                  <div>
                    <div class="panel-title">5. الأسئلة الشائعة (FAQ)</div>
                    <div class="panel-sub" style="margin-bottom:0;">تظهر مرتبة في قسم الأسئلة الشائعة بالموقع (حتى 12 سؤالًا)</div>
                  </div>
                  <div class="meta-pills">
                    <button type="button" class="btn btn-outline btn-sm" data-cms-next="samples">→ السابق</button>
                    <button type="button" class="btn btn-outline btn-sm" data-cms-next="boundaries">التالي: الحدود ←</button>
                  </div>
                </div>
                <div class="list-header">
                  <div></div>
                  <button type="button" class="btn btn-outline btn-sm" id="cmsAddFaqBtn">+ إضافة سؤال شائع</button>
                </div>
                <div id="cmsFaqList"></div>
              </div>

              <!-- Pane 6: Boundaries & Privacy Page -->
              <div class="cms-pane" id="cms-pane-boundaries">
                <div class="cms-pane-head">
                  <div>
                    <div class="panel-title">6. حدود النظام وصفحة سياسة الخصوصية</div>
                    <div class="panel-sub" style="margin-bottom:0;">عدّل بنود «ما هو / ما ليس وفاق» وترويسة صفحة privacy.html</div>
                  </div>
                  <button type="button" class="btn btn-outline btn-sm" data-cms-next="faq">→ السابق</button>
                </div>
                <div class="two-col">
                  <div>
                    <div class="form-group">
                      <label class="form-label" for="cmsWhatIsTitle">عنوان عمود «ما هو وفاق؟»</label>
                      <input type="text" id="cmsWhatIsTitle" class="input">
                    </div>
                    <div id="cmsWhatIsList" class="array-list"></div>
                    <button type="button" class="btn btn-outline btn-sm" id="cmsAddWhatIsBtn">+ إضافة بند</button>
                  </div>
                  <div>
                    <div class="form-group">
                      <label class="form-label" for="cmsWhatIsNotTitle">عنوان عمود «ما ليس وفاقًا؟»</label>
                      <input type="text" id="cmsWhatIsNotTitle" class="input">
                    </div>
                    <div id="cmsWhatIsNotList" class="array-list"></div>
                    <button type="button" class="btn btn-outline btn-sm" id="cmsAddWhatIsNotBtn">+ إضافة بند</button>
                  </div>
                </div>
                <hr style="border:none;border-top:1px solid var(--border);margin:1.1rem 0;">
                <div class="panel-title" style="font-size:0.98rem;">ترويسة صفحة سياسة الخصوصية (privacy.html)</div>
                <div class="form-row">
                  <div class="form-group"><label class="form-label" for="cmsPrivacyBadge">شارة الصفحة</label><input type="text" id="cmsPrivacyBadge" class="input"></div>
                  <div class="form-group"><label class="form-label" for="cmsPrivacyTitle">عنوان الصفحة</label><input type="text" id="cmsPrivacyTitle" class="input"></div>
                </div>
                <div class="form-group"><label class="form-label" for="cmsPrivacySubtitle">المقدمة</label><textarea id="cmsPrivacySubtitle" class="textarea" style="min-height:66px;"></textarea></div>
              </div>

              <div class="studio-bottom-save">
                <div class="form-error" id="siteCmsError"></div>
                <button type="submit" class="btn btn-primary btn-block" id="saveSiteCmsBottomBtn">حفظ ونشر جميع تغييرات الموقع</button>
              </div>
            </div>
          </div>
        </form>
      </section>

      <!-- TAB 5: Activation Codes & Ed25519 Keys (Side-Menu Studio) -->
      <section class="tab-panel" id="tab-licenses">
        <div class="cms-studio">
          <aside class="cms-side-menu" aria-label="أقسام التراخيص والمفاتيح">
            <div class="list-header" style="margin-bottom:0.25rem;padding:0 0.3rem;">
              <span class="cms-side-label" style="padding:0;">أكواد التفعيل والأمان</span>
            </div>

            <div class="cms-side-scroll">
              <button type="button" class="cms-side-btn active" data-lic-sec="issue">
                <span class="cms-side-num">1</span>
                <span class="cms-side-meta">
                  <span class="cms-side-title">إصدار كود تفعيل</span>
                  <span class="cms-side-sub">الأجهزة، الحصة، والرابط</span>
                </span>
              </button>

              <button type="button" class="cms-side-btn" data-lic-sec="registry">
                <span class="cms-side-num">2</span>
                <span class="cms-side-meta">
                  <span class="cms-side-title">سجل التراخيص المصدرة</span>
                  <span class="cms-side-sub" id="licCountSideSub">تتبع، استبدال أو إلغاء</span>
                </span>
              </button>

              <button type="button" class="cms-side-btn" data-lic-sec="keys">
                <span class="cms-side-num">3</span>
                <span class="cms-side-meta">
                  <span class="cms-side-title">مفاتيح التوقيع (Ed25519)</span>
                  <span class="cms-side-sub">المفتاح العام وتوليد المفاتيح</span>
                </span>
              </button>
            </div>

            <div class="cms-side-footer">
              <span class="pill" id="serverKeyBadge" style="justify-content:center;">جاري الفحص...</span>
            </div>
          </aside>

          <div>
            <!-- Licenses Pane 1: Issue License + Result -->
            <div class="cms-pane active" id="lic-pane-issue">
              <div class="two-col lic-issue-grid">
                <div class="panel">
                  <div class="cms-pane-head" style="margin-bottom:0.9rem;padding-bottom:0.75rem;">
                    <div>
                      <div class="panel-title">إصدار كود تفعيل موقّع</div>
                      <div class="panel-sub" style="margin-bottom:0;">يدعم 1 إلى 20 جهازًا مع حد جلسات أو مدة صلاحية</div>
                    </div>
                    <button type="button" class="btn btn-outline btn-sm" id="jumpToKeysBtn">🔐 ضبط المفاتيح</button>
                  </div>

                  <form id="licenseForm">
                    <div class="form-error" id="licenseFormError"></div>

                    <div class="form-box">
                      <div class="form-box-title">
                        <span>1. الباقة والحصة الزمنية</span>
                      </div>
                      <div class="preset-grid">
                        <button type="button" class="preset-card preset-btn" data-preset="trial">
                          <strong>تجريبي</strong>
                          <span>5 جلسات · 14 يوم</span>
                        </button>
                        <button type="button" class="preset-card preset-btn active" data-preset="couple">
                          <strong>ثنائي قياسي</strong>
                          <span>20 جلسة · 180 يوم</span>
                        </button>
                        <button type="button" class="preset-card preset-btn" data-preset="unlimited">
                          <strong>مفتوح سنة</strong>
                          <span>غير محدود · 365 يوم</span>
                        </button>
                      </div>

                      <div class="form-row" style="margin-bottom:0;">
                        <div class="form-group" style="margin-bottom:0;">
                          <label class="form-label" for="licSessionLimit">عدد الجلسات لكل جهاز</label>
                          <input type="number" id="licSessionLimit" class="input" min="1" max="1000000" value="20" placeholder="اتركه فارغًا لغير محدود">
                        </div>
                        <div class="form-group" style="margin-bottom:0;">
                          <label class="form-label" for="licDurationDays">مدة الصلاحية (بالأيام)</label>
                          <input type="number" id="licDurationDays" class="input" min="1" max="3650" value="180" placeholder="اتركه فارغًا بدون انتهاء">
                        </div>
                      </div>
                    </div>

                    <div class="form-box">
                      <div class="form-box-title">
                        <span>2. معرّفات التثبيت المصرح لها *</span>
                        <div class="meta-pills">
                          <button type="button" class="btn btn-outline btn-sm" id="addSampleDeviceBtn">توليد معرّف اختبار</button>
                          <button type="button" class="btn btn-outline btn-sm" id="addDeviceSlotBtn">+ جهاز إضافي</button>
                        </div>
                      </div>
                      <div class="array-list" id="devicesInputList"></div>
                      <div class="form-hint" style="margin-bottom:0;">الصيغة: <code>inst_xxxxxxxx-xxxx-4xxx-xxxx-xxxxxxxxxxxx</code> (من 1 إلى 20 جهازًا)</div>
                    </div>

                    <div class="form-box">
                      <div class="form-box-title">3. بيانات المرجع ورابط التفعيل</div>
                      <div class="form-row">
                        <div class="form-group">
                          <label class="form-label" for="licLabel">اسم مرجعي / ملاحظة للإدارة</label>
                          <input type="text" id="licLabel" class="input" placeholder="مثال: أحمد وسارة - طلب واتساب">
                          <div class="form-hint">للسجل الإداري فقط؛ لا يظهر للمستخدم.</div>
                        </div>
                        <div class="form-group">
                          <label class="form-label" for="licCustomId">معرّف الترخيص (اختياري)</label>
                          <input type="text" id="licCustomId" class="input" dir="ltr" placeholder="يُنشأ تلقائيًا">
                        </div>
                      </div>
                      <div class="form-group" style="margin-bottom:0;">
                        <label class="form-label" for="licLinkHost">نطاق رابط التفعيل المباشر (اختياري)</label>
                        <input type="text" id="licLinkHost" class="input" dir="ltr" placeholder="wefaq-questions-api.vercel.app">
                      </div>
                    </div>

                    <button type="submit" class="btn btn-primary btn-block" id="generateLicenseBtn">توليد كود التفعيل الموقّع</button>
                  </form>
                </div>

                <div class="panel lic-output-panel">
                  <div class="panel-title">نتيجة التفعيل الجاهزة للإرسال</div>
                  <div class="panel-sub">تظهر هنا بيانات الكود والرابط ورسالة التسليم فور الإصدار</div>

                  <div id="licenseOutputEmpty" class="empty-state" style="padding:2.2rem 0.75rem;background:#FAFBF9;border:1px dashed var(--chip-border);border-radius:14px;">
                    أدخل معرّف الجهاز واضغط «توليد كود التفعيل الموقّع» ليظهر الكود والرابط هنا.
                  </div>

                  <div id="licenseOutputBox" style="display:none;flex-direction:column;gap:0.9rem;">
                    <div>
                      <div class="list-header" style="margin-bottom:0.35rem;">
                        <span class="form-label" style="margin-bottom:0;">كود التفعيل الموقّع</span>
                        <button type="button" class="btn btn-primary btn-sm" id="copyGenCodeBtn">نسخ الكود</button>
                      </div>
                      <div class="code-output" id="genCodeOutput"></div>
                    </div>

                    <div id="genLinkWrap" style="display:none;">
                      <div class="list-header" style="margin-bottom:0.35rem;">
                        <span class="form-label" style="margin-bottom:0;">رابط التفعيل المباشر</span>
                        <button type="button" class="btn btn-outline btn-sm" id="copyGenLinkBtn">نسخ الرابط</button>
                      </div>
                      <div class="code-output" id="genLinkOutput" style="max-height:95px;"></div>
                    </div>

                    <div>
                      <div class="list-header" style="margin-bottom:0.35rem;">
                        <span class="form-label" style="margin-bottom:0;">رسالة تسليم جاهزة للمستخدم</span>
                        <button type="button" class="btn btn-gold btn-sm" id="copyDeliveryMsgBtn">نسخ الرسالة</button>
                      </div>
                      <textarea id="genDeliveryMsg" class="textarea" readonly style="min-height:115px;"></textarea>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Licenses Pane 2: Issued Registry -->
            <div class="cms-pane" id="lic-pane-registry">
              <div class="panel">
                <div class="list-header">
                  <div>
                    <div class="panel-title">سجل التراخيص المصدرة</div>
                    <div class="panel-sub" style="margin-bottom:0;">تتبع، استبدال جهاز مفقود، أو إلغاء سجل ترخيص</div>
                  </div>
                  <div class="lic-filter-bar">
                    <input type="search" id="licSearchInput" class="input" placeholder="بحث بالمعرف أو الاسم...">
                    <select id="licStatusFilter" class="select">
                      <option value="">كل الحالات</option>
                      <option value="active">ساري</option>
                      <option value="expired">منتهي</option>
                      <option value="revoked">ملغى</option>
                    </select>
                  </div>
                </div>
                <div class="questions-list" id="licensesList">
                  <div class="empty-state">لا توجد تراخيص مسجلة بعد.</div>
                </div>
              </div>
            </div>

            <!-- Licenses Pane 3: Ed25519 Keys Setup -->
            <div class="cms-pane" id="lic-pane-keys">
              <div class="panel">
                <div class="cms-pane-head">
                  <div>
                    <div class="panel-title">مفاتيح التوقيع الرقمي (Ed25519)</div>
                    <div class="panel-sub" style="margin-bottom:0;">الأكواد المولّدة متوافقة تشفيريًا مع بوابة التفعيل في تطبيق Flutter</div>
                  </div>
                  <button type="button" class="btn btn-gold btn-sm" id="generateKeyPairBtn">توليد زوج مفاتيح جديد</button>
                </div>

                <div class="two-col">
                  <div class="form-box" style="margin-bottom:0;">
                    <div class="form-box-title">المفتاح العام للتطبيق</div>
                    <label class="form-label" for="licPublicKeyDisplay">WEFAQ_LICENSE_PUBLIC_KEY</label>
                    <div class="array-row">
                      <input type="text" id="licPublicKeyDisplay" class="input" dir="ltr" readonly placeholder="لم يتم تحديد مفتاح بعد">
                      <button type="button" class="btn btn-outline btn-sm" id="copyPublicKeyBtn">نسخ</button>
                    </div>
                    <div class="form-hint">يُضبط في ملف <code>.env</code> أو عبر <code>--dart-define=WEFAQ_LICENSE_PUBLIC_KEY=...</code></div>
                  </div>

                  <div class="form-box" style="margin-bottom:0;">
                    <div class="form-box-title">مفتاح توقيع مؤقت للجلسة (اختياري)</div>
                    <label class="form-label" for="licSessionSeedInput">Seed الخاص بالتوقيع (عند غياب LICENSE_PRIVATE_SEED)</label>
                    <div class="password-wrap">
                      <input type="password" id="licSessionSeedInput" name="wefaq_ephemeral_seed" class="input" dir="ltr" autocomplete="new-password" readonly placeholder="اتركه فارغًا إذا كان LICENSE_PRIVATE_SEED مضبوطًا بالخادم">
                      <button type="button" class="toggle-vis-btn" id="toggleSeedVisBtn">إظهار</button>
                    </div>
                    <div class="form-hint">محمي من الملء التلقائي للمتصفح، ويبقى في الذاكرة المؤقتة للجلسة فقط.</div>
                  </div>
                </div>

                <div id="keygenResultBox" class="banner" style="display:none;margin-top:1rem;flex-direction:column;align-items:stretch;">
                  <div><strong>تم توليد زوج مفاتيح Ed25519 جديد — احتفظ بالمفتاح الخاص في مكان آمن:</strong></div>
                  <div class="form-row">
                    <div>
                      <div class="form-label">LICENSE_PRIVATE_SEED (سري — لمتغيرات Vercel/الخادم فقط)</div>
                      <div class="code-output" id="keygenSeedOutput"></div>
                    </div>
                    <div>
                      <div class="form-label">WEFAQ_LICENSE_PUBLIC_KEY (عام — لتطبيق Flutter)</div>
                      <div class="code-output" id="keygenPubOutput"></div>
                    </div>
                  </div>
                  <div class="meta-pills">
                    <button type="button" class="btn btn-primary btn-sm" id="useGeneratedSeedBtn">استخدام هذا المفتاح في الجلسة الآن</button>
                    <button type="button" class="btn btn-outline btn-sm" id="copyKeygenEnvBtn">نسخ سطر .env للتطبيق</button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </main>

      <footer>
        مركز إدارة وفاق — متوافق مع عقد البيانات <code dir="ltr">GET /v1/question-catalog</code> ولا يحفظ أي إجابات حوارية.
      </footer>
    </div>

    <nav class="mobile-bottom-nav" aria-label="تنقل سريع بالهاتف">
      <button type="button" class="mobile-nav-btn active" data-mobile-tab="questions">
        <span class="mnav-ico">💬</span><span>الأسئلة</span>
      </button>
      <button type="button" class="mobile-nav-btn" data-mobile-tab="activities">
        <span class="mnav-ico">🧩</span><span>الأنشطة</span>
      </button>
      <button type="button" class="mobile-nav-btn" data-mobile-tab="siteCms">
        <span class="mnav-ico">🎨</span><span>الموقع</span>
      </button>
      <button type="button" class="mobile-nav-btn" data-mobile-tab="appConfig">
        <span class="mnav-ico">📞</span><span>التواصل</span>
      </button>
      <button type="button" class="mobile-nav-btn" data-mobile-tab="licenses">
        <span class="mnav-ico">🗝️</span><span>التفعيل</span>
      </button>
    </nav>
  </div>

  <!-- Create / Edit Question Modal -->
  <div class="modal-backdrop" id="editorModalBackdrop" aria-hidden="true">
    <div class="modal" role="dialog" aria-modal="true" aria-labelledby="editorModalTitle">
      <div class="modal-header">
        <h2 class="modal-title" id="editorModalTitle">تعديل السؤال</h2>
        <button type="button" class="btn btn-outline btn-sm" id="closeEditorBtn">إغلاق</button>
      </div>
      <form id="questionForm">
        <div class="form-error" id="formError"></div>
        <div class="form-group">
          <label class="form-label" for="fieldId">معرّف السؤال (ID)</label>
          <input type="text" id="fieldId" class="input" dir="ltr" placeholder="يُنشأ تلقائيًا إذا تُرك فارغًا">
          <div class="form-hint" id="fieldIdHint">حروف إنجليزية وأرقام وشرطة (-) أو (_) فقط؛ لا يتغير بعد الإنشاء.</div>
        </div>
        <div class="form-group">
          <label class="form-label" for="fieldText">نص السؤال *</label>
          <textarea id="fieldText" class="textarea" required placeholder="اكتب صياغة السؤال بوضوح وهدوء..."></textarea>
        </div>
        <div class="form-group">
          <label class="form-label" for="fieldClarification">التوضيح / الهدف (اختياري)</label>
          <textarea id="fieldClarification" class="textarea" style="min-height:68px;" placeholder="مثال: الهدف معرفة أسلوب التواصل المفضل..."></textarea>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label" for="fieldTopic">المجال *</label>
            <select id="fieldTopic" class="select" required>
              <option value="communication">التواصل وإدارة الخلافات</option>
              <option value="dailyLife">الحياة اليومية والمسؤوليات</option>
              <option value="familyRelations">الأهل والحدود الأسرية</option>
              <option value="finances">المالية والتطلعات المشتركة</option>
              <option value="coreValues">القيم والمبادئ والتربية</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label" for="fieldDepth">العمق *</label>
            <select id="fieldDepth" class="select" required>
              <option value="introductory">تمهيدي (introductory)</option>
              <option value="deeper">أعمق (deeper)</option>
            </select>
          </div>
        </div>
        <div class="form-group">
          <span class="form-label">أوضاع الجلسة المناسبة *</span>
          <div class="checkbox-group">
            <label class="checkbox-label"><input type="checkbox" id="modeTogether" value="together" checked> معًا (together)</label>
            <label class="checkbox-label"><input type="checkbox" id="modePhone" value="phone" checked> مكالمة هاتفية (phone)</label>
          </div>
        </div>
        <div class="form-group">
          <label class="checkbox-label"><input type="checkbox" id="fieldIsDev" checked> سؤال مسودة للتطوير فقط (isDevelopmentOnly)</label>
          <div class="form-hint">لا تُزل علامة التطوير إلا بعد إتمام المراجعة الشرعية والأسرية واللغوية.</div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-outline" id="cancelEditorBtn">إلغاء</button>
          <button type="submit" class="btn btn-primary" id="saveQuestionBtn">حفظ التغييرات</button>
        </div>
      </form>
    </div>
  </div>

  <!-- Bulk Import Questions Modal -->
  <div class="modal-backdrop" id="bulkModalBackdrop" aria-hidden="true">
    <div class="modal" role="dialog" aria-modal="true" aria-labelledby="bulkModalTitle">
      <div class="modal-header">
        <h2 class="modal-title" id="bulkModalTitle">استيراد دفعة أسئلة</h2>
        <button type="button" class="btn btn-outline btn-sm" id="closeBulkBtn">إغلاق</button>
      </div>
      <form id="bulkForm">
        <div class="form-error" id="bulkError"></div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label" for="bulkTopic">المجال الافتراضي</label>
            <select id="bulkTopic" class="select">
              <option value="communication">التواصل وإدارة الخلافات</option>
              <option value="dailyLife">الحياة اليومية والمسؤوليات</option>
              <option value="familyRelations">الأهل والحدود الأسرية</option>
              <option value="finances">المالية والتطلعات المشتركة</option>
              <option value="coreValues">القيم والمبادئ والتربية</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label" for="bulkDepth">العمق الافتراضي</label>
            <select id="bulkDepth" class="select">
              <option value="introductory">تمهيدي</option>
              <option value="deeper">أعمق</option>
            </select>
          </div>
        </div>
        <div class="form-group">
          <label class="form-label" for="bulkInput">اكتب سؤالًا في كل سطر (أو الصق مصفوفة JSON)</label>
          <textarea id="bulkInput" class="textarea" style="min-height:170px;" required placeholder="مثال سطر 1: كيف نرتب وقت تواصلنا اليومي؟ | الهدف معرفة أسلوب التواصل&#10;مثال سطر 2: ما أكثر شيء يريحك عند الخلاف؟"></textarea>
          <div class="form-hint">يمكنك فصل التوضيح عن السؤال بعلامة <code>|</code> في نفس السطر، أو لصق JSON مباشر.</div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-outline" id="cancelBulkBtn">إلغاء</button>
          <button type="submit" class="btn btn-primary" id="saveBulkBtn">استيراد الأسئلة</button>
        </div>
      </form>
    </div>
  </div>

  <!-- Create / Edit Activity Modal -->
  <div class="modal-backdrop" id="activityModalBackdrop" aria-hidden="true">
    <div class="modal" role="dialog" aria-modal="true" aria-labelledby="activityModalTitle">
      <div class="modal-header">
        <h2 class="modal-title" id="activityModalTitle">إضافة نشاط جديد</h2>
        <button type="button" class="btn btn-outline btn-sm" id="closeActivityBtn">إغلاق</button>
      </div>
      <form id="activityForm">
        <div class="form-error" id="activityFormError"></div>
        <div class="form-row">
          <div class="form-group">
            <label class="form-label" for="actFieldType">نوع النشاط *</label>
            <select id="actFieldType" class="select" required>
              <option value="scenario">سيناريو للنقاش (لو حصل كده؟)</option>
              <option value="priorityOrdering">ترتيب أولويات (رتّب أولوياتك)</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label" for="actFieldTopic">المجال *</label>
            <select id="actFieldTopic" class="select" required>
              <option value="communication">التواصل وإدارة الخلافات</option>
              <option value="dailyLife">الحياة اليومية والمسؤوليات</option>
              <option value="familyRelations">الأهل والحدود الأسرية</option>
              <option value="finances">المالية والتطلعات المشتركة</option>
              <option value="coreValues">القيم والمبادئ والتربية</option>
            </select>
          </div>
        </div>
        <div class="form-group">
          <label class="form-label" for="actFieldId">معرّف النشاط (ID)</label>
          <input type="text" id="actFieldId" class="input" dir="ltr" placeholder="يُنشأ تلقائيًا إذا تُرك فارغًا">
        </div>
        <div class="form-group">
          <label class="form-label" for="actFieldTitle">عنوان البطاقة *</label>
          <input type="text" id="actFieldTitle" class="input" required placeholder="مثال: موقف للنقاش: ترتيب الأولويات الأسبوعية">
        </div>
        <div class="form-group">
          <label class="form-label" for="actFieldSituation">وصف الموقف أو التوجيه *</label>
          <textarea id="actFieldSituation" class="textarea" required placeholder="اشرح الموقف بهدوء ووضوح..."></textarea>
        </div>

        <div class="form-group" id="actOptionsGroup" style="display:none;">
          <div class="list-header" style="margin-bottom:0.35rem;">
            <span class="form-label" style="margin-bottom:0;">عناصر ترتيب الأولويات (2 على الأقل) *</span>
            <button type="button" class="btn btn-outline btn-sm" id="addActOptionBtn">+ عنصر</button>
          </div>
          <div class="array-list" id="actOptionsList"></div>
        </div>

        <div class="form-group">
          <div class="list-header" style="margin-bottom:0.35rem;">
            <span class="form-label" style="margin-bottom:0;">محاور النقاش المقترحة</span>
            <button type="button" class="btn btn-outline btn-sm" id="addActPromptBtn">+ محور</button>
          </div>
          <div class="array-list" id="actPromptsList"></div>
        </div>

        <div class="form-group">
          <label class="checkbox-label"><input type="checkbox" id="actFieldIsDev" checked> مسودة للتطوير فقط (isDevelopmentOnly)</label>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-outline" id="cancelActivityBtn">إلغاء</button>
          <button type="submit" class="btn btn-primary" id="saveActivityBtn">حفظ النشاط</button>
        </div>
      </form>
    </div>
  </div>

  <!-- Delete Confirmation Modal -->
  <div class="modal-backdrop" id="deleteModalBackdrop" aria-hidden="true">
    <div class="modal" role="dialog" aria-modal="true" style="max-width:460px;">
      <div class="modal-header">
        <h2 class="modal-title" id="deleteModalTitle">تأكيد الحذف</h2>
        <button type="button" class="btn btn-outline btn-sm" id="closeDeleteBtn">إغلاق</button>
      </div>
      <p style="margin-bottom:0.75rem;color:var(--dark);font-weight:600;" id="deletePreviewText"></p>
      <p style="font-size:0.84rem;color:var(--muted);">ملاحظة: الحذف نهائي ويزيد رقم المراجعة في الكتالوج.</p>
      <div class="form-error" id="deleteError"></div>
      <div class="modal-footer">
        <button type="button" class="btn btn-outline" id="cancelDeleteBtn">تراجع</button>
        <button type="button" class="btn btn-danger" id="confirmDeleteBtn">تأكيد التنفيذ</button>
      </div>
    </div>
  </div>

  <div class="toast" id="toast"></div>

  <script>
    (function () {
      const TOPIC_LABELS = {
        communication: 'التواصل وإدارة الخلافات',
        dailyLife: 'الحياة اليومية والمسؤوليات',
        familyRelations: 'الأهل والحدود الأسرية',
        finances: 'المالية والتطلعات المشتركة',
        coreValues: 'القيم والمبادئ والتربية',
      };
      const DEPTH_LABELS = { introductory: 'تمهيدي', deeper: 'أعمق' };
      const MODE_LABELS = { together: 'معًا', phone: 'هاتف' };
      const ACTIVITY_TYPE_LABELS = {
        scenario: 'سيناريو للنقاش',
        priorityOrdering: 'ترتيب أولويات',
      };

      const state = {
        session: null,
        activeTab: 'questions',
        page: 1,
        limit: 25,
        totalPages: 1,
        search: '',
        topic: '',
        depth: '',
        mode: '',
        isDevelopmentOnly: '',
        viewMode: 'cards',
        selectedIds: new Set(),
        currentItems: [],
        lastFilteredTotal: 0,
        lastCounts: null,
        meta: null,
        editingQuestionId: null,
        editingActivityId: null,
        deleteContext: null,
        actSearch: '',
        actType: '',
        actTopic: '',
        actDev: '',
        appConfig: null,
        cmsSampleTopic: 'communication',
        cmsSamplesDraft: null,
        licenseConfig: null,
        replacedFromId: null,
        lastGeneratedCode: '',
        lastGeneratedLink: '',
        lastKeygenPub: '',
        lastKeygenSeed: '',
      };

      const el = (id) => document.getElementById(id);
      let searchTimer = null;
      let actSearchTimer = null;
      let licSearchTimer = null;

      function showToast(message) {
        const toast = el('toast');
        toast.textContent = message;
        toast.classList.add('show');
        clearTimeout(toast._timer);
        toast._timer = setTimeout(() => toast.classList.remove('show'), 3200);
      }

      async function copyText(text, successMsg) {
        if (!text) return;
        try {
          await navigator.clipboard.writeText(text);
          showToast(successMsg || 'تم النسخ بنجاح');
        } catch (_) {
          showToast('تعذر النسخ التلقائي؛ حدد النص وانسخه يدويًا');
        }
      }

      async function apiFetch(url, options = {}) {
        const headers = new Headers(options.headers || {});
        if (options.body && !headers.has('Content-Type')) {
          headers.set('Content-Type', 'application/json');
        }
        const response = await fetch(url, {
          ...options,
          headers,
          credentials: 'same-origin',
        });
        const contentType = response.headers.get('content-type') || '';
        const data = contentType.includes('application/json')
          ? await response.json()
          : null;

        if (!response.ok) {
          const message =
            (data && (Array.isArray(data.message) ? data.message.join(' - ') : data.message)) ||
            'حدث خطأ غير متوقع (' + response.status + ')';
          const err = new Error(message);
          err.status = response.status;
          throw err;
        }
        return data;
      }

      function setLoggedInView(session) {
        state.session = session;
        if (el('bootShell')) el('bootShell').classList.remove('active');
        el('loginShell').classList.remove('active');
        el('appShell').classList.add('active');
        el('sessionUserLabel').textContent =
          'مسجّل كـ ' + (session.username || 'admin') + (session.devBypassAvailable ? ' · وضع تطوير محلي' : '');
      }

      function setLoggedOutView(sessionInfo) {
        state.session = null;
        setSidebarOpen(false);
        if (el('bootShell')) el('bootShell').classList.remove('active');
        el('appShell').classList.remove('active');
        el('loginShell').classList.add('active');
        el('loginError').classList.remove('visible');
        el('loginPassword').value = '';
        if (sessionInfo && sessionInfo.configuredUsername) {
          el('loginUsername').value = sessionInfo.configuredUsername;
        }
        if (sessionInfo && sessionInfo.devBypassAvailable) {
          el('devLoginBox').classList.add('visible');
        } else {
          el('devLoginBox').classList.remove('visible');
        }
      }

      const TAB_META = {
        questions: {
          title: 'بنك الأسئلة',
          sub: 'إدارة الأسئلة الفردية واستيراد الدفعات والمراجعة قبل النشر',
        },
        activities: {
          title: 'الأنشطة والمواقف',
          sub: 'إنشاء وتعديل السيناريوهات الواقعية وتمارين ترتيب الأولويات',
        },
        siteCms: {
          title: 'محتوى الموقع (CMS)',
          sub: 'التحكم في نصوص وأقسام الموقع التعريفي والأسئلة الشائعة',
        },
        appConfig: {
          title: 'التطبيق وقنوات التواصل',
          sub: 'قنوات الدعم المباشر بدون دفع، الإشعارات، وميزات وإصدارات التطبيق',
        },
        licenses: {
          title: 'أكواد التفعيل والمفاتيح',
          sub: 'إدارة مفاتيح Ed25519 وإصدار ومتابعة تراخيص الأجهزة',
        },
      };

      function setSidebarOpen(open) {
        if (el('sidebarNav')) el('sidebarNav').classList.toggle('open', open);
        if (el('sidebarBackdrop')) el('sidebarBackdrop').classList.toggle('open', open);
        document.body.style.overflow = open ? 'hidden' : '';
      }

      if (el('sidebarToggleBtn')) {
        el('sidebarToggleBtn').addEventListener('click', () => setSidebarOpen(true));
      }
      if (el('sidebarCloseBtn')) {
        el('sidebarCloseBtn').addEventListener('click', () => setSidebarOpen(false));
      }
      if (el('sidebarBackdrop')) {
        el('sidebarBackdrop').addEventListener('click', () => setSidebarOpen(false));
      }

      function switchTab(tabName) {
        state.activeTab = tabName;
        setSidebarOpen(false);
        const info = TAB_META[tabName] || TAB_META.questions;
        if (el('activeTabHeading')) el('activeTabHeading').textContent = info.title;
        if (el('activeTabSub')) el('activeTabSub').textContent = info.sub;

        document.querySelectorAll('.tab-btn').forEach((btn) => {
          btn.classList.toggle('active', btn.dataset.tab === tabName);
        });
        document.querySelectorAll('.mobile-nav-btn').forEach((btn) => {
          btn.classList.toggle('active', btn.dataset.mobileTab === tabName);
        });
        document.querySelectorAll('.tab-panel').forEach((panel) => {
          panel.classList.toggle('active', panel.id === 'tab-' + tabName);
        });
        window.scrollTo({ top: 0, behavior: 'smooth' });

        if (tabName === 'activities') void loadActivities();
        if (tabName === 'appConfig' || tabName === 'siteCms') {
          if (!state.appConfig) void loadAppConfig();
        }
        if (tabName === 'licenses') void loadLicensesTab();
      }

      /* ---------------- Auth Handlers ---------------- */
      el('toggleLoginVisBtn').addEventListener('click', () => {
        const input = el('loginPassword');
        const hidden = input.type === 'password';
        input.type = hidden ? 'text' : 'password';
        el('toggleLoginVisBtn').textContent = hidden ? 'إخفاء' : 'إظهار';
      });

      el('loginForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const errEl = el('loginError');
        errEl.classList.remove('visible');
        const btn = el('loginSubmitBtn');
        btn.disabled = true;
        try {
          const res = await apiFetch('/v1/auth/login', {
            method: 'POST',
            body: JSON.stringify({
              username: el('loginUsername').value.trim(),
              password: el('loginPassword').value.trim(),
            }),
          });
          const session = await apiFetch('/v1/auth/session');
          setLoggedInView({ ...session, username: res.username });
          await loadInitialWorkspace();
          showToast('تم تسجيل الدخول بنجاح');
        } catch (err) {
          errEl.textContent = err.message;
          errEl.classList.add('visible');
        } finally {
          btn.disabled = false;
        }
      });

      el('devQuickLoginBtn').addEventListener('click', async () => {
        const errEl = el('loginError');
        errEl.classList.remove('visible');
        try {
          const res = await apiFetch('/v1/auth/login', {
            method: 'POST',
            body: JSON.stringify({
              username: el('loginUsername').value.trim() || 'admin',
              devMode: true,
            }),
          });
          const session = await apiFetch('/v1/auth/session');
          setLoggedInView({ ...session, username: res.username });
          await loadInitialWorkspace();
          showToast('تم الدخول بوضع التطوير المحلي');
        } catch (err) {
          errEl.textContent = err.message;
          errEl.classList.add('visible');
        }
      });

      el('logoutBtn').addEventListener('click', async () => {
        try {
          await apiFetch('/v1/auth/logout', { method: 'POST' });
        } catch (_) {}
        const info = await apiFetch('/v1/auth/session').catch(() => null);
        setLoggedOutView(info);
        showToast('تم تسجيل الخروج');
      });

      document.querySelectorAll('.tab-btn').forEach((btn) => {
        btn.addEventListener('click', () => switchTab(btn.dataset.tab));
      });
      document.querySelectorAll('.mobile-nav-btn').forEach((btn) => {
        btn.addEventListener('click', () => switchTab(btn.dataset.mobileTab));
      });

      /* ---------------- Questions Tab ---------------- */
      function renderMetaAndNotice() {
        const meta = state.meta;
        if (!meta) return;
        if (meta.catalog) {
          el('revisionBadge').textContent =
            'الإصدار v' + meta.catalog.schemaVersion + ' · مراجعة #' + meta.catalog.revision;
        }
        const storageEl = el('storageBadge');
        if (meta.storageMode === 'vercel-blob') {
          storageEl.textContent = 'حفظ دائم: Vercel Blob';
          storageEl.className = 'pill';
        } else if (meta.storageMode === 'file') {
          storageEl.textContent = 'حفظ محلي دائم';
          storageEl.className = 'pill';
        } else {
          storageEl.textContent = 'معاينة مؤقتة (في الذاكرة)';
          storageEl.className = 'pill pill-gold';
        }

        const banner = el('noticeBanner');
        if (!meta.persistent) {
          el('noticeText').textContent =
            'وضع المعاينة المؤقت على Vercel: التعديلات تحفظ في الذاكرة المؤقتة فقط. للحفظ الدائم أضف BLOB_READ_WRITE_TOKEN أو صدّر الملف بعد التعديل.';
          banner.style.display = 'flex';
        } else {
          banner.style.display = 'none';
        }
      }

      function renderStats(counts) {
        const grid = el('statsGrid');
        grid.replaceChildren();
        if (!counts) return;

        const cards = [
          {
            topic: '',
            label: 'إجمالي الأسئلة',
            value: counts.total,
            meta: 'مسودة: ' + counts.developmentOnly + ' · معتمد: ' + counts.approved,
          },
          ...Object.keys(TOPIC_LABELS).map((key) => ({
            topic: key,
            label: TOPIC_LABELS[key],
            value: counts.byTopic[key] || 0,
            meta: 'اضغط للتصفية',
          })),
        ];

        for (const card of cards) {
          const btn = document.createElement('button');
          btn.type = 'button';
          btn.className = 'stat-card' + (state.topic === card.topic ? ' active' : '');
          const lbl = document.createElement('div');
          lbl.className = 'stat-label';
          lbl.textContent = card.label;
          const val = document.createElement('div');
          val.className = 'stat-value';
          val.textContent = String(card.value);
          const meta = document.createElement('div');
          meta.className = 'stat-meta';
          meta.textContent = card.meta;
          btn.append(lbl, val, meta);
          btn.addEventListener('click', () => {
            state.topic = card.topic;
            el('topicFilter').value = card.topic;
            state.page = 1;
            void loadQuestions();
          });
          grid.appendChild(btn);
        }
      }

      function syncBulkSelectionUi() {
        const count = state.selectedIds.size;
        const bar = el('bulkSelectionBar');
        bar.classList.toggle('visible', count > 0);
        el('bulkSelectedCount').textContent = 'تم تحديد ' + count + ' سؤال';

        const pageBox = el('selectPageCheckbox');
        const pageItems = state.currentItems || [];
        if (pageItems.length === 0) {
          pageBox.checked = false;
          pageBox.indeterminate = false;
          return;
        }
        const selectedOnPage = pageItems.filter((q) => state.selectedIds.has(q.id)).length;
        pageBox.checked = selectedOnPage === pageItems.length;
        pageBox.indeterminate = selectedOnPage > 0 && selectedOnPage < pageItems.length;
      }

      async function executeBulkQuestionAction(payload, successPrefix) {
        const res = await apiFetch('/v1/questions/bulk-action', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
        state.selectedIds.clear();
        syncBulkSelectionUi();
        showToast(successPrefix + ' (' + res.affectedCount + ' سؤال)');
        await reloadQuestionsAndMeta();
      }

      function createQuestionActionButtons(q, compact) {
        const wrap = document.createElement('div');
        wrap.className = 'item-actions';

        const toggleBtn = document.createElement('button');
        toggleBtn.type = 'button';
        toggleBtn.className = q.isDevelopmentOnly ? 'btn btn-primary btn-sm' : 'btn btn-gold btn-sm';
        toggleBtn.textContent = q.isDevelopmentOnly ? 'اعتماد' : 'لمسودة';
        toggleBtn.addEventListener('click', async () => {
          try {
            await apiFetch('/v1/questions/' + encodeURIComponent(q.id), {
              method: 'PATCH',
              body: JSON.stringify({ isDevelopmentOnly: !q.isDevelopmentOnly }),
            });
            showToast(q.isDevelopmentOnly ? 'تم اعتماد السؤال للنشر' : 'تم تحويل السؤال لمسودة');
            await reloadQuestionsAndMeta();
          } catch (err) {
            if (err.status === 401) handleUnauthorized();
            else showToast(err.message);
          }
        });

        const copyBtn = document.createElement('button');
        copyBtn.type = 'button';
        copyBtn.className = 'btn btn-outline btn-sm';
        copyBtn.textContent = 'نسخ';
        copyBtn.title = 'نسخ نص السؤال';
        copyBtn.addEventListener('click', () => copyText(q.text, 'تم نسخ نص السؤال'));

        const cloneBtn = document.createElement('button');
        cloneBtn.type = 'button';
        cloneBtn.className = 'btn btn-outline btn-sm';
        cloneBtn.textContent = 'تكرار';
        cloneBtn.title = 'إنشاء نسخة جديدة من السؤال';
        cloneBtn.addEventListener('click', () => openEditorModal(q, true));

        const editBtn = document.createElement('button');
        editBtn.type = 'button';
        editBtn.className = 'btn btn-outline btn-sm';
        editBtn.textContent = 'تعديل';
        editBtn.addEventListener('click', () => openEditorModal(q, false));

        const delBtn = document.createElement('button');
        delBtn.type = 'button';
        delBtn.className = 'btn btn-danger btn-sm';
        delBtn.textContent = 'حذف';
        delBtn.addEventListener('click', () => openDeleteModal('question', q));

        if (compact) {
          wrap.append(toggleBtn, copyBtn, editBtn, delBtn);
        } else {
          wrap.append(toggleBtn, copyBtn, cloneBtn, editBtn, delBtn);
        }
        return wrap;
      }

      function createSelectionCheckbox(q, rowEl) {
        const chk = document.createElement('input');
        chk.type = 'checkbox';
        chk.className = 'q-check';
        chk.checked = state.selectedIds.has(q.id);
        chk.setAttribute('aria-label', 'تحديد ' + q.id);
        chk.addEventListener('change', () => {
          if (chk.checked) state.selectedIds.add(q.id);
          else state.selectedIds.delete(q.id);
          rowEl.classList.toggle('is-selected', chk.checked);
          syncBulkSelectionUi();
        });
        return chk;
      }

      function createCopyableIdPill(id) {
        const pill = document.createElement('span');
        pill.className = 'pill pill-id pill-copy';
        pill.textContent = id;
        pill.title = 'اضغط لنسخ المعرّف';
        pill.addEventListener('click', () => copyText(id, 'تم نسخ المعرّف: ' + id));
        return pill;
      }

      function renderQuestions(data) {
        state.currentItems = data.items || [];
        state.lastFilteredTotal = data.filteredTotal || 0;
        state.lastCounts = data.counts || null;

        document.querySelectorAll('[data-dev-tab]').forEach((btn) => {
          btn.classList.toggle('active', btn.dataset.devTab === state.isDevelopmentOnly);
        });
        document.querySelectorAll('[data-view-mode]').forEach((btn) => {
          btn.classList.toggle('active', btn.dataset.viewMode === state.viewMode);
        });
        const showBulkApprove =
          state.isDevelopmentOnly !== 'false' &&
          data.counts &&
          data.counts.developmentOnly > 0 &&
          data.filteredTotal > 0;
        el('approveFilteredBtn').style.display = showBulkApprove ? 'inline-flex' : 'none';

        const list = el('questionsList');
        list.replaceChildren();
        el('filteredCountBadge').textContent = data.filteredTotal + ' سؤال';
        el('pageIndicator').textContent =
          'صفحة ' + data.page + ' من ' + data.totalPages + ' (عرض ' + data.items.length + ' من ' + data.filteredTotal + ')';
        el('prevPageBtn').disabled = data.page <= 1;
        el('nextPageBtn').disabled = data.page >= data.totalPages;

        if (!data.items || data.items.length === 0) {
          const empty = document.createElement('div');
          empty.className = 'empty-state';
          empty.textContent = 'لا توجد أسئلة مطابقة لخيارات البحث الحالية.';
          list.appendChild(empty);
          syncBulkSelectionUi();
          return;
        }

        const startIdx = (data.page - 1) * state.limit;

        if (state.viewMode === 'table') {
          const wrap = document.createElement('div');
          wrap.className = 'q-table-wrap';
          const table = document.createElement('table');
          table.className = 'q-table';
          const thead = document.createElement('thead');
          const headTr = document.createElement('tr');
          for (const title of ['', '#', 'المعرّف', 'السؤال والتوضيح', 'المجال والمستوى', 'الحالة', 'إجراءات']) {
            const th = document.createElement('th');
            th.textContent = title;
            headTr.appendChild(th);
          }
          thead.appendChild(headTr);
          const tbody = document.createElement('tbody');

          data.items.forEach((q, idx) => {
            const tr = document.createElement('tr');
            if (state.selectedIds.has(q.id)) tr.classList.add('is-selected');

            const tdChk = document.createElement('td');
            tdChk.appendChild(createSelectionCheckbox(q, tr));

            const tdNum = document.createElement('td');
            tdNum.className = 'q-index';
            tdNum.textContent = String(startIdx + idx + 1);

            const tdId = document.createElement('td');
            tdId.appendChild(createCopyableIdPill(q.id));

            const tdBody = document.createElement('td');
            const qTxt = document.createElement('div');
            qTxt.style.fontWeight = '700';
            qTxt.style.color = 'var(--dark)';
            qTxt.textContent = q.text;
            tdBody.appendChild(qTxt);
            if (q.clarification) {
              const cTxt = document.createElement('div');
              cTxt.style.fontSize = '0.79rem';
              cTxt.style.color = 'var(--muted)';
              cTxt.style.marginTop = '0.2rem';
              cTxt.textContent = q.clarification;
              tdBody.appendChild(cTxt);
            }

            const tdMeta = document.createElement('td');
            tdMeta.style.whiteSpace = 'nowrap';
            const tP = document.createElement('div');
            tP.style.fontWeight = '700';
            tP.style.fontSize = '0.8rem';
            tP.textContent = TOPIC_LABELS[q.topic] || q.topic;
            const dP = document.createElement('div');
            dP.style.fontSize = '0.74rem';
            dP.style.color = 'var(--muted)';
            dP.textContent = (DEPTH_LABELS[q.depth] || q.depth) + ' · ' + q.suitableModes.map((m) => MODE_LABELS[m] || m).join('+');
            tdMeta.append(tP, dP);

            const tdStat = document.createElement('td');
            const sPill = document.createElement('span');
            sPill.className = q.isDevelopmentOnly ? 'pill pill-gold' : 'pill pill-success';
            sPill.textContent = q.isDevelopmentOnly ? 'مسودة' : 'معتمد';
            tdStat.appendChild(sPill);

            const tdAct = document.createElement('td');
            tdAct.appendChild(createQuestionActionButtons(q, true));

            tr.append(tdChk, tdNum, tdId, tdBody, tdMeta, tdStat, tdAct);
            tbody.appendChild(tr);
          });

          table.append(thead, tbody);
          wrap.appendChild(table);
          list.appendChild(wrap);
          syncBulkSelectionUi();
          return;
        }

        data.items.forEach((q, idx) => {
          const card = document.createElement('article');
          card.className =
            'item-card ' +
            (q.isDevelopmentOnly ? 'status-draft' : 'status-approved') +
            (state.selectedIds.has(q.id) ? ' is-selected' : '');

          const top = document.createElement('div');
          top.className = 'item-top';

          const badges = document.createElement('div');
          badges.className = 'meta-pills';

          const chk = createSelectionCheckbox(q, card);
          const idxLabel = document.createElement('span');
          idxLabel.className = 'q-index';
          idxLabel.textContent = '#' + (startIdx + idx + 1);

          const idPill = createCopyableIdPill(q.id);

          const topicPill = document.createElement('span');
          topicPill.className = 'pill';
          topicPill.textContent = TOPIC_LABELS[q.topic] || q.topic;

          const depthPill = document.createElement('span');
          depthPill.className = 'pill pill-gold';
          depthPill.textContent = DEPTH_LABELS[q.depth] || q.depth;

          const modesPill = document.createElement('span');
          modesPill.className = 'pill pill-muted';
          modesPill.textContent = q.suitableModes.map((m) => MODE_LABELS[m] || m).join(' + ');

          const statusPill = document.createElement('span');
          statusPill.className = q.isDevelopmentOnly ? 'pill pill-gold' : 'pill pill-success';
          statusPill.textContent = q.isDevelopmentOnly ? 'مسودة تطوير' : 'معتمد للنشر';

          badges.append(chk, idxLabel, idPill, topicPill, depthPill, modesPill, statusPill);
          top.append(badges, createQuestionActionButtons(q, false));

          const textEl = document.createElement('div');
          textEl.className = 'question-text';
          textEl.textContent = q.text;
          card.append(top, textEl);

          if (q.clarification) {
            const clarEl = document.createElement('div');
            clarEl.className = 'question-clarification';
            clarEl.textContent = q.clarification;
            card.appendChild(clarEl);
          }

          list.appendChild(card);
        });
        syncBulkSelectionUi();
      }

      function renderStatsShimmer(gridId, count) {
        const grid = el(gridId);
        if (!grid || grid.children.length > 0) return;
        for (let i = 0; i < count; i++) {
          const box = document.createElement('div');
          box.className = 'shimmer-stat';
          const l1 = document.createElement('div'); l1.className = 'shimmer-block shimmer-line short';
          const l2 = document.createElement('div'); l2.className = 'shimmer-block shimmer-line num';
          const l3 = document.createElement('div'); l3.className = 'shimmer-block shimmer-line short';
          box.append(l1, l2, l3);
          grid.appendChild(box);
        }
      }

      function renderListShimmer(listId, count, isTable) {
        const list = el(listId);
        if (!list) return;
        list.replaceChildren();
        if (isTable) {
          const wrap = document.createElement('div');
          wrap.className = 'q-table-wrap';
          const inner = document.createElement('div');
          inner.style.padding = '0.75rem';
          inner.style.display = 'flex';
          inner.style.flexDirection = 'column';
          inner.style.gap = '0.65rem';
          for (let i = 0; i < count; i++) {
            const row = document.createElement('div');
            row.className = 'shimmer-block shimmer-line';
            row.style.height = '26px';
            inner.appendChild(row);
          }
          wrap.appendChild(inner);
          list.appendChild(wrap);
          return;
        }
        for (let i = 0; i < count; i++) {
          const card = document.createElement('div');
          card.className = 'shimmer-card';
          const pills = document.createElement('div');
          pills.className = 'shimmer-pills';
          for (let p = 0; p < 3; p++) {
            const pl = document.createElement('div');
            pl.className = 'shimmer-block shimmer-pill';
            pills.appendChild(pl);
          }
          const l1 = document.createElement('div'); l1.className = 'shimmer-block shimmer-line med';
          const l2 = document.createElement('div'); l2.className = 'shimmer-block shimmer-line';
          card.append(pills, l1, l2);
          list.appendChild(card);
        }
      }

      async function refreshMeta() {
        state.meta = await apiFetch('/v1/questions/meta');
        renderMetaAndNotice();
      }

      async function loadQuestions() {
        renderStatsShimmer('statsGrid', 6);
        renderListShimmer('questionsList', state.viewMode === 'table' ? 6 : 4, state.viewMode === 'table');

        const params = new URLSearchParams();
        params.set('page', String(state.page));
        params.set('limit', String(state.limit));
        if (state.topic) params.set('topic', state.topic);
        if (state.depth) params.set('depth', state.depth);
        if (state.mode) params.set('mode', state.mode);
        if (state.isDevelopmentOnly) params.set('isDevelopmentOnly', state.isDevelopmentOnly);
        if (state.search) params.set('search', state.search);

        const data = await apiFetch('/v1/questions?' + params.toString());
        state.totalPages = data.totalPages;
        state.page = data.page;
        state.lastRenderData = data;
        renderStats(data.counts);
        renderQuestions(data);
      }

      async function reloadQuestionsAndMeta() {
        await Promise.all([refreshMeta(), loadQuestions()]);
      }

      function openEditorModal(question, cloneMode) {
        const isEdit = Boolean(question) && !cloneMode;
        state.editingQuestionId = isEdit ? question.id : null;
        el('editorModalTitle').textContent = cloneMode
          ? 'تكرار السؤال كجديد'
          : isEdit
            ? 'تعديل السؤال'
            : 'إضافة سؤال جديد';
        const idField = el('fieldId');
        idField.value = isEdit ? question.id : '';
        idField.disabled = isEdit;
        el('fieldIdHint').style.display = isEdit ? 'none' : 'block';
        el('fieldText').value = question ? question.text : '';
        el('fieldClarification').value = question && question.clarification ? question.clarification : '';
        el('fieldTopic').value = question ? question.topic : 'communication';
        el('fieldDepth').value = question ? question.depth : 'introductory';
        const modes = question ? question.suitableModes : ['together', 'phone'];
        el('modeTogether').checked = modes.includes('together');
        el('modePhone').checked = modes.includes('phone');
        el('fieldIsDev').checked = isEdit ? question.isDevelopmentOnly : true;
        el('formError').classList.remove('visible');
        el('editorModalBackdrop').classList.add('open');
        el('fieldText').focus();
      }

      function closeEditorModal() { el('editorModalBackdrop').classList.remove('open'); }
      function openBulkModal() {
        el('bulkError').classList.remove('visible');
        el('bulkInput').value = '';
        el('bulkModalBackdrop').classList.add('open');
        el('bulkInput').focus();
      }
      function closeBulkModal() { el('bulkModalBackdrop').classList.remove('open'); }

      function openDeleteModal(kind, item) {
        state.deleteContext = { kind, item };
        if (kind === 'questionsBulkApprove') {
          el('deleteModalTitle').textContent = 'تأكيد الاعتماد الجماعي';
          el('confirmDeleteBtn').textContent = 'اعتماد الكل';
          el('confirmDeleteBtn').className = 'btn btn-primary';
          el('deletePreviewText').textContent =
            'هل تريد اعتماد جميع مسودات الأسئلة المطابقة للتصفية الحالية لتصبح جاهزة للنشر في التطبيق؟';
        } else if (kind === 'questionsBulkDelete') {
          el('deleteModalTitle').textContent = 'تأكيد حذف المحدد';
          el('confirmDeleteBtn').textContent = 'حذف (' + item.ids.length + ')';
          el('confirmDeleteBtn').className = 'btn btn-danger';
          el('deletePreviewText').textContent =
            'هل تريد حذف الأسئلة المحددة نهائيًا؟ عددها: ' + item.ids.length + ' سؤال.';
        } else {
          el('deleteModalTitle').textContent =
            kind === 'license' ? 'إلغاء سجل الترخيص' : 'تأكيد الحذف';
          el('confirmDeleteBtn').textContent =
            kind === 'license' ? 'تأكيد الإلغاء' : 'حذف نهائي';
          el('confirmDeleteBtn').className = 'btn btn-danger';
          el('deletePreviewText').textContent =
            kind === 'question'
              ? 'هل تريد حذف السؤال "' + item.text + '" (' + item.id + ')؟'
              : kind === 'activity'
                ? 'هل تريد حذف النشاط "' + item.title + '" (' + item.id + ')؟'
                : 'هل تريد تعليم الترخيص "' + item.id + '" كملغى في السجل الإداري؟';
        }
        el('deleteError').classList.remove('visible');
        el('deleteModalBackdrop').classList.add('open');
      }
      function closeDeleteModal() {
        el('deleteModalBackdrop').classList.remove('open');
        state.deleteContext = null;
      }

      el('addQuestionBtn').addEventListener('click', () => openEditorModal(null));
      el('closeEditorBtn').addEventListener('click', closeEditorModal);
      el('cancelEditorBtn').addEventListener('click', closeEditorModal);
      el('bulkImportBtn').addEventListener('click', openBulkModal);
      el('closeBulkBtn').addEventListener('click', closeBulkModal);
      el('cancelBulkBtn').addEventListener('click', closeBulkModal);
      el('closeDeleteBtn').addEventListener('click', closeDeleteModal);
      el('cancelDeleteBtn').addEventListener('click', closeDeleteModal);

      el('questionForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const errEl = el('formError');
        errEl.classList.remove('visible');
        const modes = [];
        if (el('modeTogether').checked) modes.push('together');
        if (el('modePhone').checked) modes.push('phone');
        if (modes.length === 0) {
          errEl.textContent = 'اختر وضع جلسة واحدًا على الأقل.';
          errEl.classList.add('visible');
          return;
        }
        const payload = {
          text: el('fieldText').value.trim(),
          clarification: el('fieldClarification').value.trim(),
          topic: el('fieldTopic').value,
          depth: el('fieldDepth').value,
          suitableModes: modes,
          isDevelopmentOnly: el('fieldIsDev').checked,
        };
        if (!state.editingQuestionId && el('fieldId').value.trim()) {
          payload.id = el('fieldId').value.trim();
        }
        const btn = el('saveQuestionBtn');
        btn.disabled = true;
        try {
          if (state.editingQuestionId) {
            await apiFetch('/v1/questions/' + encodeURIComponent(state.editingQuestionId), {
              method: 'PATCH',
              body: JSON.stringify(payload),
            });
            showToast('تم تحديث السؤال بنجاح');
          } else {
            await apiFetch('/v1/questions', {
              method: 'POST',
              body: JSON.stringify(payload),
            });
            showToast('تمت إضافة السؤال بنجاح');
          }
          closeEditorModal();
          await reloadQuestionsAndMeta();
        } catch (err) {
          if (err.status === 401) handleUnauthorized();
          else {
            errEl.textContent = err.message;
            errEl.classList.add('visible');
          }
        } finally {
          btn.disabled = false;
        }
      });

      el('bulkForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const errEl = el('bulkError');
        errEl.classList.remove('visible');
        const raw = el('bulkInput').value.trim();
        if (!raw) return;

        let questions;
        try {
          if (raw.startsWith('[') || raw.startsWith('{')) {
            const parsed = JSON.parse(raw);
            questions = Array.isArray(parsed) ? parsed : parsed.questions;
            if (!Array.isArray(questions) || questions.length === 0) {
              throw new Error('JSON يجب أن يحتوي على مصفوفة أسئلة غير فارغة.');
            }
          } else {
            const topic = el('bulkTopic').value;
            const depth = el('bulkDepth').value;
            questions = raw
              .split(/\\r?\\n/)
              .map((line) => line.trim())
              .filter(Boolean)
              .map((line) => {
                const parts = line.split('|');
                return {
                  text: parts[0].trim(),
                  clarification: parts[1] ? parts[1].trim() : undefined,
                  topic,
                  depth,
                  suitableModes: ['together', 'phone'],
                  isDevelopmentOnly: true,
                };
              });
          }
        } catch (parseErr) {
          errEl.textContent = parseErr.message;
          errEl.classList.add('visible');
          return;
        }

        const btn = el('saveBulkBtn');
        btn.disabled = true;
        try {
          const res = await apiFetch('/v1/questions/bulk', {
            method: 'POST',
            body: JSON.stringify({ questions }),
          });
          closeBulkModal();
          showToast('تم استيراد ' + res.createdCount + ' سؤال بنجاح');
          await reloadQuestionsAndMeta();
        } catch (err) {
          if (err.status === 401) handleUnauthorized();
          else {
            errEl.textContent = err.message;
            errEl.classList.add('visible');
          }
        } finally {
          btn.disabled = false;
        }
      });

      el('confirmDeleteBtn').addEventListener('click', async () => {
        if (!state.deleteContext) return;
        const { kind, item } = state.deleteContext;
        const btn = el('confirmDeleteBtn');
        const errEl = el('deleteError');
        errEl.classList.remove('visible');
        btn.disabled = true;
        try {
          if (kind === 'question') {
            await apiFetch('/v1/questions/' + encodeURIComponent(item.id), { method: 'DELETE' });
            state.selectedIds.delete(item.id);
            closeDeleteModal();
            showToast('تم حذف السؤال بنجاح');
            await reloadQuestionsAndMeta();
          } else if (kind === 'questionsBulkDelete') {
            await executeBulkQuestionAction({ action: 'delete', ids: item.ids }, 'تم حذف الأسئلة المحددة');
            closeDeleteModal();
          } else if (kind === 'questionsBulkApprove') {
            await executeBulkQuestionAction({ action: 'approve', filter: item.filter }, 'تم اعتماد مسودات التصفية');
            closeDeleteModal();
          } else if (kind === 'activity') {
            await apiFetch('/v1/activities/' + encodeURIComponent(item.id), { method: 'DELETE' });
            closeDeleteModal();
            showToast('تم حذف النشاط بنجاح');
            await loadActivities();
          } else if (kind === 'license') {
            await apiFetch('/v1/licenses/' + encodeURIComponent(item.id) + '/revoke', {
              method: 'PATCH',
              body: JSON.stringify({ reason: 'تم الإلغاء من لوحة التحكم' }),
            });
            closeDeleteModal();
            showToast('تم تعليم الترخيص كملغى');
            await loadLicensesList();
          }
        } catch (err) {
          if (err.status === 401) {
            closeDeleteModal();
            handleUnauthorized();
          } else {
            errEl.textContent = err.message;
            errEl.classList.add('visible');
          }
        } finally {
          btn.disabled = false;
        }
      });

      /* Question Filters */
      el('searchInput').addEventListener('input', (e) => {
        clearTimeout(searchTimer);
        searchTimer = setTimeout(() => {
          state.search = e.target.value.trim();
          state.page = 1;
          void loadQuestions();
        }, 220);
      });
      el('topicFilter').addEventListener('change', (e) => { state.topic = e.target.value; state.page = 1; void loadQuestions(); });
      el('depthFilter').addEventListener('change', (e) => { state.depth = e.target.value; state.page = 1; void loadQuestions(); });
      el('modeFilter').addEventListener('change', (e) => { state.mode = e.target.value; state.page = 1; void loadQuestions(); });
      el('devFilter').addEventListener('change', (e) => { state.isDevelopmentOnly = e.target.value; state.page = 1; void loadQuestions(); });
      el('limitFilter').addEventListener('change', (e) => { state.limit = Number(e.target.value) || 25; state.page = 1; void loadQuestions(); });
      el('resetFiltersBtn').addEventListener('click', () => {
        state.search = ''; state.topic = ''; state.depth = ''; state.mode = ''; state.isDevelopmentOnly = ''; state.page = 1;
        el('searchInput').value = ''; el('topicFilter').value = ''; el('depthFilter').value = '';
        el('modeFilter').value = ''; el('devFilter').value = '';
        void loadQuestions();
      });
      el('prevPageBtn').addEventListener('click', () => { if (state.page > 1) { state.page -= 1; void loadQuestions(); } });
      el('nextPageBtn').addEventListener('click', () => { if (state.page < state.totalPages) { state.page += 1; void loadQuestions(); } });

      document.querySelectorAll('[data-dev-tab]').forEach((btn) => {
        btn.addEventListener('click', () => {
          state.isDevelopmentOnly = btn.dataset.devTab;
          el('devFilter').value = state.isDevelopmentOnly;
          state.page = 1;
          void loadQuestions();
        });
      });

      document.querySelectorAll('[data-view-mode]').forEach((btn) => {
        btn.addEventListener('click', () => {
          state.viewMode = btn.dataset.viewMode;
          if (state.lastRenderData) renderQuestions(state.lastRenderData);
        });
      });

      el('selectPageCheckbox').addEventListener('change', (e) => {
        const checked = e.target.checked;
        for (const q of state.currentItems || []) {
          if (checked) state.selectedIds.add(q.id);
          else state.selectedIds.delete(q.id);
        }
        if (state.lastRenderData) renderQuestions(state.lastRenderData);
      });

      el('bulkClearSelectionBtn').addEventListener('click', () => {
        state.selectedIds.clear();
        if (state.lastRenderData) renderQuestions(state.lastRenderData);
      });

      el('bulkApproveSelectedBtn').addEventListener('click', async () => {
        const ids = Array.from(state.selectedIds);
        if (ids.length === 0) return;
        try {
          await executeBulkQuestionAction({ action: 'approve', ids }, 'تم اعتماد المحدد');
        } catch (err) {
          if (err.status === 401) handleUnauthorized();
          else showToast(err.message);
        }
      });

      el('bulkDraftSelectedBtn').addEventListener('click', async () => {
        const ids = Array.from(state.selectedIds);
        if (ids.length === 0) return;
        try {
          await executeBulkQuestionAction({ action: 'draft', ids }, 'تم تحويل المحدد لمسودة');
        } catch (err) {
          if (err.status === 401) handleUnauthorized();
          else showToast(err.message);
        }
      });

      el('bulkDeleteSelectedBtn').addEventListener('click', () => {
        const ids = Array.from(state.selectedIds);
        if (ids.length === 0) return;
        openDeleteModal('questionsBulkDelete', { ids });
      });

      el('approveFilteredBtn').addEventListener('click', () => {
        const filter = {
          ...(state.topic ? { topic: state.topic } : {}),
          ...(state.depth ? { depth: state.depth } : {}),
          ...(state.mode ? { mode: state.mode } : {}),
          ...(state.search ? { search: state.search } : {}),
          isDevelopmentOnly: 'true',
        };
        openDeleteModal('questionsBulkApprove', { filter });
      });

      /* ---------------- Activities Tab ---------------- */
      function renderActivitiesStats(counts) {
        const grid = el('activitiesStatsGrid');
        grid.replaceChildren();
        if (!counts) return;
        const items = [
          { label: 'إجمالي الأنشطة', value: counts.total, meta: 'معتمد: ' + counts.approved + ' · مسودة: ' + counts.developmentOnly },
          { label: 'بطاقات سيناريو', value: counts.scenarios, meta: 'لو حصل كده؟' },
          { label: 'بطاقات ترتيب أولويات', value: counts.priorityOrdering, meta: 'رتّب أولوياتك' },
        ];
        for (const item of items) {
          const card = document.createElement('div');
          card.className = 'stat-card';
          const lbl = document.createElement('div'); lbl.className = 'stat-label'; lbl.textContent = item.label;
          const val = document.createElement('div'); val.className = 'stat-value'; val.textContent = String(item.value);
          const meta = document.createElement('div'); meta.className = 'stat-meta'; meta.textContent = item.meta;
          card.append(lbl, val, meta);
          grid.appendChild(card);
        }
      }

      function renderActivitiesList(data) {
        const list = el('activitiesList');
        list.replaceChildren();
        el('activitiesCountBadge').textContent = data.total + ' نشاط';

        if (!data.items || data.items.length === 0) {
          const empty = document.createElement('div');
          empty.className = 'empty-state';
          empty.textContent = 'لا توجد أنشطة مطابقة للتصفية الحالية.';
          list.appendChild(empty);
          return;
        }

        for (const act of data.items) {
          const card = document.createElement('article');
          card.className = 'item-card';

          const top = document.createElement('div');
          top.className = 'item-top';

          const badges = document.createElement('div');
          badges.className = 'meta-pills';

          const idPill = document.createElement('span');
          idPill.className = 'pill pill-id';
          idPill.textContent = act.id;

          const typePill = document.createElement('span');
          typePill.className = 'pill';
          typePill.textContent = ACTIVITY_TYPE_LABELS[act.type] || act.type;

          const topicPill = document.createElement('span');
          topicPill.className = 'pill pill-gold';
          topicPill.textContent = TOPIC_LABELS[act.topic] || act.topic;

          const statusPill = document.createElement('span');
          statusPill.className = act.isDevelopmentOnly ? 'pill pill-gold' : 'pill pill-success';
          statusPill.textContent = act.isDevelopmentOnly ? 'مسودة تطوير' : 'معتمد للنشر';

          badges.append(idPill, typePill, topicPill, statusPill);

          const actions = document.createElement('div');
          actions.className = 'item-actions';

          const toggleBtn = document.createElement('button');
          toggleBtn.type = 'button';
          toggleBtn.className = act.isDevelopmentOnly ? 'btn btn-primary btn-sm' : 'btn btn-gold btn-sm';
          toggleBtn.textContent = act.isDevelopmentOnly ? 'اعتماد' : 'إرجاع لمسودة';
          toggleBtn.addEventListener('click', async () => {
            try {
              await apiFetch('/v1/activities/' + encodeURIComponent(act.id), {
                method: 'PATCH',
                body: JSON.stringify({ isDevelopmentOnly: !act.isDevelopmentOnly }),
              });
              showToast('تم تحديث حالة النشاط');
              await loadActivities();
            } catch (err) {
              if (err.status === 401) handleUnauthorized();
              else showToast(err.message);
            }
          });

          const editBtn = document.createElement('button');
          editBtn.type = 'button';
          editBtn.className = 'btn btn-outline btn-sm';
          editBtn.textContent = 'تعديل';
          editBtn.addEventListener('click', () => openActivityModal(act));

          const delBtn = document.createElement('button');
          delBtn.type = 'button';
          delBtn.className = 'btn btn-danger btn-sm';
          delBtn.textContent = 'حذف';
          delBtn.addEventListener('click', () => openDeleteModal('activity', act));

          actions.append(toggleBtn, editBtn, delBtn);
          top.append(badges, actions);

          const titleEl = document.createElement('div');
          titleEl.className = 'question-text';
          titleEl.textContent = act.title;

          const sitEl = document.createElement('div');
          sitEl.className = 'question-clarification';
          sitEl.textContent = act.situation;

          card.append(top, titleEl, sitEl);

          if (act.options && act.options.length > 0) {
            const optWrap = document.createElement('div');
            optWrap.className = 'meta-pills';
            for (let i = 0; i < act.options.length; i += 1) {
              const chip = document.createElement('span');
              chip.className = 'pill pill-muted';
              chip.textContent = String(i + 1) + '. ' + act.options[i];
              optWrap.appendChild(chip);
            }
            card.appendChild(optWrap);
          }

          if (act.prompts && act.prompts.length > 0) {
            const prWrap = document.createElement('div');
            prWrap.style.fontSize = '0.86rem';
            prWrap.style.color = 'var(--muted)';
            for (const p of act.prompts) {
              const row = document.createElement('div');
              row.textContent = '• ' + p;
              prWrap.appendChild(row);
            }
            card.appendChild(prWrap);
          }

          list.appendChild(card);
        }
      }

      async function loadActivities() {
        renderStatsShimmer('activitiesStatsGrid', 3);
        renderListShimmer('activitiesList', 3, false);

        const params = new URLSearchParams();
        if (state.actType) params.set('type', state.actType);
        if (state.actTopic) params.set('topic', state.actTopic);
        if (state.actDev) params.set('isDevelopmentOnly', state.actDev);
        if (state.actSearch) params.set('search', state.actSearch);
        const data = await apiFetch('/v1/activities?' + params.toString());
        renderActivitiesStats(data.counts);
        renderActivitiesList(data);
      }

      function addArrayInputRow(containerId, value, placeholder) {
        const container = el(containerId);
        const row = document.createElement('div');
        row.className = 'array-row';
        const input = document.createElement('input');
        input.type = 'text';
        input.className = 'input';
        input.value = value || '';
        input.placeholder = placeholder;
        const removeBtn = document.createElement('button');
        removeBtn.type = 'button';
        removeBtn.className = 'btn btn-danger btn-sm';
        removeBtn.textContent = 'حذف';
        removeBtn.addEventListener('click', () => row.remove());
        row.append(input, removeBtn);
        container.appendChild(row);
      }

      function readArrayInputs(containerId) {
        return Array.from(el(containerId).querySelectorAll('input'))
          .map((inp) => inp.value.trim())
          .filter(Boolean);
      }

      function syncActivityTypeVisibility() {
        const isPrio = el('actFieldType').value === 'priorityOrdering';
        el('actOptionsGroup').style.display = isPrio ? 'block' : 'none';
      }

      function openActivityModal(act) {
        state.editingActivityId = act ? act.id : null;
        el('activityModalTitle').textContent = act ? 'تعديل النشاط' : 'إضافة نشاط جديد';
        const idInput = el('actFieldId');
        idInput.value = act ? act.id : '';
        idInput.disabled = Boolean(act);
        el('actFieldType').value = act ? act.type : 'scenario';
        el('actFieldTopic').value = act ? act.topic : 'communication';
        el('actFieldTitle').value = act ? act.title : '';
        el('actFieldSituation').value = act ? act.situation : '';
        el('actFieldIsDev').checked = act ? act.isDevelopmentOnly : true;

        el('actOptionsList').replaceChildren();
        const opts = act && act.options && act.options.length > 0 ? act.options : ['', ''];
        for (const o of opts) addArrayInputRow('actOptionsList', o, 'عنصر للترتيب...');

        el('actPromptsList').replaceChildren();
        const prs = act && act.prompts && act.prompts.length > 0 ? act.prompts : [''];
        for (const p of prs) addArrayInputRow('actPromptsList', p, 'سؤال أو محور نقاش...');

        syncActivityTypeVisibility();
        el('activityFormError').classList.remove('visible');
        el('activityModalBackdrop').classList.add('open');
        el('actFieldTitle').focus();
      }

      function closeActivityModal() { el('activityModalBackdrop').classList.remove('open'); }

      el('addActivityBtn').addEventListener('click', () => openActivityModal(null));
      el('closeActivityBtn').addEventListener('click', closeActivityModal);
      el('cancelActivityBtn').addEventListener('click', closeActivityModal);
      el('actFieldType').addEventListener('change', syncActivityTypeVisibility);
      el('addActOptionBtn').addEventListener('click', () =>
        addArrayInputRow('actOptionsList', '', 'عنصر للترتيب...'),
      );
      el('addActPromptBtn').addEventListener('click', () =>
        addArrayInputRow('actPromptsList', '', 'سؤال أو محور نقاش...'),
      );

      el('activityForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const errEl = el('activityFormError');
        errEl.classList.remove('visible');
        const type = el('actFieldType').value;
        const options = type === 'priorityOrdering' ? readArrayInputs('actOptionsList') : [];
        const prompts = readArrayInputs('actPromptsList');

        const payload = {
          type,
          topic: el('actFieldTopic').value,
          title: el('actFieldTitle').value.trim(),
          situation: el('actFieldSituation').value.trim(),
          options,
          prompts,
          isDevelopmentOnly: el('actFieldIsDev').checked,
        };
        if (!state.editingActivityId && el('actFieldId').value.trim()) {
          payload.id = el('actFieldId').value.trim();
        }
        const btn = el('saveActivityBtn');
        btn.disabled = true;
        try {
          if (state.editingActivityId) {
            await apiFetch('/v1/activities/' + encodeURIComponent(state.editingActivityId), {
              method: 'PATCH',
              body: JSON.stringify(payload),
            });
            showToast('تم تحديث النشاط بنجاح');
          } else {
            await apiFetch('/v1/activities', {
              method: 'POST',
              body: JSON.stringify(payload),
            });
            showToast('تمت إضافة النشاط بنجاح');
          }
          closeActivityModal();
          await loadActivities();
        } catch (err) {
          if (err.status === 401) handleUnauthorized();
          else {
            errEl.textContent = err.message;
            errEl.classList.add('visible');
          }
        } finally {
          btn.disabled = false;
        }
      });

      el('actSearchInput').addEventListener('input', (e) => {
        clearTimeout(actSearchTimer);
        actSearchTimer = setTimeout(() => { state.actSearch = e.target.value.trim(); void loadActivities(); }, 220);
      });
      el('actTypeFilter').addEventListener('change', (e) => { state.actType = e.target.value; void loadActivities(); });
      el('actTopicFilter').addEventListener('change', (e) => { state.actTopic = e.target.value; void loadActivities(); });
      el('actDevFilter').addEventListener('change', (e) => { state.actDev = e.target.value; void loadActivities(); });
      el('resetActFiltersBtn').addEventListener('click', () => {
        state.actSearch = ''; state.actType = ''; state.actTopic = ''; state.actDev = '';
        el('actSearchInput').value = ''; el('actTypeFilter').value = '';
        el('actTopicFilter').value = ''; el('actDevFilter').value = '';
        void loadActivities();
      });

      /* ---------------- App & Site Config Tab ---------------- */
      function updateAnnouncementPreview() {
        const enabled = el('cfgAnnEnabled').checked;
        const box = el('annPreviewBox');
        const msg = el('cfgAnnMessage').value.trim();
        const title = el('cfgAnnTitle').value.trim();
        const style = el('cfgAnnStyle').value;
        if (!enabled || !msg) {
          box.style.display = 'none';
          return;
        }
        box.style.display = 'flex';
        box.className = 'banner ' + (style === 'success' ? 'banner-success' : style === 'info' ? 'banner-info' : '');
        el('annPreviewTitle').textContent = title ? title + ': ' : '';
        el('annPreviewMsg').textContent = msg;
      }

      function addSimpleStringRow(listId, value, placeholder, maxItems) {
        const list = el(listId);
        if (maxItems && list.children.length >= maxItems) {
          showToast('الحد الأقصى ' + maxItems + ' عناصر');
          return;
        }
        const row = document.createElement('div');
        row.className = 'array-row';
        const input = document.createElement('input');
        input.type = 'text';
        input.className = 'input';
        input.value = value || '';
        input.placeholder = placeholder || '';
        const upBtn = document.createElement('button');
        upBtn.type = 'button';
        upBtn.className = 'btn btn-outline btn-sm';
        upBtn.textContent = '↑';
        upBtn.title = 'تقديم للأعلى';
        upBtn.addEventListener('click', () => {
          if (row.previousElementSibling) list.insertBefore(row, row.previousElementSibling);
        });
        const delBtn = document.createElement('button');
        delBtn.type = 'button';
        delBtn.className = 'btn btn-danger btn-sm';
        delBtn.textContent = 'حذف';
        delBtn.addEventListener('click', () => row.remove());
        row.append(input, upBtn, delBtn);
        list.appendChild(row);
      }

      function renderSimpleStringList(listId, items, placeholder, maxItems) {
        const list = el(listId);
        list.replaceChildren();
        for (const item of items || []) {
          addSimpleStringRow(listId, item, placeholder, maxItems);
        }
      }

      function readSimpleStringList(listId) {
        return Array.from(el(listId).querySelectorAll('input'))
          .map((inp) => inp.value.trim())
          .filter((v) => v.length > 0);
      }

      function appendStructuredCardRow(listId, item, cfg) {
        const list = el(listId);
        if (cfg.maxItems && list.children.length >= cfg.maxItems) {
          showToast('الحد الأقصى ' + cfg.maxItems + ' عناصر');
          return;
        }
        const card = document.createElement('div');
        card.className = 'cms-card-item';

        const head = document.createElement('div');
        head.className = 'cms-card-head';
        const label = document.createElement('strong');
        label.style.fontSize = '0.84rem';
        label.style.color = 'var(--primary)';
        label.textContent = cfg.itemLabel;

        const ctrl = document.createElement('div');
        ctrl.className = 'meta-pills';
        const upBtn = document.createElement('button');
        upBtn.type = 'button';
        upBtn.className = 'btn btn-outline btn-sm';
        upBtn.textContent = '↑ أعلى';
        upBtn.addEventListener('click', () => {
          if (card.previousElementSibling) list.insertBefore(card, card.previousElementSibling);
        });
        const delBtn = document.createElement('button');
        delBtn.type = 'button';
        delBtn.className = 'btn btn-danger btn-sm';
        delBtn.textContent = 'حذف';
        delBtn.addEventListener('click', () => card.remove());
        ctrl.append(upBtn, delBtn);
        head.append(label, ctrl);
        card.appendChild(head);

        const rowA = document.createElement('div');
        rowA.className = 'array-row';
        if (cfg.withIcon) {
          const iconIn = document.createElement('input');
          iconIn.type = 'text';
          iconIn.className = 'input';
          iconIn.style.width = '76px';
          iconIn.style.textAlign = 'center';
          iconIn.dataset.field = 'icon';
          iconIn.value = (item && item.icon) || '✨';
          iconIn.placeholder = 'أيقونة';
          rowA.appendChild(iconIn);
        }
        const inputA = document.createElement('input');
        inputA.type = 'text';
        inputA.className = 'input';
        inputA.dataset.field = cfg.keyA;
        inputA.value = (item && item[cfg.keyA]) || '';
        inputA.placeholder = cfg.phA || '';
        rowA.appendChild(inputA);
        card.appendChild(rowA);

        const inputB = document.createElement(cfg.textareaB ? 'textarea' : 'input');
        if (!cfg.textareaB) inputB.type = 'text';
        inputB.className = cfg.textareaB ? 'textarea' : 'input';
        if (cfg.textareaB) inputB.style.minHeight = '66px';
        inputB.dataset.field = cfg.keyB;
        inputB.value = (item && item[cfg.keyB]) || '';
        inputB.placeholder = cfg.phB || '';
        card.appendChild(inputB);

        list.appendChild(card);
      }

      function renderStructuredList(listId, items, cfg) {
        const list = el(listId);
        list.replaceChildren();
        for (const item of items || []) {
          appendStructuredCardRow(listId, item, cfg);
        }
      }

      function readStructuredList(listId, cfg) {
        const results = [];
        for (const card of Array.from(el(listId).children)) {
          const valA = card.querySelector('[data-field="' + cfg.keyA + '"]').value.trim();
          const valB = card.querySelector('[data-field="' + cfg.keyB + '"]').value.trim();
          if (!valA && !valB) continue;
          const entry = {};
          if (cfg.withIcon) {
            const iconVal = card.querySelector('[data-field="icon"]').value.trim();
            entry.icon = iconVal || '✨';
          }
          entry[cfg.keyA] = valA;
          entry[cfg.keyB] = valB;
          results.push(entry);
        }
        return results;
      }

      const CMS_LIST_CONFIG = {
        features: { maxItems: 8, itemLabel: 'بطاقة ميزة', withIcon: true, keyA: 'title', phA: 'عنوان الميزة', keyB: 'description', phB: 'شرح مختصر للميزة', textareaB: true },
        activities: { maxItems: 6, itemLabel: 'بطاقة نشاط', withIcon: true, keyA: 'title', phA: 'عنوان النشاط', keyB: 'description', phB: 'وصف النشاط بالموقع', textareaB: true },
        steps: { maxItems: 5, itemLabel: 'خطوة', withIcon: false, keyA: 'title', phA: 'عنوان الخطوة', keyB: 'description', phB: 'وصف الخطوة', textareaB: true },
        faq: { maxItems: 12, itemLabel: 'سؤال شائع', withIcon: false, keyA: 'question', phA: 'نص السؤال', keyB: 'answer', phB: 'الإجابة الواضحة', textareaB: true },
        samples: { maxItems: 6, itemLabel: 'سؤال نموذجي', withIcon: false, keyA: 'question', phA: 'نص السؤال المعروض', keyB: 'clarification', phB: 'التوضيح أو الهدف من السؤال', textareaB: false },
      };

      function syncCmsSampleTopicView() {
        const topic = state.cmsSampleTopic;
        document.querySelectorAll('[data-cms-topic]').forEach((btn) => {
          const active = btn.dataset.cmsTopic === topic;
          btn.className = active ? 'btn btn-primary btn-sm' : 'btn btn-outline btn-sm';
        });
        const items = (state.cmsSamplesDraft && state.cmsSamplesDraft[topic]) || [];
        renderStructuredList('cmsSamplesList', items, CMS_LIST_CONFIG.samples);
      }

      function saveCurrentCmsSampleTopicToDraft() {
        if (!state.cmsSamplesDraft) state.cmsSamplesDraft = {};
        state.cmsSamplesDraft[state.cmsSampleTopic] = readStructuredList(
          'cmsSamplesList',
          CMS_LIST_CONFIG.samples,
        );
      }

      function updateSiteLinks(websiteUrl) {
        const url = websiteUrl || 'https://wefaq-site.vercel.app';
        if (el('headerSiteLink')) el('headerSiteLink').href = url;
        if (el('cmsOpenSiteLink')) el('cmsOpenSiteLink').href = url;
      }

      function populateConfigForms(cfg) {
        state.appConfig = cfg;
        const contact = cfg.contact || {};
        el('cfgWhatsapp').value = contact.whatsappNumber || '';
        el('cfgWhatsappDisplay').value = contact.whatsappDisplay || '';
        el('cfgTelegramUrl').value = contact.telegramUrl || '';
        el('cfgTelegramDisplay').value = contact.telegramDisplay || '';
        el('cfgPhoneDisplay').value = contact.phoneDisplay || '';
        el('cfgEmail').value = contact.email || '';
        el('cfgSupportHours').value = contact.supportHours || '';
        el('cfgWebsiteUrl').value = contact.websiteUrl || '';
        el('cfgContactTemplate').value = contact.contactMessageTemplate || '';
        el('cfgSiteNotice').value = (cfg.branding && cfg.branding.siteNotice) || '';
        updateSiteLinks(contact.websiteUrl);

        el('cfgAnnEnabled').checked = Boolean(cfg.announcement && cfg.announcement.enabled);
        el('cfgAnnStyle').value = (cfg.announcement && cfg.announcement.style) || 'info';
        el('cfgAnnTitle').value = (cfg.announcement && cfg.announcement.title) || '';
        el('cfgAnnMessage').value = (cfg.announcement && cfg.announcement.message) || '';

        const features = cfg.features || {};
        el('cfgFeatSpark').checked = Boolean(features.quickSparkEnabled);
        el('cfgFeatActivities').checked = Boolean(features.activitiesEnabled);
        el('cfgFeatDisc').checked = Boolean(features.discEnabled);
        el('cfgFeatFeedback').checked = Boolean(features.feedbackEnabled);

        const release = cfg.appRelease || {};
        el('cfgLatestVer').value = release.latestVersion || '';
        el('cfgMinVer').value = release.minSupportedVersion || '';
        el('cfgDownloadUrl').value = release.downloadUrl || '';
        el('cfgReleaseNotes').value = release.releaseNotes || '';

        const branding = cfg.branding || {};
        const site = cfg.site || {};
        const contactForm = site.contactForm || {};
        renderSimpleStringList('cfgReasonsList', contactForm.reasons || [], 'مثال: طلب تفعيل تطبيق وفاق', 10);
        el('cfgNamePlaceholder').value = contactForm.namePlaceholder || '';
        el('cfgNotesPlaceholder').value = contactForm.notesPlaceholder || '';
        el('cfgPreviewHeading').value = contactForm.previewHeading || '';
        el('cfgPreviewHint').value = contactForm.previewHint || '';

        el('cmsRevisionBadge').textContent = 'مراجعة #' + (cfg.revision || 1);
        const meta = site.meta || {};
        el('cmsBrandName').value = meta.brandName || '';
        el('cmsPageTitle').value = meta.pageTitle || '';
        el('cmsFooterText').value = meta.footerText || '';

        el('cfgBrandBadge').value = branding.badgeText || '';
        el('cfgBrandTitle').value = branding.heroTitle || '';
        el('cfgBrandSubtitle').value = branding.heroSubtitle || '';

        const hero = site.hero || {};
        el('cmsPrimaryCta').value = hero.primaryCtaLabel || '';
        el('cmsSecondaryCta').value = hero.secondaryCtaLabel || '';
        el('cmsDownloadCta').value = hero.downloadCtaLabel || '';
        renderSimpleStringList('cmsTrustPillsList', hero.trustPills || [], 'مثال: ✓ يعمل دون إنترنت', 6);
        el('cmsMockupTitle').value = hero.mockupTitle || '';
        el('cmsMockupSubtitle').value = hero.mockupSubtitle || '';
        el('cmsMockupQuestion').value = hero.mockupQuestion || '';
        el('cmsMockupClarify').value = hero.mockupClarify || '';

        const sec = site.sections || {};
        el('cmsShowFeatures').checked = sec.showFeatures !== false;
        el('cmsFeaturesBadge').value = sec.featuresBadge || '';
        el('cmsFeaturesTitle').value = sec.featuresTitle || '';
        el('cmsFeaturesSubtitle').value = sec.featuresSubtitle || '';

        el('cmsShowExplorer').checked = sec.showExplorer !== false;
        el('cmsExplorerBadge').value = sec.explorerBadge || '';
        el('cmsExplorerTitle').value = sec.explorerTitle || '';
        el('cmsExplorerSubtitle').value = sec.explorerSubtitle || '';

        el('cmsShowActivities').checked = sec.showActivities !== false;
        el('cmsActivitiesBadge').value = sec.activitiesBadge || '';
        el('cmsActivitiesTitle').value = sec.activitiesTitle || '';
        el('cmsActivitiesSubtitle').value = sec.activitiesSubtitle || '';

        el('cmsShowHowItWorks').checked = sec.showHowItWorks !== false;
        el('cmsHowBadge').value = sec.howItWorksBadge || '';
        el('cmsHowTitle').value = sec.howItWorksTitle || '';
        el('cmsHowSubtitle').value = sec.howItWorksSubtitle || '';

        el('cmsShowContact').checked = sec.showContact !== false;
        el('cmsContactBadge').value = sec.contactBadge || '';
        el('cmsContactTitle').value = sec.contactTitle || '';
        el('cmsContactSubtitle').value = sec.contactSubtitle || '';

        el('cmsShowFaq').checked = sec.showFaq !== false;
        el('cmsFaqBadge').value = sec.faqBadge || '';
        el('cmsFaqTitle').value = sec.faqTitle || '';
        el('cmsShowBoundaries').checked = sec.showBoundaries !== false;

        renderStructuredList('cmsFeaturesCardsList', site.featuresCards || [], CMS_LIST_CONFIG.features);
        renderStructuredList('cmsActivitiesCardsList', site.activitiesCards || [], CMS_LIST_CONFIG.activities);
        renderStructuredList('cmsStepsList', site.steps || [], CMS_LIST_CONFIG.steps);
        renderStructuredList('cmsFaqList', site.faq || [], CMS_LIST_CONFIG.faq);

        if (el('cmsCountCardsSub')) {
          el('cmsCountCardsSub').textContent =
            (site.featuresCards ? site.featuresCards.length : 0) +
            ' ميزات · ' +
            (site.activitiesCards ? site.activitiesCards.length : 0) +
            ' أنشطة · ' +
            (site.steps ? site.steps.length : 0) +
            ' خطوات';
        }
        if (el('cmsCountFaqSub')) {
          el('cmsCountFaqSub').textContent =
            (site.faq ? site.faq.length : 0) + ' أسئلة وإجابات';
        }

        const boundaries = site.boundaries || {};
        el('cmsWhatIsTitle').value = boundaries.whatIsTitle || '';
        renderSimpleStringList('cmsWhatIsList', boundaries.whatIsItems || [], 'بند عن نظام وفاق', 8);
        el('cmsWhatIsNotTitle').value = boundaries.whatIsNotTitle || '';
        renderSimpleStringList('cmsWhatIsNotList', boundaries.whatIsNotItems || [], 'حد أو ما لا يقدمه النظام', 8);

        const priv = site.privacyPage || {};
        el('cmsPrivacyBadge').value = priv.badge || '';
        el('cmsPrivacyTitle').value = priv.title || '';
        el('cmsPrivacySubtitle').value = priv.subtitle || '';

        state.cmsSamplesDraft = JSON.parse(JSON.stringify(site.sampleQuestions || {}));
        syncCmsSampleTopicView();
        updateAnnouncementPreview();
        updateAppContactLivePreview();
      }

      async function loadAppConfig() {
        const cfg = await apiFetch('/v1/app-config');
        populateConfigForms(cfg);
        return cfg;
      }

      el('cfgAnnEnabled').addEventListener('change', updateAnnouncementPreview);
      el('cfgAnnStyle').addEventListener('change', updateAnnouncementPreview);
      el('cfgAnnTitle').addEventListener('input', updateAnnouncementPreview);
      el('cfgAnnMessage').addEventListener('input', updateAnnouncementPreview);

      el('cfgAddReasonBtn').addEventListener('click', () => addSimpleStringRow('cfgReasonsList', '', 'مثال: طلب تفعيل لجهازين', 10));
      el('cmsAddTrustPillBtn').addEventListener('click', () => addSimpleStringRow('cmsTrustPillsList', '', '✓ ميزة مختصرة', 6));
      el('cmsAddWhatIsBtn').addEventListener('click', () => addSimpleStringRow('cmsWhatIsList', '', 'وصف توضيحي عن النظام', 8));
      el('cmsAddWhatIsNotBtn').addEventListener('click', () => addSimpleStringRow('cmsWhatIsNotList', '', 'حد أو توضيح أخلاقي', 8));
      el('cmsAddFeatureCardBtn').addEventListener('click', () => appendStructuredCardRow('cmsFeaturesCardsList', { icon: '✨' }, CMS_LIST_CONFIG.features));
      el('cmsAddActivityCardBtn').addEventListener('click', () => appendStructuredCardRow('cmsActivitiesCardsList', { icon: '🎯' }, CMS_LIST_CONFIG.activities));
      el('cmsAddStepBtn').addEventListener('click', () => appendStructuredCardRow('cmsStepsList', {}, CMS_LIST_CONFIG.steps));
      el('cmsAddFaqBtn').addEventListener('click', () => appendStructuredCardRow('cmsFaqList', {}, CMS_LIST_CONFIG.faq));
      el('cmsAddSampleBtn').addEventListener('click', () => appendStructuredCardRow('cmsSamplesList', {}, CMS_LIST_CONFIG.samples));

      function switchStudioSection(secAttr, panePrefix, secName) {
        let activeBtn = null;
        document.querySelectorAll('[' + secAttr + ']').forEach((btn) => {
          const isMatch = btn.getAttribute(secAttr) === secName;
          btn.classList.toggle('active', isMatch);
          if (isMatch) activeBtn = btn;
        });
        document.querySelectorAll('[id^="' + panePrefix + '"]').forEach((pane) => {
          pane.classList.toggle('active', pane.id === panePrefix + secName);
        });
        if (activeBtn && window.innerWidth <= 980) {
          activeBtn.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
        }
      }

      function bindSideStudio(secAttr, nextAttr, panePrefix) {
        document.querySelectorAll('[' + secAttr + ']').forEach((btn) => {
          btn.addEventListener('click', () =>
            switchStudioSection(secAttr, panePrefix, btn.getAttribute(secAttr)),
          );
        });
        if (nextAttr) {
          document.querySelectorAll('[' + nextAttr + ']').forEach((btn) => {
            btn.addEventListener('click', () => {
              switchStudioSection(secAttr, panePrefix, btn.getAttribute(nextAttr));
              if (window.innerWidth <= 980) {
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }
            });
          });
        }
      }

      bindSideStudio('data-cms-sec', 'data-cms-next', 'cms-pane-');
      bindSideStudio('data-app-sec', 'data-app-next', 'app-pane-');
      bindSideStudio('data-lic-sec', 'data-lic-next', 'lic-pane-');

      function updateAppContactLivePreview() {
        const preview = el('cfgContactLivePreview');
        if (!preview) return;
        const tpl = el('cfgContactTemplate').value.trim() || 'السلام عليكم، أود التواصل مع فريق وفاق:';
        const reasons = readSimpleStringList('cfgReasonsList');
        const firstReason = reasons[0] || 'طلب كود تفعيل لتطبيق وفاق';
        preview.textContent = [
          tpl,
          '- الموضوع: ' + firstReason,
          '- الاسم: أحمد',
          '- معرّف التثبيت: inst_12345678-...',
        ].join('\\n');
      }

      el('cfgContactTemplate').addEventListener('input', updateAppContactLivePreview);
      el('cfgReasonsList').addEventListener('input', updateAppContactLivePreview);
      el('cfgAddReasonBtn').addEventListener('click', () => setTimeout(updateAppContactLivePreview, 0));

      document.querySelectorAll('[data-cms-topic]').forEach((btn) => {
        btn.addEventListener('click', () => {
          saveCurrentCmsSampleTopicToDraft();
          state.cmsSampleTopic = btn.dataset.cmsTopic;
          syncCmsSampleTopicView();
        });
      });

      el('cmsPullSamplesBtn').addEventListener('click', async () => {
        try {
          const res = await apiFetch('/v1/questions?topic=' + encodeURIComponent(state.cmsSampleTopic) + '&devOnly=false&limit=3&page=1');
          const mapped = (res.items || []).map((q) => ({
            question: q.text || '',
            clarification: q.clarification || '',
          }));
          if (mapped.length === 0) {
            showToast('لا توجد أسئلة معتمدة لهذا المحور حاليًا');
            return;
          }
          if (!state.cmsSamplesDraft) state.cmsSamplesDraft = {};
          state.cmsSamplesDraft[state.cmsSampleTopic] = mapped;
          syncCmsSampleTopicView();
          showToast('تم استيراد ' + mapped.length + ' أسئلة معتمدة (اضغط حفظ لنشرها في الموقع)');
        } catch (err) {
          showToast(err.message);
        }
      });

      el('cmsReloadBtn').addEventListener('click', async () => {
        try {
          await loadAppConfig();
          showToast('تم تحديث بيانات الموقع والتطبيق من الخادم');
        } catch (err) {
          if (err.status === 401) handleUnauthorized();
          else showToast(err.message);
        }
      });

      el('appConfigForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const errEl = el('appConfigError');
        errEl.classList.remove('visible');
        const btn = el('saveAppConfigBtn');
        const btnBot = el('saveAppConfigBottomBtn');
        btn.disabled = true;
        if (btnBot) btnBot.disabled = true;
        try {
          const payload = {
            contact: {
              whatsappNumber: el('cfgWhatsapp').value.trim(),
              whatsappDisplay: el('cfgWhatsappDisplay').value.trim(),
              telegramUrl: el('cfgTelegramUrl').value.trim(),
              telegramDisplay: el('cfgTelegramDisplay').value.trim(),
              phoneDisplay: el('cfgPhoneDisplay').value.trim(),
              email: el('cfgEmail').value.trim(),
              supportHours: el('cfgSupportHours').value.trim(),
              websiteUrl: el('cfgWebsiteUrl').value.trim(),
              contactMessageTemplate: el('cfgContactTemplate').value.trim(),
            },
            announcement: {
              enabled: el('cfgAnnEnabled').checked,
              style: el('cfgAnnStyle').value,
              title: el('cfgAnnTitle').value.trim(),
              message: el('cfgAnnMessage').value.trim(),
            },
            features: {
              quickSparkEnabled: el('cfgFeatSpark').checked,
              activitiesEnabled: el('cfgFeatActivities').checked,
              discEnabled: el('cfgFeatDisc').checked,
              feedbackEnabled: el('cfgFeatFeedback').checked,
            },
            appRelease: {
              latestVersion: el('cfgLatestVer').value.trim(),
              minSupportedVersion: el('cfgMinVer').value.trim(),
              downloadUrl: el('cfgDownloadUrl').value.trim(),
              releaseNotes: el('cfgReleaseNotes').value.trim(),
            },
            branding: {
              siteNotice: el('cfgSiteNotice').value.trim(),
            },
            site: {
              contactForm: {
                reasons: readSimpleStringList('cfgReasonsList'),
                namePlaceholder: el('cfgNamePlaceholder').value.trim(),
                notesPlaceholder: el('cfgNotesPlaceholder').value.trim(),
                previewHeading: el('cfgPreviewHeading').value.trim(),
                previewHint: el('cfgPreviewHint').value.trim(),
              },
            },
          };
          const res = await apiFetch('/v1/app-config', {
            method: 'PATCH',
            body: JSON.stringify(payload),
          });
          populateConfigForms(res.config);
          showToast('تم حفظ إعدادات التطبيق وقنوات التواصل (مراجعة #' + res.config.revision + ')');
        } catch (err) {
          if (err.status === 401) handleUnauthorized();
          else {
            errEl.textContent = err.message;
            errEl.classList.add('visible');
          }
        } finally {
          btn.disabled = false;
          if (btnBot) btnBot.disabled = false;
        }
      });

      el('siteCmsForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const errEl = el('siteCmsError');
        errEl.classList.remove('visible');
        const btnTop = el('saveSiteCmsBtn');
        const btnBot = el('saveSiteCmsBottomBtn');
        btnTop.disabled = true;
        btnBot.disabled = true;
        try {
          saveCurrentCmsSampleTopicToDraft();
          const payload = {
            branding: {
              badgeText: el('cfgBrandBadge').value.trim(),
              heroTitle: el('cfgBrandTitle').value.trim(),
              heroSubtitle: el('cfgBrandSubtitle').value.trim(),
            },
            site: {
              meta: {
                brandName: el('cmsBrandName').value.trim(),
                pageTitle: el('cmsPageTitle').value.trim(),
                footerText: el('cmsFooterText').value.trim(),
              },
              hero: {
                primaryCtaLabel: el('cmsPrimaryCta').value.trim(),
                secondaryCtaLabel: el('cmsSecondaryCta').value.trim(),
                downloadCtaLabel: el('cmsDownloadCta').value.trim(),
                trustPills: readSimpleStringList('cmsTrustPillsList'),
                mockupTitle: el('cmsMockupTitle').value.trim(),
                mockupSubtitle: el('cmsMockupSubtitle').value.trim(),
                mockupQuestion: el('cmsMockupQuestion').value.trim(),
                mockupClarify: el('cmsMockupClarify').value.trim(),
              },
              sections: {
                showFeatures: el('cmsShowFeatures').checked,
                featuresBadge: el('cmsFeaturesBadge').value.trim(),
                featuresTitle: el('cmsFeaturesTitle').value.trim(),
                featuresSubtitle: el('cmsFeaturesSubtitle').value.trim(),
                showExplorer: el('cmsShowExplorer').checked,
                explorerBadge: el('cmsExplorerBadge').value.trim(),
                explorerTitle: el('cmsExplorerTitle').value.trim(),
                explorerSubtitle: el('cmsExplorerSubtitle').value.trim(),
                showActivities: el('cmsShowActivities').checked,
                activitiesBadge: el('cmsActivitiesBadge').value.trim(),
                activitiesTitle: el('cmsActivitiesTitle').value.trim(),
                activitiesSubtitle: el('cmsActivitiesSubtitle').value.trim(),
                showHowItWorks: el('cmsShowHowItWorks').checked,
                howItWorksBadge: el('cmsHowBadge').value.trim(),
                howItWorksTitle: el('cmsHowTitle').value.trim(),
                howItWorksSubtitle: el('cmsHowSubtitle').value.trim(),
                showContact: el('cmsShowContact').checked,
                contactBadge: el('cmsContactBadge').value.trim(),
                contactTitle: el('cmsContactTitle').value.trim(),
                contactSubtitle: el('cmsContactSubtitle').value.trim(),
                showFaq: el('cmsShowFaq').checked,
                faqBadge: el('cmsFaqBadge').value.trim(),
                faqTitle: el('cmsFaqTitle').value.trim(),
                showBoundaries: el('cmsShowBoundaries').checked,
              },
              featuresCards: readStructuredList('cmsFeaturesCardsList', CMS_LIST_CONFIG.features),
              activitiesCards: readStructuredList('cmsActivitiesCardsList', CMS_LIST_CONFIG.activities),
              steps: readStructuredList('cmsStepsList', CMS_LIST_CONFIG.steps),
              faq: readStructuredList('cmsFaqList', CMS_LIST_CONFIG.faq),
              boundaries: {
                whatIsTitle: el('cmsWhatIsTitle').value.trim(),
                whatIsItems: readSimpleStringList('cmsWhatIsList'),
                whatIsNotTitle: el('cmsWhatIsNotTitle').value.trim(),
                whatIsNotItems: readSimpleStringList('cmsWhatIsNotList'),
              },
              privacyPage: {
                badge: el('cmsPrivacyBadge').value.trim(),
                title: el('cmsPrivacyTitle').value.trim(),
                subtitle: el('cmsPrivacySubtitle').value.trim(),
              },
              sampleQuestions: state.cmsSamplesDraft || {},
            },
          };
          const res = await apiFetch('/v1/app-config', {
            method: 'PATCH',
            body: JSON.stringify(payload),
          });
          populateConfigForms(res.config);
          showToast('تم حفظ ونشر محتوى الموقع بنجاح (مراجعة #' + res.config.revision + ')');
        } catch (err) {
          if (err.status === 401) handleUnauthorized();
          else {
            errEl.textContent = err.message;
            errEl.classList.add('visible');
          }
        } finally {
          btnTop.disabled = false;
          btnBot.disabled = false;
        }
      });

      /* ---------------- Licenses & Keygen Tab ---------------- */
      function createRandomInstId() {
        const bytes = new Uint8Array(16);
        crypto.getRandomValues(bytes);
        bytes[6] = (bytes[6] & 0x0f) | 0x40;
        bytes[8] = (bytes[8] & 0x3f) | 0x80;
        const hex = Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');
        return 'inst_' + hex.slice(0, 8) + '-' + hex.slice(8, 12) + '-' + hex.slice(12, 16) + '-' + hex.slice(16, 20) + '-' + hex.slice(20);
      }

      function addDeviceInputRow(value) {
        const list = el('devicesInputList');
        if (list.children.length >= 20) {
          showToast('الحد الأقصى 20 جهازًا لكل كود');
          return;
        }
        const row = document.createElement('div');
        row.className = 'array-row';
        const input = document.createElement('input');
        input.type = 'text';
        input.className = 'input';
        input.dir = 'ltr';
        input.value = value || '';
        input.placeholder = 'inst_xxxxxxxx-xxxx-4xxx-xxxx-xxxxxxxxxxxx';
        const removeBtn = document.createElement('button');
        removeBtn.type = 'button';
        removeBtn.className = 'btn btn-danger btn-sm';
        removeBtn.textContent = 'حذف';
        removeBtn.addEventListener('click', () => {
          if (list.children.length > 1) row.remove();
          else input.value = '';
        });
        row.append(input, removeBtn);
        list.appendChild(row);
      }

      function resetDeviceInputs(devices) {
        const list = el('devicesInputList');
        list.replaceChildren();
        const items = devices && devices.length > 0 ? devices : ['', ''];
        for (const d of items) addDeviceInputRow(d);
      }

      async function loadLicenseConfig() {
        const cfg = await apiFetch('/v1/licenses/config');
        state.licenseConfig = cfg;
        const badge = el('serverKeyBadge');
        if (cfg.serverKeyConfigured) {
          badge.textContent = 'مفتاح الخادم مهيأ ✓';
          badge.className = 'pill pill-success';
          el('licPublicKeyDisplay').value = cfg.publicKey || '';
        } else {
          badge.textContent = 'بدون LICENSE_PRIVATE_SEED بالخادم';
          badge.className = 'pill pill-gold';
          el('licPublicKeyDisplay').value = state.lastKeygenPub || '';
        }
        if (cfg.defaultLinkHost && !el('licLinkHost').value) {
          el('licLinkHost').value = cfg.defaultLinkHost;
        }
      }

      async function loadLicensesList() {
        renderListShimmer('licensesList', 3, false);

        const params = new URLSearchParams();
        const q = el('licSearchInput').value.trim();
        const st = el('licStatusFilter').value;
        if (q) params.set('search', q);
        if (st) params.set('status', st);
        const data = await apiFetch('/v1/licenses?' + params.toString());
        if (el('licCountSideSub')) {
          el('licCountSideSub').textContent = (data.items ? data.items.length : 0) + ' سجل محفوظ';
        }
        const list = el('licensesList');
        list.replaceChildren();

        if (!data.items || data.items.length === 0) {
          const empty = document.createElement('div');
          empty.className = 'empty-state';
          empty.textContent = 'لا توجد تراخيص مصدرة مطابقة للبحث.';
          list.appendChild(empty);
          return;
        }

        const now = Date.now();
        for (const lic of data.items) {
          const card = document.createElement('article');
          card.className = 'item-card';

          const top = document.createElement('div');
          top.className = 'item-top';

          const badges = document.createElement('div');
          badges.className = 'meta-pills';

          const idPill = document.createElement('span');
          idPill.className = 'pill pill-id';
          idPill.textContent = lic.id;

          const isExpired = lic.expiresAt && Date.parse(lic.expiresAt) <= now;
          const stPill = document.createElement('span');
          if (lic.status === 'revoked') {
            stPill.className = 'pill pill-danger';
            stPill.textContent = 'ملغى';
          } else if (isExpired) {
            stPill.className = 'pill pill-gold';
            stPill.textContent = 'منتهي الصلاحية';
          } else {
            stPill.className = 'pill pill-success';
            stPill.textContent = 'ساري';
          }

          const devPill = document.createElement('span');
          devPill.className = 'pill';
          devPill.textContent = lic.devices.length + ' جهاز';

          const quotaPill = document.createElement('span');
          quotaPill.className = 'pill pill-muted';
          quotaPill.textContent = lic.sessionLimit ? lic.sessionLimit + ' جلسة' : 'جلسات غير محدودة';

          badges.append(idPill, stPill, devPill, quotaPill);
          if (lic.expiresAt) {
            const expPill = document.createElement('span');
            expPill.className = 'pill pill-muted';
            expPill.textContent = 'ينتهي: ' + lic.expiresAt.slice(0, 10);
            badges.appendChild(expPill);
          }

          const actions = document.createElement('div');
          actions.className = 'item-actions';

          const replaceBtn = document.createElement('button');
          replaceBtn.type = 'button';
          replaceBtn.className = 'btn btn-outline btn-sm';
          replaceBtn.textContent = 'استبدال جهاز / تجديد';
          replaceBtn.addEventListener('click', () => {
            state.replacedFromId = lic.id;
            el('licLabel').value = lic.label ? lic.label + ' (تجديد)' : 'بديل ' + lic.id;
            el('licCustomId').value = '';
            el('licSessionLimit').value = lic.sessionLimit ? String(lic.sessionLimit) : '';
            resetDeviceInputs(lic.devices);
            switchStudioSection('data-lic-sec', 'lic-pane-', 'issue');
            showToast('تم تجهيز بيانات الترخيص لاستبدال جهاز أو تجديده');
            window.scrollTo({ top: 0, behavior: 'smooth' });
          });

          actions.appendChild(replaceBtn);
          if (lic.status === 'active') {
            const revBtn = document.createElement('button');
            revBtn.type = 'button';
            revBtn.className = 'btn btn-danger btn-sm';
            revBtn.textContent = 'إلغاء';
            revBtn.addEventListener('click', () => openDeleteModal('license', lic));
            actions.appendChild(revBtn);
          }

          top.append(badges, actions);
          card.appendChild(top);

          if (lic.label) {
            const lblEl = document.createElement('div');
            lblEl.style.fontWeight = '700';
            lblEl.textContent = lic.label;
            card.appendChild(lblEl);
          }

          const devListEl = document.createElement('div');
          devListEl.className = 'meta-pills';
          for (const dev of lic.devices) {
            const dp = document.createElement('span');
            dp.className = 'pill pill-id';
            dp.textContent = dev;
            devListEl.appendChild(dp);
          }
          card.appendChild(devListEl);

          if (lic.revokedReason) {
            const reasonEl = document.createElement('div');
            reasonEl.style.fontSize = '0.82rem';
            reasonEl.style.color = 'var(--danger)';
            reasonEl.textContent = 'سبب الإلغاء: ' + lic.revokedReason;
            card.appendChild(reasonEl);
          }

          list.appendChild(card);
        }
      }

      async function loadLicensesTab() {
        if (el('devicesInputList').children.length === 0) {
          resetDeviceInputs(['', '']);
        }
        if (!state.lastKeygenSeed && el('licSessionSeedInput')) {
          el('licSessionSeedInput').value = '';
        }
        await Promise.all([loadLicenseConfig(), loadLicensesList()]);
      }

      if (el('licSessionSeedInput')) {
        const seedInput = el('licSessionSeedInput');
        const unlockSeed = () => {
          if (seedInput.hasAttribute('readonly')) seedInput.removeAttribute('readonly');
        };
        seedInput.addEventListener('focus', unlockSeed);
        seedInput.addEventListener('pointerdown', unlockSeed);
      }
      if (el('toggleSeedVisBtn')) {
        el('toggleSeedVisBtn').addEventListener('click', () => {
          const inp = el('licSessionSeedInput');
          inp.removeAttribute('readonly');
          const hidden = inp.type === 'password';
          inp.type = hidden ? 'text' : 'password';
          el('toggleSeedVisBtn').textContent = hidden ? 'إخفاء' : 'إظهار';
        });
      }
      if (el('jumpToKeysBtn')) {
        el('jumpToKeysBtn').addEventListener('click', () =>
          switchStudioSection('data-lic-sec', 'lic-pane-', 'keys'),
        );
      }

      el('addDeviceSlotBtn').addEventListener('click', () => addDeviceInputRow(''));
      el('addSampleDeviceBtn').addEventListener('click', () => {
        const inputs = Array.from(el('devicesInputList').querySelectorAll('input'));
        const emptyInput = inputs.find((inp) => !inp.value.trim());
        const sample = createRandomInstId();
        if (emptyInput) emptyInput.value = sample;
        else addDeviceInputRow(sample);
        showToast('تمت إضافة معرّف تثبيت اختباري');
      });

      document.querySelectorAll('.preset-btn').forEach((btn) => {
        btn.addEventListener('click', () => {
          document.querySelectorAll('.preset-btn').forEach((b) =>
            b.classList.toggle('active', b === btn),
          );
          const p = btn.dataset.preset;
          if (p === 'trial') {
            el('licSessionLimit').value = '5';
            el('licDurationDays').value = '14';
          } else if (p === 'couple') {
            el('licSessionLimit').value = '20';
            el('licDurationDays').value = '180';
          } else if (p === 'unlimited') {
            el('licSessionLimit').value = '';
            el('licDurationDays').value = '365';
          }
        });
      });

      ['licSessionLimit', 'licDurationDays'].forEach((id) => {
        if (el(id)) {
          el(id).addEventListener('input', () => {
            document.querySelectorAll('.preset-btn').forEach((b) => b.classList.remove('active'));
          });
        }
      });

      el('generateKeyPairBtn').addEventListener('click', async () => {
        try {
          const keys = await apiFetch('/v1/licenses/keygen', { method: 'POST' });
          state.lastKeygenSeed = keys.privateSeedBase64Url;
          state.lastKeygenPub = keys.publicKeyBase64Url;
          el('keygenSeedOutput').textContent = keys.privateSeedBase64Url;
          el('keygenPubOutput').textContent = keys.publicKeyBase64Url;
          el('keygenResultBox').style.display = 'flex';
          showToast('تم توليد زوج مفاتيح Ed25519 جديد');
        } catch (err) {
          if (err.status === 401) handleUnauthorized();
          else showToast(err.message);
        }
      });

      el('useGeneratedSeedBtn').addEventListener('click', () => {
        if (!state.lastKeygenSeed) return;
        el('licSessionSeedInput').value = state.lastKeygenSeed;
        el('licPublicKeyDisplay').value = state.lastKeygenPub;
        showToast('تم تفعيل المفتاح المولّد في هذه الجلسة');
      });

      el('copyKeygenEnvBtn').addEventListener('click', () => {
        if (!state.lastKeygenPub) return;
        void copyText(
          'WEFAQ_LICENSE_PUBLIC_KEY=' + state.lastKeygenPub,
          'تم نسخ سطر WEFAQ_LICENSE_PUBLIC_KEY',
        );
      });

      el('copyPublicKeyBtn').addEventListener('click', () => {
        void copyText(el('licPublicKeyDisplay').value.trim(), 'تم نسخ المفتاح العام');
      });

      el('licenseForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const errEl = el('licenseFormError');
        errEl.classList.remove('visible');
        const devices = readArrayInputs('devicesInputList');
        if (devices.length === 0) {
          errEl.textContent = 'أدخل معرّف تثبيت واحدًا على الأقل.';
          errEl.classList.add('visible');
          return;
        }
        const limitRaw = el('licSessionLimit').value.trim();
        const daysRaw = el('licDurationDays').value.trim();
        const payload = {
          devices,
          label: el('licLabel').value.trim(),
          ...(el('licCustomId').value.trim() ? { id: el('licCustomId').value.trim() } : {}),
          ...(limitRaw ? { sessionLimit: Number(limitRaw) } : {}),
          ...(daysRaw ? { durationDays: Number(daysRaw) } : {}),
          ...(el('licLinkHost').value.trim() ? { linkHost: el('licLinkHost').value.trim() } : {}),
          ...(el('licSessionSeedInput').value.trim()
            ? { privateSeed: el('licSessionSeedInput').value.trim() }
            : {}),
          ...(state.replacedFromId ? { replacedFromId: state.replacedFromId } : {}),
        };

        const btn = el('generateLicenseBtn');
        btn.disabled = true;
        try {
          const res = await apiFetch('/v1/licenses/generate', {
            method: 'POST',
            body: JSON.stringify(payload),
          });
          state.replacedFromId = null;
          state.lastGeneratedCode = res.code;
          state.lastGeneratedLink = res.activationLink || '';
          el('licPublicKeyDisplay').value = res.publicKeyUsed;
          el('licenseOutputEmpty').style.display = 'none';
          el('licenseOutputBox').style.display = 'flex';
          el('genCodeOutput').textContent = res.code;

          if (res.activationLink) {
            el('genLinkWrap').style.display = 'block';
            el('genLinkOutput').textContent = res.activationLink;
          } else {
            el('genLinkWrap').style.display = 'none';
          }

          const lines = [
            'السلام عليكم، تم تجهيز كود التفعيل الخاص بكم في تطبيق وفاق:',
            '',
            res.activationLink ? 'رابط التفعيل المباشر:\\n' + res.activationLink : 'كود التفعيل:\\n' + res.code,
            '',
            res.record.sessionLimit ? 'عدد الجلسات لكل جهاز: ' + res.record.sessionLimit : 'الجلسات: غير محدودة',
            res.record.expiresAt ? 'صالح حتى: ' + res.record.expiresAt.slice(0, 10) : '',
            'رقم المرجع: ' + res.record.id,
          ].filter((x) => x !== '');
          el('genDeliveryMsg').value = lines.join('\\n');

          showToast('تم إصدار كود التفعيل وتوقيعه بنجاح');
          if (window.innerWidth <= 900) {
            el('licenseOutputBox').scrollIntoView({ behavior: 'smooth', block: 'nearest' });
          }
          await loadLicensesList();
        } catch (err) {
          if (err.status === 401) handleUnauthorized();
          else {
            errEl.textContent = err.message;
            errEl.classList.add('visible');
          }
        } finally {
          btn.disabled = false;
        }
      });

      el('copyGenCodeBtn').addEventListener('click', () =>
        copyText(state.lastGeneratedCode, 'تم نسخ كود التفعيل'),
      );
      el('copyGenLinkBtn').addEventListener('click', () =>
        copyText(state.lastGeneratedLink, 'تم نسخ رابط التفعيل'),
      );
      el('copyDeliveryMsgBtn').addEventListener('click', () =>
        copyText(el('genDeliveryMsg').value, 'تم نسخ رسالة التسليم'),
      );
      el('licSearchInput').addEventListener('input', () => {
        clearTimeout(licSearchTimer);
        licSearchTimer = setTimeout(() => void loadLicensesList(), 220);
      });
      el('licStatusFilter').addEventListener('change', () => void loadLicensesList());

      function handleUnauthorized() {
        showToast('انتهت جلسة الإدارة، يرجى تسجيل الدخول مجددًا');
        void apiFetch('/v1/auth/session')
          .then((info) => setLoggedOutView(info))
          .catch(() => setLoggedOutView(null));
      }

      document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
          setSidebarOpen(false);
          closeEditorModal();
          closeBulkModal();
          closeActivityModal();
          closeDeleteModal();
        }
      });

      async function loadInitialWorkspace() {
        await Promise.all([
          reloadQuestionsAndMeta(),
          loadAppConfig().catch(() => undefined),
        ]);
      }

      async function boot() {
        try {
          const session = await apiFetch('/v1/auth/session');
          if (session.authenticated) {
            setLoggedInView(session);
            await loadInitialWorkspace();
          } else {
            setLoggedOutView(session);
          }
        } catch (err) {
          setLoggedOutView(null);
          el('loginError').textContent = 'تعذر الاتصال بالخادم: ' + err.message;
          el('loginError').classList.add('visible');
        }
      }

      void boot();
    })();
  </script>
</body>
</html>
`;
}
