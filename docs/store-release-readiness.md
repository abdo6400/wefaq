# Wefaq Store Release Readiness, Data Safety & Production Guide

**Date:** 12 November 2026  
**Application Title:** وفاق: حوارات مقبلين على الزواج (Wefaq)  
**Package Identifier:** `com.wefaq.wefaq` (Placeholder until production domain registration)  
**Target Platform:** Android (Google Play Store) & iOS (Apple App Store)  
**Target Market:** Egypt & Arabic-speaking regions  
**Category:** Lifestyle / Family & Relationships  
**Content Rating Target:** Everyone 18+ (Mature adult relationship dialogue)

---

## 1. Store Listing Assets and Arabic Copy

### App Title
- **AR:** وفاق: حوارات هادفة للمخطوبين
- **EN:** Wefaq: Meaningful Dialogue for Engaged Couples

### Short Description (Max 80 chars)
- **AR:** أسئلة وأنشطة حوارية هادفة للمقبلين على الزواج في خصوصية تامة وبدون تسجيل.
- **EN:** Guided questions and dialogue activities for engaged couples in complete privacy.

### Full Description (Arabic)
```
أهلًا بكم في «وفاق» — رفيق الحوار الهادئ للمخطوبين والمقبلين على الزواج.

يهدف وفاق إلى تيسير حوارات واعية وبناءة بين المخطوبين حول أهم محاور الحياة المشتركة، بأسلوب هادئ ومحترم بعيدًا عن الضغط أو الإحراج.

لماذا وفاق؟
• خصوصية تامة 100%: التطبيق لا يسجل إجاباتكم أو تفاصيل حواركم، ولا يحفظ أي تسجيلات صوتية أو نصوص خاصة إطلاقًا.
• نمطان للحوار:
  - «مع بعض»: حوار مباشر هادئ من جهاز واحد وأنتما معًا.
  - «في مكالمة»: قراءة وتنسيق الأسئلة أثناء مكالمتكم الخارجية عبر الهاتف أو الإنترنت.
• محاور حياتية شاملة:
  - أساليب التواصل وإدارة الخلافات بهدوء
  - نمط الحياة والمسؤوليات اليومية والمنزلية
  - الأهل والحدود الأسرية
  - التطلعات المالية والميزانية المشتركة
  - القيم والمبادئ الأساسية في الحياة
• أنشطة ومواقف واقعية: بطاقات تفاعلية لمناقشة مواقف يومية محتملة وترتيب الأولويات المشتركة.
• حرية كاملة: لكل طرف الحق التام في تخطي أي سؤال دون إبداء أسباب، فالهدف هو راحة الطرفين وبناء التفاهم.
• اشتراك واحد لشخصين: تفعيل سهل لكلا الطرفين على جهازين مستقلين مع دعم فني مخصص.

وفاق ليس تطبيقًا للمطابقة أو الدردشة، ولا يقدم فتاوى أو استشارات طبية؛ بل هو مساحة منظمة تجمعكما على حوار راقٍ يقرّب الفهم ويؤسس لحياة مستقرة بإذن الله.
```

### Promotional Graphic & Screenshot Captions
1. **Screen 1 (Home):** حوار هادئ يقرّب الفهم — خطوتكم الأولى لحياة مشتركة واعية
2. **Screen 2 (Modes):** اختاروا طريقة الحوار — مع بعض من جهاز واحد، أو أثناء مكالمتكم الخارجية
3. **Screen 3 (Questions):** أسئلة متدرجة ومحاور مدروسة — التواصل، الحياة اليومية، المالية، والأهل
4. **Screen 4 (Activities):** أنشطة ومواقف واقعية — ناقشوا المواقف ورتبوا الأولويات معًا
5. **Screen 5 (Privacy):** خصوصية مطلقة — لا نسجل إجاباتكم أو تفاصيل حواركم إطلاقًا

---

## 2. Google Play Data Safety Declaration

Under Google Play Developer Policy and Egypt's Personal Data Protection Law (Law 151/2020):

| Policy Question | Response | Technical Justification |
|---|---|---|
| **Does your app collect or share any user data?** | **No** | Wefaq collects zero personal data, zero analytics identifiers, and zero conversation content. |
| **Is all data processed ephemerally?** | **Yes (for dialogue)** | Questions are displayed on screen. Responses are spoken aloud by users; no app recording occurs. |
| **Does the app collect audio or voice recordings?** | **No** | Microphone permissions are not requested (`RECORD_AUDIO` is absent from AndroidManifest.xml). |
| **Does the app collect location, contacts, or photos?** | **No** | Zero sensitive platform permissions requested. |
| **Does the app track across apps or websites?** | **No** | Advertising ID (`AD_ID`) is strictly disabled. |
| **What data is stored locally?** | **App Preferences only** | Installation identity UUID (anonymously generated), local favorites, question history, and session state. Never synced to remote servers without user request. |
| **Is local data encrypted/sandboxed?** | **Yes** | Uses app internal private sandboxed storage (`getApplicationDocumentsDirectory()`). |
| **Can users request data deletion?** | **Yes** | One-tap "Discard session" and clearing app data purges all local state instantly. |

---

## 3. Production Signing Configuration

### `android/key.properties.example`
Before creating release bundles, create `android/key.properties`:
```properties
storePassword=<STORE_PASSWORD>
keyPassword=<KEY_PASSWORD>
keyAlias=wefaq-release-key
storeFile=../keystore/wefaq-release-keystore.jks
```

### `android/app/build.gradle` Production Configuration
```groovy
def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### Proguard Rules (`android/app/proguard-rules.pro`)
```proguard
# Flutter ProGuard baseline
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep domain data models from obfuscation reflection issues
-keep class com.wefaq.wefaq.** { *; }
```

---

## 4. Release Commands

### 1. Build Production App Bundle (AAB for Google Play):
```bash
flutter build appbundle --release
```

### 2. Build Release APK (for Direct Sideload / Manual Distribution in Egypt):
```bash
flutter build apk --release --split-per-abi
```

### 3. Verify Code Integrity & Lints:
```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
