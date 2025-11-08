# 📘 Togu

> **Share. Learn. Build Together.**

Togu is a student-friendly learning platform where users can ask questions, share answers, and earn badges for being active and helpful. Think of it as a focused, community-driven Q&A platform designed for students to connect and learn together.

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

---

## ✨ Features

### Core Functionality
- 🔐 **OneLogin Authentication** - Secure sign-in with OneLogin OIDC
- 📝 **Ask Questions** - Post questions with text, tags, code snippets, and images
- 💬 **Answer Questions** - Help others by providing detailed answers
- ⬆️ **Voting System** - Upvote helpful questions and answers
- 🏆 **Badges & Points** - Earn achievements and XP for your contributions
- 👤 **User Profiles** - View your stats, badges, questions, and answers
- 📊 **Leaderboard** - See top contributors ranked by points
- 🔍 **Search & Filter** - Find questions by text or tags
- 📱 **Modern UI** - Beautiful, intuitive SwiftUI interface

### Advanced Features
- ✨ **Pull-to-Refresh** - Refresh content with a simple swipe
- 📄 **Pagination** - Efficient loading of large question lists
- 🎨 **Code Snippet Support** - Syntax-highlighted code blocks
- 🏷️ **Tag System** - Organize content with predefined tags
- 📈 **Activity Feed** - Track your recent contributions
- 🎯 **Empty States** - Helpful messages when no content is available
- ⚡ **Error Handling** - Graceful error messages and retry logic
- 🔄 **Real-time Updates** - Instant UI updates after actions

---

## 🏗️ Architecture

Togu follows the **MVVM (Model-View-ViewModel)** architecture pattern for clean separation of concerns:

```
┌─────────────┐
│    Views    │  SwiftUI Views (UI Layer)
├─────────────┤
│  ViewModels │  Business Logic & State Management
├─────────────┤
│   Services  │  API & Data Layer (Airtable)
├─────────────┤
│    Models   │  Data Structures
└─────────────┘
```

### Key Components

- **Views**: SwiftUI views for UI presentation
- **ViewModels**: `ObservableObject` classes managing view state and business logic
- **Services**: Domain-specific services for API interactions
  - `QuestionsService` - Question operations
  - `AnswersService` - Answer operations
  - `UsersService` - User management
  - `VotesService` - Voting system
  - `BadgesService` - Badge management
  - `LeaderboardService` - Leaderboard data
- **Models**: Data structures representing entities (Question, Answer, User, etc.)

---

## 🛠️ Tech Stack

- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **iOS Version**: 17.0+
- **Authentication**: OneLogin OIDC
- **Backend**: Airtable API
- **Architecture**: MVVM
- **Async/Await**: Modern Swift concurrency

---

## 📋 Prerequisites

Before you begin, ensure you have:

- **Xcode 15.0+** installed
- **iOS 17.0+** deployment target
- **Airtable Account** with:
  - API Key
  - Base ID
  - Tables: `Users`, `Questions`, `Answers`, `Votes`, `Badges`
- **OneLogin Configuration**:
  - Client ID
  - Redirect URI: `com.shfa.Togu.oidc://`
  - OIDC configuration file (`OL-Oidc.plist`)

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/togu.git
cd togu
```

### 2. Configure Airtable

1. Create an Airtable base with the following tables:
   - **Users** (Name, Email, ProfilePicture, Points, Badges)
   - **Questions** (Title, Body, Tags, Author, Upvotes, Image)
   - **Answers** (AnswerText, Author, Question, Upvotes, CreatedDate)
   - **Votes** (User, TargetType, TargetQuestion, TargetAnswer)
   - **Badges** (Badge Name, Description, Icon, EarnedBy, DateEarned)

2. Get your Airtable API Key and Base ID from [Airtable Account](https://airtable.com/account)

### 3. Configure OneLogin

1. Set up your OneLogin OIDC application
2. Add the redirect URI: `com.shfa.Togu.oidc://`
3. Place your `OL-Oidc.plist` configuration file in `Togu/Resources/`

### 4. Set Environment Variables

Add the following to your Xcode project's build settings or `Info.plist`:

```xml
<key>AIRTABLE_KEY</key>
<string>your_airtable_api_key</string>
<key>AIRTABLE_BASE_ID</key>
<string>your_airtable_base_id</string>
```

Alternatively, set them as environment variables in your Xcode scheme.

### 5. Build and Run

1. Open `Togu.xcodeproj` in Xcode
2. Select your target device or simulator
3. Press `Cmd + R` to build and run

---

## 📁 Project Structure

```
Togu/
├── App/
│   ├── ToguApp.swift          # App entry point
│   ├── RootRouter.swift       # Navigation router
│   └── AppDelegate.swift      # App lifecycle
│
├── Model/
│   ├── Question.swift         # Question data model
│   ├── Answer.swift           # Answer data model
│   ├── AuthState.swift        # Authentication state
│   ├── LeaderboardEntry.swift # Leaderboard entry
│   ├── Activity.swift         # User activity
│   ├── Skill.swift            # User skills
│   ├── LevelInfo.swift        # Level calculation
│   └── AirtableModels.swift   # Airtable field mappings
│
├── ViewModel/
│   ├── AuthViewModel.swift           # Authentication logic
│   ├── FeedViewModel.swift           # Question feed logic
│   ├── HomeViewModel.swift           # Home screen logic
│   ├── QuestionDetailViewModel.swift # Question detail logic
│   ├── AnswerFormViewModel.swift     # Answer form logic
│   ├── AskQuestionViewModel.swift    # Ask question logic
│   ├── ProfileViewModel.swift        # Profile logic
│   ├── LeaderboardViewModel.swift    # Leaderboard logic
│   └── LoginViewModel.swift          # Login screen logic
│
├── Views/
│   ├── MainTabView.swift          # Tab navigation
│   ├── HomeView.swift             # Question feed
│   ├── QuestionDetailView.swift   # Question details
│   ├── AskQuestionView.swift      # Post question
│   ├── AnswerFormView.swift       # Post answer
│   ├── ProfileView.swift          # User profile
│   ├── LeaderboardView.swift      # Leaderboard
│   ├── LoginView.swift            # Login screen
│   ├── SplashView.swift           # Splash screen
│   └── Components/                # Reusable UI components
│       ├── Profile/
│       ├── Leaderboard/
│       ├── QuestionDetail/
│       ├── EmptyStateView.swift
│       ├── LoadingView.swift
│       ├── ErrorView.swift
│       └── ErrorToast.swift
│
├── Services/
│   ├── AirtableService.swift      # Main Airtable facade
│   ├── QuestionsService.swift     # Question operations
│   ├── AnswersService.swift       # Answer operations
│   ├── UsersService.swift         # User operations
│   ├── VotesService.swift         # Voting operations
│   ├── BadgesService.swift        # Badge operations
│   ├── LeaderboardService.swift  # Leaderboard operations
│   ├── AirtableConfig.swift       # Airtable configuration
│   └── AirtableListResponse.swift # API response models
│
├── Utilities/
│   ├── FormattingHelpers.swift    # Date/number formatting
│   └── MarkdownHelpers.swift      # Markdown processing
│
└── Resources/
    ├── Assets.xcassets           # App assets
    ├── Theme.swift                # App theme & colors
    ├── Info.plist                 # App configuration
    └── OL-Oidc.plist              # OneLogin config
```

---

## 🎨 Design System

Togu uses a custom design system defined in `Theme.swift`:

- **Primary Color**: `toguPrimary` - Main brand color
- **Background**: `toguBackground` - App background
- **Text Colors**: `toguTextPrimary`, `toguTextSecondary`
- **Card Colors**: `toguCard`, `toguBorder`
- **Error Colors**: `toguError`, `toguDisabled`

All colors are accessible via SwiftUI's `Color` extension.

---

## 🔐 Authentication Flow

1. User taps "Sign in with IDServe" on `LoginView`
2. `AuthViewModel` initiates OneLogin OIDC flow
3. User authenticates via OneLogin
4. App receives OIDC callback with tokens
5. User is redirected to `MainTabView` (Home)
6. User data is synced with Airtable `Users` table

---

## 📊 Data Flow

### Question Feed
```
HomeView → FeedViewModel → QuestionsService → Airtable API
```

### Posting a Question
```
AskQuestionView → AskQuestionViewModel → QuestionsService → Airtable API
                → BadgesService (check milestones)
                → UsersService (award points)
```

### Voting
```
QuestionDetailView → QuestionDetailViewModel → VotesService → Airtable API
                  → UsersService (award points to author)
```

---

## 🧪 Testing

To test the app:

1. **Login**: Use your OneLogin credentials
2. **Ask Questions**: Post questions with tags and optional images
3. **Answer Questions**: Provide helpful answers
4. **Vote**: Upvote quality content
5. **Check Profile**: View your badges, points, and activity
6. **Leaderboard**: See top contributors

---

## 🐛 Known Issues

- Mesh gradient background requires iOS 18.0+ (fallback provided for earlier versions)
- Image uploads are limited by Airtable's attachment size limits
- Badge awarding may have a slight delay due to Airtable indexing

---

## 🚧 Roadmap

- [ ] Push notifications for new answers
- [ ] Markdown editor for questions/answers
- [ ] Image compression before upload
- [ ] Offline mode with local caching
- [ ] Dark mode support
- [ ] Question categories
- [ ] Answer acceptance feature
- [ ] User mentions and notifications

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Swift naming conventions
- Use SwiftUI best practices
- Maintain MVVM architecture
- Add comments for complex logic
- Keep functions focused and small

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Authors

- **Your Name** - *Initial work* - [YourGitHub](https://github.com/yourusername)

---

## 🙏 Acknowledgments

- [Airtable](https://airtable.com) for the backend infrastructure
- [OneLogin](https://www.onelogin.com) for authentication
- SwiftUI community for inspiration and best practices

---

## 📞 Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/yourusername/togu/issues) page
2. Create a new issue with detailed information
3. Contact the maintainers

---

## 📸 Screenshots

_Add screenshots of your app here_

---

**Made with ❤️ for students, by students**

