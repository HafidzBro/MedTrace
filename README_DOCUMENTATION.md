# 🏥 MedTrace - TB Adherence Mobile App

## 📋 Overview

MedTrace is a comprehensive Flutter mobile application designed to support TB (Tuberculosis) treatment adherence through real-time medication tracking, AI-powered health education, and doctor-patient coordination.

**Target Users**: TB patients and their healthcare providers  
**Current Status**: Phase 5-6 Complete (Patient & Doctor Feature Pages)  
**Platform**: Android, iOS  
**Framework**: Flutter 3.19.0+  
**Backend**: Supabase PostgreSQL with Real-time Subscriptions  
**State Management**: Riverpod 2.4.1+  

---

## 📚 Documentation Guide

This project includes comprehensive documentation organized by use case:

### 🚀 **For First-Time Setup**
→ Start with **[SETUP.md](SETUP.md)**
- Environment prerequisites
- Installation steps
- Supabase configuration
- Test credentials
- Troubleshooting

**Time Required**: 15-30 minutes

---

### 📱 **For What Features Exist**
→ Check **[FEATURES.md](FEATURES.md)**
- Complete feature matrix
- Implementation status (✅/🔄/❌)
- What's working, what's planned
- How to test each feature
- Backend integration TODOs

**Time Required**: 10 minutes to scan, 30+ to deep dive

---

### 🏗️ **For Understanding Architecture**
→ Read **[ARCHITECTURE.md](ARCHITECTURE.md)**
- Clean Architecture explanation (3 layers)
- Data flow diagrams
- Design patterns (Repository, Factory, StateNotifier)
- Database schema design
- Security & isolation strategies

**Time Required**: 20-30 minutes

---

### 👨‍💻 **For Development Tasks**
→ Use **[DEVELOPMENT.md](DEVELOPMENT.md)**
- Coding standards & naming conventions
- StateNotifier patterns
- Common task walkthroughs:
  - Add new feature page
  - Create new provider
  - Add database table
  - Write tests
- Debugging tips
- Code review checklist

**Time Required**: Reference as needed

---

### ⚡ **For Quick Commands & Snippets**
→ Reference **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)**
- Copy-paste commands for common tasks
- Code snippets for:
  - Provider watching
  - Navigation
  - API calls
  - Error handling
  - Date/time operations
- Testing commands
- Git workflow

**Time Required**: 2-5 minutes per task

---

### 📊 **For Project Status & Progress**
→ Review **[PROJECT_STATUS.md](PROJECT_STATUS.md)**
- Completed components (✅)
- In-progress work (🔄)
- Not-yet-started features (❌)
- Statistics: 12,000+ lines across 31 files
- Known issues and TODOs
- Roadmap for remaining phases

**Time Required**: 5-10 minutes

---

## 🎯 Quick Navigation by Role

### 👨‍💻 Backend Developer
1. Read: ARCHITECTURE.md (focus on Data & Domain layers)
2. Reference: DEVELOPMENT.md (Database section)
3. Check: FEATURES.md (API Integration sections marked TODO)
4. Use: QUICK_REFERENCE.md (Supabase queries)

### 📱 Mobile Developer
1. Read: SETUP.md (get app running)
2. Study: ARCHITECTURE.md (Presentation layer)
3. Reference: DEVELOPMENT.md (Widget patterns, StateNotifier)
4. Check: FEATURES.md (find feature to build)
5. Use: QUICK_REFERENCE.md (code snippets)

### 🔐 DevOps / Deployment
1. Check: PROJECT_STATUS.md (current build status)
2. Review: SETUP.md (environment config)
3. Reference: Supabase documentation for deployment

### 📋 Project Manager / Stakeholder
1. Review: PROJECT_STATUS.md (overall progress)
2. Check: FEATURES.md (what's complete vs planned)
3. Use: SETUP.md (understand setup requirements)

---

## 📦 Project Structure

```
medtrace/
├── lib/
│   ├── core/              # Configuration, constants, errors, extensions
│   ├── data/              # Repositories, models, datasources
│   ├── domain/            # Business entities and interfaces
│   ├── presentation/      # UI pages, providers, routing, widgets
│   ├── services/          # Utility services
│   └── main.dart          # App entry point
├── test/                  # Unit and widget tests
├── supabase/              # Database migrations and seed data
├── android/               # Android-specific configuration
├── ios/                   # iOS-specific configuration
├── web/                   # Web-specific configuration
├── documentation/         # Guides and references
└── pubspec.yaml           # Dependencies and project metadata
```

---

## 🚀 Getting Started (5 Minutes)

```bash
# 1. Clone repository
git clone https://github.com/your-org/medtrace.git
cd medtrace

# 2. Install dependencies
flutter clean
flutter pub get

# 3. Configure Supabase
# Copy environment variables to .env or AppConfig

# 4. Run app
flutter run

# 5. Login with test credentials
# Email: patient@test.com
# Password: Test123!@#
```

For detailed setup, see **[SETUP.md](SETUP.md)**.

---

## ✨ Current Features (Phase 5-6 Complete)

### ✅ Patient Features
- ✅ Authentication & Login
- ✅ Patient Dashboard
- ✅ Treatment Details
- ✅ Medication Schedule (daily tracking)
- ✅ TB Geographic Map (real-time location)
- ✅ AI Health Chatbot (UI complete, API pending)
- ✅ Appointment Reminders (UI complete, CRUD pending)

### ✅ Doctor Features
- ✅ Doctor Dashboard
- ✅ Patient Management (UI complete, provider pending)
- ✅ Alert System (UI complete, provider pending)

### 🔄 In Progress
- 🔄 Complete doctor data providers
- 🔄 Integrate OpenAI for chatbot
- 🔄 Full reminder CRUD operations

### ⏳ Planned (Phases 7-12)
- Notification system
- Real-time subscriptions
- Analytics dashboard
- Offline support
- Store submission

---

## 🏗️ Architecture Highlights

### Clean Architecture (3 Layers)
```
┌─────────────────────────────────┐
│  PRESENTATION (UI, Pages, etc)  │
├─────────────────────────────────┤
│  STATE MANAGEMENT (Riverpod)    │
├─────────────────────────────────┤
│  DOMAIN (Entities, Interfaces)  │
├─────────────────────────────────┤
│  DATA (Repositories, Models)    │
├─────────────────────────────────┤
│  EXTERNAL (Supabase Backend)    │
└─────────────────────────────────┘
```

### State Management
- **Riverpod**: Reactive dependency injection
- **StateNotifier**: Encapsulated mutable state
- **Family Providers**: Parameterized providers for patient/doctor-specific data

### Navigation
- **GoRouter**: Type-safe, declarative routing
- **Role-based redirects**: Automatic patient/doctor routing
- **Deep linking**: Ready for Firebase dynamic links

### Database
- **12 PostgreSQL tables** with Row Level Security
- **RLS Policies**: Patient isolation, doctor access control
- **Indexes**: Optimized for common queries

---

## 🧪 Testing & Quality

### Code Quality Tools
```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ -i

# Run tests
flutter test
```

### Current Test Coverage
- Domain entities: 90%+
- Data models: 85%+
- Repositories: 70%+
- Pages: UI tested manually

---

## 📞 Common Questions

### Q: "Why do I see 'Coming Soon' on Analytics page?"
**A**: Features marked "Coming Soon" are planned but not yet implemented. See [FEATURES.md](FEATURES.md) for status and TODOs.

### Q: "How do I add a new patient feature?"
**A**: See [DEVELOPMENT.md](DEVELOPMENT.md) section "Add a New Feature Page" for step-by-step guide.

### Q: "How do I run just the patient flow?"
**A**: Login with patient credentials (patient@test.com). All doctor features hidden by role-based redirect.

### Q: "Can I work offline?"
**A**: Not yet. Real-time sync and offline support planned for Phase 11. See [FEATURES.md](FEATURES.md).

### Q: "How's the app testing done?"
**A**: Manually on emulator/device. Test plan in [FEATURES.md](FEATURES.md) "Testing Checklist".

---

## 🔗 Quick Links

| Document | Purpose | Audience |
|----------|---------|----------|
| **🚀 [SETUP.md](SETUP.md)** | Get started quickly | Everyone |
| **📱 [FEATURES.md](FEATURES.md)** | Feature status & roadmap | Everyone |
| **🏗️ [ARCHITECTURE.md](ARCHITECTURE.md)** | System design deep dive | Developers |
| **👨‍💻 [DEVELOPMENT.md](DEVELOPMENT.md)** | Coding standards & tasks | Developers |
| **⚡ [QUICK_REFERENCE.md](QUICK_REFERENCE.md)** | Commands & snippets | Developers |
| **📊 [PROJECT_STATUS.md](PROJECT_STATUS.md)** | Overall progress | Everyone |
| **📄 [README.md](README.md)** | This file | Everyone |

---

## 👥 Team & Contributions

### Contributing
1. Create feature branch: `git checkout -b feature/my-feature`
2. Follow [DEVELOPMENT.md](DEVELOPMENT.md) standards
3. Run tests and analysis: `flutter test && flutter analyze`
4. Create pull request with description

### Code Review
All PRs checked against [DEVELOPMENT.md](DEVELOPMENT.md) Code Review Checklist.

---

## 📈 Project Timeline

| Phase | Status | Duration | Deliverables |
|-------|--------|----------|--------------|
| 1-4 | ✅ Complete | Apr 2024 | Auth, DB, Domain, Data layers |
| 5-6 | ✅ Complete | May 2024 | Patient & Doctor feature pages |
| 7 | 🔄 In Progress | May 2024 | Complete providers & API integration |
| 8-9 | ⏳ Planned | May-Jun 2024 | Notifications & Real-time |
| 10-11 | ⏳ Planned | Jun 2024 | Advanced features |
| 12 | ⏳ Planned | Jun-Jul 2024 | Release & deployment |

---

## 🛠️ Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| **Frontend** | Flutter | 3.19.0+ |
| **Language** | Dart | 3.3.0+ |
| **State** | Riverpod | 2.4.1+ |
| **Routing** | GoRouter | 13.0.0+ |
| **Database** | Supabase | Latest |
| **Backend Lang** | PostgreSQL | 15+ |
| **Auth** | Supabase Auth | Built-in |
| **API** | REST + Realtime | Supabase SDK |
| **Maps** | Flutter Map | 5.0.0+ |
| **Location** | Geolocator | 9.0.0+ |

---

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| **Android** | ✅ Ready | Tested on API 24+ |
| **iOS** | ✅ Ready | iOS 11+ required |
| **Web** | 🔄 Partial | Core features only |
| **macOS** | ⏳ Future | Not prioritized |
| **Windows** | ⏳ Future | Not prioritized |
| **Linux** | ⏳ Future | Not prioritized |

---

## 📊 Project Statistics

- **Total Files**: 31
- **Production Code**: 12,000+ lines
- **Documentation**: 5 comprehensive guides
- **Database Tables**: 12
- **API Endpoints**: 40+
- **Feature Pages**: 9
- **State Providers**: 15+
- **Test Coverage**: 70%+

---

## 🎓 Learning Path

### For New Developers:
1. **Day 1**: Read SETUP.md, get app running
2. **Day 2**: Read ARCHITECTURE.md, understand structure
3. **Day 3**: Study DEVELOPMENT.md patterns
4. **Day 4**: Pick first task from FEATURES.md TODOs
5. **Day 5+**: Refer to QUICK_REFERENCE.md as needed

### Estimated Time to Productivity
- **Familiar with Flutter/Riverpod**: 1-2 days
- **New to Flutter**: 3-5 days
- **New to mobile dev**: 1-2 weeks

---

## 📞 Support & Resources

### Documentation
- Inside this repo: All markdown files
- Flutter: https://flutter.dev/docs
- Riverpod: https://riverpod.dev
- Supabase: https://supabase.com/docs
- Material Design: https://m3.material.io

### Common Issues
See Troubleshooting sections in individual docs:
- SETUP.md → Installation issues
- DEVELOPMENT.md → Dev environment issues
- ARCHITECTURE.md → Design questions

### Reporting Bugs
1. Describe issue clearly
2. Include steps to reproduce
3. Check PROJECT_STATUS.md for known issues
4. Reference relevant FEATURES.md section

---

## 🚀 Next Steps

### Immediate (This Week)
- [ ] Run app following SETUP.md
- [ ] Explore patient and doctor flows
- [ ] Review FEATURES.md for current status

### Short Term (Next 2 Weeks)
- [ ] Complete doctor data providers (task #7)
- [ ] Integrate OpenAI chatbot API (task #8)
- [ ] Finalize reminder CRUD operations

### Medium Term (Next 4 Weeks)
- [ ] Implement notification system
- [ ] Add real-time subscriptions
- [ ] Build analytics dashboard

---

## 📄 License

This project is part of a TB adherence initiative. See LICENSE file for details.

---

## 👏 Acknowledgments

- WHO TB Treatment Guidelines (Data foundation)
- Flutter & Dart Communities
- Supabase for backend infrastructure
- Material Design 3 for UI framework

---

## 🎯 Help Needed?

1. **Getting started?** → [SETUP.md](SETUP.md)
2. **Want to build a feature?** → [DEVELOPMENT.md](DEVELOPMENT.md)
3. **Need code examples?** → [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
4. **Checking progress?** → [PROJECT_STATUS.md](PROJECT_STATUS.md)
5. **Understanding architecture?** → [ARCHITECTURE.md](ARCHITECTURE.md)

---

**Last Updated**: May 2024  
**Version**: 0.2.0 (Beta)  
**Maintainers**: [Your Team]

---

**Commit MedTrace to improving TB treatment adherence worldwide 🌍💪**
