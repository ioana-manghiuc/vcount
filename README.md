# VCount

## Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Python 3.8+](https://www.python.org/downloads/)

## Installation

1. Download and extract the ZIP file

## Backend Setup

1. Navigate to the **backend** directory
2. Create virtual environment: `py -m venv .venv`
3. Activate virtual environment:
   - Windows: `.venv\Scripts\activate`
   - macOS/Linux: `source .venv/bin/activate`
4. Install dependencies: `pip install -r requirements.txt`
5. Start server: `uvicorn app.main:app --reload`
   - Server runs on http://127.0.0.1:8000

## Frontend Setup

1. Navigate to the **frontend** directory
2. Install dependencies: `flutter pub get`
3. Run application:
   - Windows: `flutter run -d windows`
   - macOS: `flutter run -d macos`
   - Linux: `flutter run -d linux`

**Note:** Both backend and frontend must be running simultaneously for the application to work.
