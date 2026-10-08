---
name: delivery-app-dev
description: >-
  Standard operating procedures, cheat sheet, and rapid command reference for
  AMN Delivery mobile app and socket server. Use whenever building, testing,
  deploying to Google Play or Render, managing git repositories, or interacting
  with backend APIs across delivery_app and delivery-socket-server.
---

# AMN Delivery Development & Operations Runbook

Rapid command cheatsheet and architectural reference for the AMN Delivery ecosystem.

---

## 1. Project Locations & Repositories

| Component | Path | Remote Repo | Branch | Production Deployment |
| :--- | :--- | :--- | :--- | :--- |
| **Mobile App (Flutter)** | `c:\flutter_dev\projects\delivery_app` | `https://github.com/DaV212001/delivery_app.git` | `master` | Google Play Store (`com.amn.delivery_app`) |
| **Socket Server (Node/TS)** | `c:\flutter_dev\projects\delivery-socket-server` | `https://github.com/DaV212001/delivery-socket-server.git` | `main` | Render (`https://amn-delivery-socket-server.onrender.com`) |
| **Backend REST API** | - | - | - | `https://api.amnplc.com/api` |

---

## 2. Fast Command Reference

### Flutter Mobile App (`c:\flutter_dev\projects\delivery_app`)

* **Analyze code**:
  ```powershell
  flutter analyze
  ```
* **Run tests**:
  ```powershell
  flutter test
  ```
* **Run specific test file**:
  ```powershell
  flutter test test/my_property_test.dart
  ```
* **Build release Android App Bundle (AAB)**:
  ```powershell
  flutter build appbundle --release
  ```
* **Automated Google Play Release (Internal track)**:
  ```powershell
  dart run tool/release.dart
  ```
* **Automated Google Play Release (Production track with patch bump)**:
  ```powershell
  dart run tool/release.dart --bump=patch --track=production --notes="Release notes here"
  ```
* **Dry run release pipeline (verifies versioning, key file, and bundle without uploading)**:
  ```powershell
  dart run tool/release.dart --bump=patch --track=production --dry-run
  ```
* **Git commit & push**:
  ```powershell
  git add .
  git commit -m "feat/fix: description"
  git push origin master
  ```

### Socket Server (`c:\flutter_dev\projects\delivery-socket-server`)

* **Run tests**:
  ```powershell
  npm test
  ```
* **Build TypeScript**:
  ```powershell
  npm run build
  ```
* **Install dependencies (including dev)**:
  ```powershell
  npm install --include=dev
  ```
* **Check live health probe on Render**:
  ```powershell
  Invoke-RestMethod -Uri "https://amn-delivery-socket-server.onrender.com/health" -Method Get | ConvertTo-Json
  ```
* **Deploy to Render**:
  Commit and push to `origin main`. Render has `autoDeploy: true` configured on `main`:
  ```powershell
  git add .
  git commit -m "fix/feat: description"
  git push origin main
  ```

---

## 3. Windows PowerShell Rules
* **Never use `&&` statement separators** in standard Windows PowerShell (causes parse errors). Use `;` or run sequential commands.
* Always check background tasks reactively without polling loops on `status`.

---

## 4. Key Endpoints & Architecture
* **Order details format**: `GET https://api.amnplc.com/api/my_order_detail/{orderId}`
  Returns:
  ```json
  {
    "message": "...",
    "data": [ { "item_name": "...", "property": "..." } ],
    "order_status": { "id": 15, "customer_id": "2", "status": "0", "latitude": "9.032", "longitude": "38.7469" }
  }
  ```
* **Active orders**: `GET https://api.amnplc.com/api/my_active_order/{customerId}`
* **Gebeta Maps**: MapLibre vector maps powered by `package:gebeta_gl/gebeta_gl.dart`. Style: `gebetaStandardStyle`. Center default: Addis Ababa `(9.0209, 38.7469)`.
