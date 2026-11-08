# Contributing to Mendaki

Thank you for your interest in contributing to **Mendaki**! Whether you are helping fix bugs, adding new features, improving documentation, or submitting verified Indonesian mountain GPX trails, your contributions are warmly welcomed.

---

## 📋 Table of Contents
1. [Code of Conduct](#-code-of-conduct)
2. [How Can I Contribute?](#-how-can-i-contribute)
   - [Reporting Bugs](#reporting-bugs)
   - [Suggesting Features](#suggesting-features)
   - [Contributing GPX Trails & Mountain Data](#contributing-gpx-trails--mountain-data)
   - [Code Contributions](#code-contributions)
3. [Development Setup](#-development-setup)
4. [Coding Guidelines & Standards](#-coding-guidelines--standards)
5. [Pull Request (PR) Workflow](#-pull-request-pr-workflow)

---

## 🤝 Code of Conduct
We are committed to fostering an inclusive, welcoming, and harassment-free environment. Please treat all contributors and community members with mutual respect, kindness, and professionalism.

---

## 💡 How Can I Contribute?

### Reporting Bugs
If you find a bug or unexpected behavior:
1. Check the existing [Issues](https://github.com/<your-username>/mendaki/issues) to make sure it hasn't already been reported.
2. Open a new issue with a clear title and description:
   - Steps to reproduce the issue.
   - Expected behavior vs. actual behavior.
   - Device model, OS version (Android/iOS), and Flutter version.
   - Screenshots or video recordings if applicable.

### Suggesting Features
Have an idea to make Mendaki better?
- Open an Issue titled `[Feature Request]: <short-title>`.
- Explain why the feature would be useful for hikers and how it could work.

### Contributing GPX Trails & Mountain Data
Accurate trail data saves lives on the mountain! If you have recorded a clean, verified GPX track from a mountain in Indonesia:
1. Ensure the GPX includes important trail points:
   - Basecamp (`<cmt>basecamp</cmt>`)
   - Pos / Checkpoints (`<cmt>pos</cmt>`)
   - Camping grounds (`<cmt>camp</cmt>`)
   - Mountain summit (`<cmt>summit</cmt>`)
   - Water sources (`<cmt>water</cmt>`)
2. Verify that track coordinates avoid off-route GPS drifts or personal privacy areas.
3. Submit a PR adding or updating the mountain gpx.

### Code Contributions
We welcome bug fixes, architecture improvements, widget optimizations, and feature implementations.

---

## 🛠️ Development Setup

1. **Fork & Clone the Repository**:
   ```bash
   git clone https://github.com/<your-username>/mendaki.git
   cd mendaki
   ```

2. **Install Flutter Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**:
   Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
   Fill in your Supabase project credentials.

4. **Initialize Supabase Database**:
   Run [`supabase/schema.sql`](supabase/schema.sql) in your Supabase SQL Editor. It automatically sets up the required tables (`mountain`, `route`), RLS security policies, and seed dummy data.

5. **Run the App Locally**:
   ```bash
   flutter run
   ```

---

## 📐 Coding Guidelines & Standards

- **Dart Style**: Follow the official [Effective Dart](https://dart.dev/effective-dart) style guide.
- **Null Safety**: All code must strictly adhere to Sound Null Safety.
- **Clean Architecture & Separation of Concerns**: Keep widgets focused on presentation. Extract geodesic calculations, business logic, and database operations into dedicated services or utilities.
- **Static Analysis**: Zero warnings or linter issues allowed.
  ```bash
  flutter analyze
  ```
- **Automated Tests**: Every new feature or bug fix should be accompanied by relevant unit or widget tests. All tests must pass:
  ```bash
  flutter test
  ```

---

## 🚀 Pull Request (PR) Workflow

1. Create a descriptive branch from `main`:
   ```bash
   git checkout -b feat/offline-compass-calibration
   # or
   git checkout -b fix/gpx-altitude-calculation
   ```

2. Use clear commit messages following [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat: add compass auto-calibration notice`
   - `fix: resolve waypoint marker clipping on small screens`
   - `docs: update setup steps in README`
   - `test: add unit tests for NavigationGeoUtils`

3. Verify tests and linter locally:
   ```bash
   flutter analyze
   flutter test
   ```

4. Push your branch and open a Pull Request against the `main` branch. Provide a brief explanation of what changes were made and attach screenshots/recordings if the UI was modified.

---

Thank you for helping make mountain hiking in Indonesia safer and more accessible! ⛰️🇮🇩

