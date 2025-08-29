# Project Planning & Architecture  
## Reverse Dictionary Game

---

## Vision
Deliver a **fun, clever, monetizable puzzle game** where players guess words from definitions, emojis, or riddles. Keep it lightweight, accessible, and expandable with fresh content.

---

## Architecture
- **Frontend**: Flutter for cross-platform mobile development  
- **Backend**: Firebase for cloud sync, daily challenges, and analytics  
- **Storage**: Local (sqflite + JSON) + Firebase Firestore for cloud features  
- **Content**: Hybrid approach - static JSON for core content, Firestore for daily updates  

---

## Technology Stack (Finalized)
- **Framework**: Flutter (Dart)  
- **State Management**: Provider package (simple, upgradeable)  
- **Local Database**: sqflite package for progress/settings  
- **Local Content**: JSON files for core puzzle packs  
- **Cloud Database**: Firebase Firestore for daily challenges & user data  
- **Authentication**: Firebase Auth (optional accounts)  
- **Monetization**: google_mobile_ads + in_app_purchase packages  
- **Analytics**: Firebase Analytics & Crashlytics  
- **Platform Integration**: google_sign_in, games_services  

---

## Required Tools
- Flutter SDK (latest stable)  
- Android Studio with Flutter/Dart plugins  
- Android SDK & NDK  
- Firebase CLI  
- Git for source control  

---

## Key Design Decisions (Resolved)
- **Content Strategy**: Static JSON for 500+ core puzzles, Firestore for daily challenges  
- **User Accounts**: Optional - anonymous play allowed, accounts unlock cloud features  
- **Platform Launch**: Android-first, iOS later based on success  
- **Monetization**: Balanced - ads for free users, IAP for enhanced experience  
- **Localization**: English MVP, expand based on market response  
- **Offline Support**: Core gameplay works offline, online adds daily challenges  

---

## Architecture Principles
- **Offline-first**: Game playable without internet connection  
- **Progressive enhancement**: Online features enhance but don't block core gameplay  
- **Material Design 3**: Consistent, modern Android-native UI  
- **Modular content**: Easy to add new puzzle packs via JSON or Firestore  
- **Privacy-conscious**: Minimal data collection, optional accounts