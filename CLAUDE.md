# Claude Guide — Reverse Dictionary Game

---

## How Claude Should Work on This Project
1. Always read `planning.md` at the start of every session  
2. Check `tasks.md` before starting work  
3. Work only on the **next incomplete task**  
4. Mark tasks as complete once done  
5. Add newly discovered tasks as needed  
6. Append a **Session Summary** at the end of each session  

---

## Technology Stack (Finalized)
- **Framework**: Flutter (Dart)  
- **State Management**: Provider package  
- **Local Database**: sqflite package  
- **Local Content**: JSON files for core puzzles  
- **Cloud Services**: Firebase (Firestore, Auth, Analytics, Crashlytics)  
- **Monetization**: google_mobile_ads + in_app_purchase packages  
- **Platform Integration**: google_sign_in, games_services packages  

---

## Content Pipeline
This project uses a **prompt-driven content pipeline** (see `puzzles_base.json`):  
- Puzzle generation: definition / emoji / riddle packs using LLM prompts  
- QA validation + deduplication to ensure quality  
- JSON → sqflite database loading for efficient local storage  
- Flutter widget scaffolding for consistent UI components  
- Play Store listing + localization content generation  

Claude should use these patterns to **create, validate, and integrate puzzle content**.

---

## Development Principles
- **Flutter-first**: Design with widgets and Material Design 3 in mind  
- **Offline-capable**: Core gameplay must work without internet  
- **Provider pattern**: Use Provider for state management, avoid complex patterns  
- **Test-driven**: Write tests for game logic and critical UI components  
- **Privacy-conscious**: Minimal data collection, optional user accounts  

---

## Architecture Decisions (All Resolved)
✅ **Framework**: Flutter chosen over Unity for UI-heavy game  
✅ **State Management**: Provider package (simple, upgradeable to Riverpod later)  
✅ **Content Strategy**: Hybrid - static JSON for core, Firestore for daily challenges  
✅ **User Accounts**: Optional - anonymous play allowed, accounts unlock cloud features  
✅ **Monetization**: Balanced approach - ads for free users, IAP for enhanced experience  
✅ **Platform Launch**: Android-first, iOS expansion based on success metrics  
✅ **Localization**: English MVP, expand to major languages if successful  

---

## Project Structure
```
lib/
├── models/          # Data models (Puzzle, UserProgress, etc.)
├── services/        # Firebase, database, ads services
├── providers/       # Provider state management classes
├── screens/         # UI screens (game, settings, etc.)
├── widgets/         # Reusable UI components
├── utils/           # Helpers, constants, extensions
└── main.dart        # App entry point

assets/
├── puzzles/         # JSON puzzle pack files
├── images/          # Icons, graphics
└── sounds/          # Audio files (if needed)
```

---

## Quality Standards
- **Code**: Follow Flutter/Dart style guide, use meaningful variable names  
- **UI**: Material Design 3 components, consistent spacing, accessible design  
- **Performance**: Target 60fps, minimize widget rebuilds, optimize images  
- **Testing**: Unit tests for business logic, widget tests for UI components  
- **Content**: All puzzles reviewed for quality, appropriateness, difficulty balance  

---

## Session Summaries

### Session 1
- Integrated existing docs (`game design`, `prompts`, `dev plan`) into Claude framework  
- Created `prd.md`, `planning.md`, `tasks.md`, `claude.md`  
- **Next**: Begin Milestone 1, Task 1 → Install Flutter SDK + Android Studio setup  

### Session 2  
- Updated all documentation from Unity to Flutter  
- Identified key architecture decisions needed for implementation  
- Restructured tasks to reflect Flutter development workflow  
- **Next**: Make state management decision and begin Flutter project setup

### Session 3
- **RESOLVED ALL DECISIONS**: Finalized technology stack and architecture choices  
- Updated all 4 documents with concrete recommendations (no more decision points)  
- Documents now ready for Claude Code implementation  
- **Next**: Claude Code should begin Milestone 1, Task 1 → Flutter SDK installation

### Session 4 (Claude Code Implementation)
- **MILESTONE 1 PROGRESS**: Successfully installed Flutter SDK and created project structure
- Installed Flutter SDK from GitHub (stable branch) in WSL environment
- Created `wordquest_reverse_dictionary` Flutter project with proper directory structure:
  - `lib/` with models, services, providers, screens, widgets, utils folders
  - `assets/` with puzzles, images, sounds folders
- Set up `pubspec.yaml` with core dependencies: provider, sqflite, path_provider
- Copied all puzzle JSON files (`puzzles_base.json`, `puzzles_base200.json`, etc.) to assets
- Created basic `main.dart` with Material Design 3 theme and home screen
- Flutter toolchain setup in progress (building tools on first run)
- **Next**: Complete Flutter pub get, then implement puzzle data models and JSON loader

### Session 5 (Data Models & JSON Loader Implementation)
- **MILESTONE 1 TASKS COMPLETED**: Implemented puzzle data models and JSON loader system
- Created comprehensive `Puzzle` model with JSON/database serialization and answer validation
- Built `PuzzlePack` model with filtering and statistics methods
- Implemented `PuzzleLoaderService` for loading puzzle data from JSON assets
- Created `DatabaseService` with full sqflite schema for puzzles, progress, and settings
- Built `PuzzleInitializationService` to orchestrate JSON loading into database
- Updated `main.dart` to test puzzle initialization with loading UI
- All code passes Flutter static analysis without errors
- **Next**: Continue with Milestone 1 → Build basic game screen with clue display and text input

### Session 6 (Flutter Setup & Game Screen Implementation) 
- **MILESTONE 1 COMPLETION**: Successfully set up Flutter environment and implemented working game
- **Flutter SDK Installation**: Fixed broken Flutter installation in WSL, downloaded and configured Flutter 3.24.4 stable
- **Database Compatibility**: Resolved sqflite database factory errors on web with adaptive storage solution:
  - Created `WebStorageService` using browser LocalStorage for web platforms
  - Built `AdaptiveDatabaseService` that auto-detects platform and uses appropriate storage
  - Updated all services to use adaptive database for cross-platform compatibility
- **Game Screen Implementation**: Built fully functional game interface with:
  - Material Design 3 UI with clue display, answer input, and feedback system
  - Animation controllers for smooth feedback transitions and haptic feedback
  - Puzzle navigation, hint system, and completion dialogs
  - Progress tracking with puzzle counters and completion celebration
- **Web Deployment**: Successfully deployed game on Flutter web server at localhost:8080
- **Error Resolution**: Fixed MultiProvider empty list error and missing getPuzzles method
- Game now fully functional on web with puzzle loading, answer validation, and progression
- **Next**: Continue Milestone 1 → Implement answer validation and scoring logic (already functional)

### Session 7 (Provider State Management & UI Enhancement)
- **MILESTONE 2 PROGRESS**: Successfully implemented Provider-based state management architecture
- **Task Verification**: Audited existing implementation and updated task tracker to reflect actual progress
  - Confirmed Milestone 1 is fully complete with working game, validation, and navigation
  - Identified hint system was already implemented and marked as complete
- **Provider Architecture**: Built comprehensive state management system:
  - Created `GameProvider` with centralized game state, statistics, and business logic
  - Implemented reactive UI updates, auto-progression, and completion handling
  - Added enhanced game statistics (score, accuracy, attempts, progress tracking)
- **UI Enhancements**: Upgraded game interface with Provider-based `GameScreenProvider`:
  - **Icon Size Increase**: Enlarged all game icons from 24px to 28px for better visibility
  - Added linear progress indicator showing game completion percentage  
  - Enhanced app bar with score display and skip puzzle functionality
  - Improved completion dialog with detailed statistics (score, accuracy, correct answers)
  - Better error handling and loading states with reactive UI
- **Code Quality**: Clean separation of concerns between UI and business logic
- **Web Deployment**: Successfully tested Provider implementation at localhost:8080
- **Next**: Continue Milestone 2 → Create difficulty progression system (easy → medium → hard)