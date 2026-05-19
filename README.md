# 🛡️ SafePath — Women's Safety Platform

> A full-stack safety ecosystem combining a **Flutter mobile app** for users and a **Django web dashboard** for police officers and administrators — powered by AI predictions, real-time SOS alerts, and blockchain-backed credibility scoring.

---

## 📌 Table of Contents

- [About the Project](#-about-the-project)
- [Key Features](#-key-features)
- [System Architecture](#-system-architecture)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Web (Django) Setup](#web-django-setup)
  - [Mobile (Flutter) Setup](#mobile-flutter-setup)
- [Roles & Portals](#-roles--portals)
- [Blockchain Integration](#-blockchain-integration)
- [ML Safety Prediction](#-ml-safety-prediction)
- [Project Structure](#-project-structure)
- [Contributing](#-contributing)
- [Presentation](#-presentation)
- [Team](#-team)
- [License](#-license)

---

## 🌟 About the Project

**SafePath** (mobile app name: *SheCare*) is a comprehensive women's safety platform built to bridge the gap between citizens and law enforcement. Users can report dangerous spots, trigger SOS alerts, share live journeys with trusted contacts, and get AI-powered safety predictions — all in real time. Police officers and admins manage everything from a dedicated web dashboard.

---

## ✨ Key Features

### 📱 Mobile App (Flutter — SheCare)
- 🆘 **Multi-Factor SOS Alert** — Triggers via shake gesture, voice command, or manual button; notifies nearby police and emergency contacts instantly
- 📍 **Live Journey Sharing** — Share your route with trusted contacts and request journey companions
- 🗺️ **Dangerous & Safe Spot Map** — View and report hazardous locations near you
- 🤖 **AI Safety Prediction** — Get a real-time safety score for your current location based on time, lighting, and area zone
- 💬 **In-App Chat** — Communicate with journey companions securely
- 📊 **Credit Score System** — Earn blockchain-verified credibility points for accurate spot reporting
- 🚨 **SOS History** — View past SOS alerts and their resolution status
- 📞 **Emergency Contacts** — Manage and instantly alert personal emergency contacts
- 🤖 **AI Chatbot** — Get safety tips and guidance from an in-app assistant
- 📝 **Complaint System** — Submit and track complaints to police stations

### 🖥️ Web Dashboard (Django)
**Police Officer Portal:**
- View and manage dangerous spots reported by users
- Mark spots as verified, false, or resolved
- Respond to live SOS and emergency requests
- View nearby SOS alerts on a map
- Add/edit safe points in their jurisdiction
- Update real-time location for proximity-based SOS matching

**Admin Portal:**
- Manage police stations (add, edit, delete)
- Verify and approve police officer registrations
- Monitor all users and their activity
- View false reporting records
- Full oversight of the platform

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────┐
│                   SheCare Mobile App                │
│              (Flutter — Android/iOS)                │
│  Users: SOS • Journey • Spot Reports • Chat • AI   │
└────────────────────┬────────────────────────────────┘
                     │ REST API (HTTP)
┌────────────────────▼────────────────────────────────┐
│              Django Backend (Python)                │
│    Auth • Models • REST Views • ML Prediction       │
│              MySQL Database                         │
└──────┬──────────────────────────┬───────────────────┘
       │                          │
┌──────▼──────┐          ┌────────▼────────┐
│  Blockchain  │          │   Web Dashboard  │
│  (Ganache +  │          │  Admin & Police  │
│   Web3.py +  │          │  Officer Portal  │
│  Solidity)   │          │   (Templates)    │
└─────────────┘          └─────────────────┘
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Dart) |
| Web Backend | Django 3.0 (Python) |
| Database | MySQL |
| Blockchain | Solidity + Web3.py + Ganache |
| ML/AI | scikit-learn, pandas, numpy |
| Authentication | Django Auth + Groups |
| SOS Detection | Accelerometer + Voice Recognition |

---

## 🚀 Getting Started

### Prerequisites

- Python 3.6+
- Flutter SDK
- MySQL Server
- [Ganache](https://trufflesuite.com/ganache/) (for local blockchain)
- Node.js (for Ganache CLI, optional)

---

### Web (Django) Setup

**1. Clone the repository**
```bash
git clone https://github.com/YOUR_USERNAME/safepath.git
cd safepath/safe_path_web
```

**2. Create and activate a virtual environment**
```bash
python -m venv venv
source venv/bin/activate        # On Windows: venv\Scripts\activate
```

**3. Install dependencies**
```bash
pip install -r requirement.txt
```

**4. Configure the database**

Open `safe_path_web/settings.py` and update the `DATABASES` section with your MySQL credentials:
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'safepath_db',
        'USER': 'your_mysql_user',
        'PASSWORD': 'your_mysql_password',
        'HOST': 'localhost',
        'PORT': '3306',
    }
}
```

**5. Configure Blockchain paths**

In `myapp/blockchain.py`, update the paths to your Solidity contract and deployment JSON:
```python
sol_path = "path/to/your/myapp/contract/CreditScore.Sol"
deploy_info_path = "path/to/your/myapp/contract/deployed.json"
```

**6. Start Ganache** (in a separate terminal)
```bash
ganache
```

**7. Run migrations and start the server**
```bash
python manage.py makemigrations
python manage.py migrate
python manage.py runserver
```

The web dashboard will be available at `http://127.0.0.1:8000`

> **Default Admin credentials:** `admin@gmail.com` / `Admin@123`

---

### Mobile (Flutter) Setup

**1. Navigate to the mobile project**
```bash
cd safepath/mobile
```

**2. Install Flutter dependencies**
```bash
flutter pub get
```

**3. Configure the backend IP**

Open `lib/ipPage.dart` and set your Django server's IP address (the app has a dedicated screen for this at startup).

**4. Run the app**
```bash
flutter run
```

---

## 👥 Roles & Portals

| Role | Access | Portal |
|---|---|---|
| **Admin** | Full platform management | Web (`/admin_home`) |
| **Police Officer** | Jurisdiction management, SOS response | Web (`/police_home`) |
| **User** | Safety features, SOS, journey sharing | Mobile App |

Police officers must register and await **admin approval** before gaining access.

---

## ⛓️ Blockchain Integration

SafePath uses a **Solidity smart contract** deployed on a local Ganache blockchain to maintain a **tamper-proof credit score** for users.

- Every time a user reports a dangerous spot that gets **verified** by police, their credit score is updated on-chain.
- **False reports** reduce the credit score.
- Scores are stored immutably on the blockchain, making the reputation system transparent and fraud-resistant.

The smart contract (`CreditScore.Sol`) exposes:
- `updateCreditScore(username, score, totalSpots)` — called when a spot report is resolved
- `getUserByUsername(username)` — retrieves a user's on-chain reputation data

---

## 🤖 ML Safety Prediction

The AI safety prediction module analyzes multiple contextual factors to generate a **real-time safety score** for a location:

- **Time & Lighting** — Day/night, dawn/dusk classification
- **Area Zone** — Urban, suburban, rural classification from coordinates
- **Nearby Places** — Points of interest around the location
- **Known Dangerous Locations** — Cross-referenced against the reported spots database

The model (`safety_model_new.pkl`) is trained on an augmented safety dataset (`augmented_safety_dataset.csv`) using scikit-learn.

---

## 📁 Project Structure

```
safepath/
│
├── safe_path_web/                  # Django Web Backend
│   ├── myapp/
│   │   ├── models.py               # DB models (users, spots, SOS, etc.)
│   │   ├── views.py                # All API & page views
│   │   ├── blockchain.py           # Web3 / Ganache integration
│   │   ├── prediction_new.py       # ML safety prediction logic
│   │   ├── ml_model.py             # Model training utilities
│   │   └── contract/
│   │       └── CreditScore.Sol     # Solidity smart contract
│   ├── templates/
│   │   ├── admin/                  # Admin portal templates
│   │   └── police_station/         # Police officer portal templates
│   └── requirement.txt
│
└── mobile/lib/                     # Flutter Mobile App (SheCare)
    ├── main.dart                   # App entry point
    ├── home_screen.dart            # Main user dashboard
    ├── services/
    │   ├── sos_service.dart        # SOS trigger logic
    │   ├── sos_motion.dart         # Shake detection
    │   ├── sos_voice.dart          # Voice command detection
    │   └── sos_multifactor.dart    # Combined SOS logic
    ├── safety_prediction_page.dart # AI safety score UI
    ├── chat.dart                   # In-app chat
    ├── chatBot.dart                # AI chatbot
    ├── emergency_contacts_page.dart
    ├── viewNearbyDangerousSpots.dart
    ├── viewSafePoints.dart
    └── add_journey_details.dart
```

---

## 🤝 Contributing

Contributions are welcome! Here's how to get started:

1. Fork the repository
2. Create a new branch: `git checkout -b feature/your-feature-name`
3. Make your changes and commit: `git commit -m "Add: your feature description"`
4. Push to your fork: `git push origin feature/your-feature-name`
5. Open a Pull Request

Please make sure your code follows the existing style and includes appropriate comments.

---

## ⚠️ Important Notes

- The blockchain path in `blockchain.py` contains hardcoded local paths — update these before deploying or sharing.
- Never commit your `settings.py` with real database credentials. Use environment variables or a `.env` file.
- Add a `.gitignore` to exclude `*.pyc`, `__pycache__/`, `*.pkl`, `*.env`, `venv/`, and `node_modules/`.

---

## 📊 Presentation

For a detailed overview of the project including architecture diagrams, UI screenshots, and system flow, refer to our project presentation:

📄 [View Presentation (PDF)](./Presentation_PPT.pdf)

---

## 👨‍💻 Team

This project was built as a group project by:

| Name | Role |
|---|---|
| **Safa Abdul Muneer** | Full Stack Developer |
| **Pranav R** | Full Stack Developer |
| **Sayanth T N** | Full Stack Developer |
| **Vishnuraj C** | Full Stack Developer |

---

## 📄 License

This project is intended for academic and research purposes.

---

<div align="center">
  Built with ❤️ to make every path a safe path.
</div>
