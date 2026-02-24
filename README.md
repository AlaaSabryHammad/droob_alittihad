# Droob Alittihad (دروب الاتحاد)

**Droob Alittihad** is a professional Flutter-based application designed for road maintenance inspection and reporting, specifically tailored for **Droob Alittihad Contracting Co.**

The application streamlines the process of documenting road issues, capturing real-time location data, and generating standardized PDF reports for submission to municipal authorities.

## 🚀 Features

- **Inspection Reporting:** Comprehensive forms to document road maintenance needs.
- **Location Integration:** Automatically capture GPS coordinates for precise issue localization.
- **Media Support:** Attachment of images to document site conditions.
- **PDF Generation:** Create professional, ready-to-print inspection reports in PDF format.
- **Sharing Capabilities:** Easily share generated reports via various platforms (WhatsApp, Email, etc.).
- **Localization:** Full support for Arabic (Saudi Arabia) with a custom "Cairo" font for a native feel.
- **Splash Screen:** Branded entry experience reflecting the company identity.

## 🛠️ Tech Stack

- **Framework:** Flutter (Material 3)
- **Key Dependencies:**
  - `geolocator`: For GPS location services.
  - `image_picker`: For documenting site conditions with photos.
  - `pdf` & `printing`: For generating and handling report documents.
  - `share_plus`: For report distribution.
  - `shared_preferences`: For local data persistence.

## 📁 Project Structure

- `lib/screens/`: UI implementation including forms, history, and splash screens.
- `lib/services/`: Core logic for location, PDF generation, and storage.
- `lib/models/`: Data structures for inspection reports.
- `assets/`: High-quality fonts and company branding assets.

## 📦 Getting Started

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/AlaaSabryHammad/droob_alittihad.git
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the application:**
    ```bash
    flutter run
    ```

---
*Developed for Droob Alittihad Contracting Co.*
