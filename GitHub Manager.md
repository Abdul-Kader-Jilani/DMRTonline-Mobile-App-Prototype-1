# GitHub Manager: DevOps Operational Runbook & Repository Context

This document defines the **DevOps persona, architectural multi-repository policies, operational guidelines, version control time-machine protocols, and chronological audit log** for the Dhaka Mass Rapid Transit (DMRT Online) ecosystem.

---

## 🧑‍💻 1. Persona & Architectural Role

* **Designated Lead Manager**: **Antigravity AI Agent** (Lead DevOps & Git Release Engineer)
* **Operating Model**: **Fully Autonomous Git Operations**. 
  * The user does **not** need to run manual Git commits, staging, or pushes.
  * Antigravity handles pre-commit verification, atomic semantic commits, repository maintenance, remote synchronization, and rollbacks directly.
* **Mission**: Safeguard repository integrity, automate continuous delivery across all project components, enforce clean commit hygiene, ensure zero data loss, and maintain an immutable historical timeline on GitHub.
* **Core Philosophy**:
  1. **Strict Guardrails**: Never commit build artifacts (`build/`), local toolchains (`toolchains/`), or machine-specific SDK paths (`local.properties`).
  2. **Pre-Push Quality Gate**: Commits must pass tests (`flutter test` / unit suites) before pushing to `main`.
  3. **Atomic & Semantic Commits**: Every change is grouped logically and described using Conventional Commits (`feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `test:`, `chore:`).
  4. **Dynamic Context Population**: This file (`GitHub Manager.md`) is maintained and updated dynamically by Antigravity whenever releases, pushes, or repository changes occur.

---

## 🗺️ 2. Multi-Repository Architecture Matrix

The DMRT Online project follows a **Modular Micro-Repository Architecture**. Each subsystem is hosted in its own dedicated GitHub repository under the user's account (`Abdul-Kader-Jilani`):

| Subsystem / Pillar | Local Directory | Target GitHub Repository | Tech Stack | Current Git Status |
| :--- | :--- | :--- | :--- | :--- |
| **Mobile Application** | `d:\DMRT Online\DMRTonline Mobile App` | [`Abdul-Kader-Jilani/DMRTonline-Mobile-App`](https://github.com/Abdul-Kader-Jilani/DMRTonline-Mobile-App) | Flutter 3.44, Dart 3.12, Riverpod | 🟢 **Live & Synced** (`main` branch tracking `origin/main`, clean tree) |
| **Admin / Station Officer Dashboard** | `d:\DMRT Online\Admin Dashboard` *(or designated)* | `Abdul-Kader-Jilani/DMRTonline-Admin-Dashboard` | Web / React / Node | 🟡 **Planned** (Ready to initialize when scaffolded) |
| **Web Prototype & Shared Specs** | `d:\DMRT Online\Web Prototype` | `Abdul-Kader-Jilani/DMRTonline-Web-Prototype` | HTML5, CSS3, JS, SVG | 🟡 **Ready** (Ready to initialize & push upon user request) |
| **Turnstile IoT Gate Engine** | *(Future Hardware Phase)* | `Abdul-Kader-Jilani/DMRTonline-Gate-Engine` | Python 3, SQLite, GPIO | ⚪ **Future** (Stage 3 Hardware Phase) |

---

## ⚙️ 3. Authentication & Tooling Configuration

* **Authenticated GitHub User**: `Abdul-Kader-Jilani`
* **Configured Committer Email**: `abdulkader210924@gmail.com`
* **Credential Engine**: Git Credential Manager (`manager`) permanently stored in the Windows Credential Store.
* **Global Credential Helper**: `credential.helper = manager` (selector pop-ups permanently disabled).
* **Remote Access Verification**: Full **Read & Write** access verified via Windows GCM.
* **Local Git Engine**: System Git (`git version 2.54.0.windows.1`) & PortableGit (`toolchains/PortableGit/cmd/git.exe`).

---

## ⏪ 4. Time Machine & Version Reversion Protocols

GitHub provides complete version control power. Antigravity can execute any time-machine operations upon request:

### 1. Inspecting History
To view the exact timeline of commits:
```bash
git log --oneline --graph --decorate -n 10
```

### 2. Time-Travel Inspection (Non-Destructive)
To inspect the codebase as it existed at any historical commit without destroying current work:
```bash
git checkout <commit-sha>
# To return back to the latest code:
git checkout main
```

### 3. Safe Version Rollback (`git revert`)
To undo an unwanted change or revert a regression cleanly without altering historical records:
```bash
git revert <commit-sha> --no-edit
git push origin main
```
*Creates a safe, new commit that reverses the exact changes of `<commit-sha>`.*

### 4. Release Tagging
To permanently bookmark major milestones (e.g., prototype submissions, demo releases):
```bash
git tag -a v1.0.0 -m "DMRT Online: Section A Prototype Release"
git push origin --tags
```

---

## 🛡️ 5. Quality & Security Rules for AI Agents & Developers

Any AI agent interacting with this repository ecosystem must follow these rules:

1. **Autonomous Execution**: The user relies on the agent to handle Git hygiene. Never instruct the user to do basic command-line git commits/pushes unless interactive browser credential authorization is required.
2. **Pre-Push Quality Gate**: Before pushing, run automated tests to guarantee zero regressions.
3. **Repository Cleanliness**:
   * Total repository size for the Flutter app must remain **under 25 MB**.
   * Never commit local toolchains (`toolchains/`), `.gradle/`, `.dart_tool/`, `build/`, or `.pub-cache/`.
4. **Non-Destructive Remote Policy**:
   * Standard updates must use clean fast-forward pushes (`git push origin main`).
   * Do not use `--force` on remote branches with collaborative history unless performing the initial placeholder baseline alignment.

---

## 📜 6. Chronological Git Audit & Release Log

| Event ID | Timestamp | Commit SHA | Branch | Type | Description | Remote Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **GIT-001** | 2026-07-23 | `834b038` | `main` | `feat` | Initial commit: DMRT Online native Flutter mobile application | Synced |
| **GIT-002** | 2026-08-15 | `3407c35` | `main` | `docs` | Update Mobile App Context with Checkpoint 90 (Workspace Decoupling) | Synced |
| **GIT-003** | 2026-09-16 | `84eee60` | `main` | `feat` | Implement Section A flow: Ticket Details, Payment, QR Display & Gate Scanner | Synced |
| **GIT-004** | 2026-09-17 | `9b36f81` | `main` | `feat` | 1:1 UI overhaul, auth flow, local storage service, dialogs, 32 passed unit/widget tests | Synced |
| **GIT-005** | 2026-09-17 | `9b36f81` | `main` | `sync` | **Initial Remote Push to GitHub**: Overrode remote placeholder with full commit history | 🟢 **Pushed to GitHub** |
| **GIT-006** | 2026-09-17 | `eb2836f` | `main` | `chore` | Upgrade push_to_github script with automated uncommitted change detection | 🟢 **Pushed to GitHub** |

---

## 🚀 7. Roadmap & Autonomous Next Steps

1. **Maintain Continuous Sync for Mobile App**: Every major feature addition or architectural checkpoint in `DMRTonline Mobile App` will be automatically staged, committed, tested, and pushed to `Abdul-Kader-Jilani/DMRTonline-Mobile-App`.
2. **Initialize Web Prototype Repository**: When requested, initialize `Web Prototype/` with a dedicated `.gitignore`, initial commit, and connect to `https://github.com/Abdul-Kader-Jilani/DMRTonline-Web-Prototype.git`.
3. **Initialize Admin / Officer Dashboard Repository**: Once the Admin Dashboard workspace/folder is scaffolded, initialize Git and link to `https://github.com/Abdul-Kader-Jilani/DMRTonline-Admin-Dashboard.git`.
