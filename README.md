# Tutor_app-Learnova – Mathematics Tutoring Mobile App

Learnova is a full-stack mobile application designed to streamline the learning experience between teachers and students. It provides a centralized platform for managing classes, communication, assignments, and payments in an efficient and user-friendly way.

🚀 Overview

Learnova bridges the gap between teachers and students by offering real-time interaction, structured learning management, and seamless communication — all within a single mobile application.

✨ Features
👨‍🎓 For Students

📅 View class schedules with Google Meet links

📥 Download study notes & upload assignments

💬 Real-time private chat with teachers

💳 Upload payment receipts & track subscriptions

🔔 Receive instant notifications

👩‍🏫 For Teachers

📅 Create & manage class schedules

📤 Upload learning materials

📝 Review & grade assignments

✅ Approve student payments

📢 Send announcements

💬 Real-time messaging with students

🛠️ Tech Stack
Layer	Technology
Frontend	Flutter (Dart)
Backend	Node.js + Express.js
Database	MongoDB Atlas
Authentication	JWT + bcrypt
File Handling	Multer
Hosting	Railway (Backend), MongoDB Atlas
Tools	Git, GitHub, VS Code
📂 Project Structure
## 📂 Project Structure

```
learnova/
├── frontend/              # Flutter mobile application
│   ├── lib/               # Main Dart source code
│   ├── assets/            # Images, fonts, etc.
│   └── pubspec.yaml       # Flutter dependencies
│
├── backend/               # Node.js + Express API
│   ├── controllers/       # Business logic
│   ├── models/            # MongoDB schemas
│   ├── routes/            # API endpoints
│   ├── middleware/        # Authentication & validation
│   ├── config/            # Database & app config
│   └── server.js          # Entry point
│
├── uploads/               # File storage (if local)
├── .env                   # Environment variables
├── package.json
└── README.md
```
🔐 Key Functionalities

Role-Based Access Control (Student / Teacher)

Secure Authentication using JWT

Real-time Chat System

File Upload & Download Management

Payment Verification Workflow

Notification System

⚙️ Installation & Setup
1. Clone the repositories
git clone https://github.com/your-username/learnova-frontend.git
git clone https://github.com/your-username/learnova-backend.git
2. Backend Setup
cd learnova-backend
npm install

Create a .env file:

PORT=5000
MONGO_URI=your_mongodb_connection
JWT_SECRET=your_secret_key

Run backend:

npm start
3. Frontend Setup (Flutter)
cd learnova-frontend
flutter pub get
flutter run
🌐 Deployment

Backend deployed on Railway

Database hosted on MongoDB Atlas

Frontend runs as a cross-platform mobile app

🎯 Key Highlights

📌 Full-stack mobile application (Flutter + Node.js)

🔐 Secure authentication & role management

💬 Real-time communication system

☁️ Cloud-based architecture

🎨 Modern UI (Glassmorphism design)

🚀 Production-ready deployment

🔗 GitHub Links

Frontend: https://lnkd.in/gM85UMHv

Backend: https://lnkd.in/g6hVfE42

📈 Learning Outcomes

Built a complete mobile + backend ecosystem

Gained experience in REST API development

Implemented authentication & authorization

Worked with cloud databases (MongoDB Atlas)

Improved skills in Flutter mobile development

🔮 Future Improvements

Push notifications (Firebase Cloud Messaging)

Video class integration inside app

Payment gateway integration

Admin dashboard

AI-based learning recommendations

👩‍💻 Author

Nethmi Amasha
Software Engineering Undergraduate
