# Awoken The Nations Ministries - Expense Tracker

A complete production-ready expense tracker app with a Flutter frontend and FastAPI backend, containerized using Docker.

## Project Structure

- `/backend`: FastAPI Python backend with PostgreSQL database.
- `/mobile`: Flutter mobile and web frontend application.

## Getting Started

### Prerequisites
- Docker
- Docker Compose

### Running the Application

1. Make sure Docker is running on your machine.
2. Clone the repository and navigate to the root directory.
3. Start the application using Docker Compose:
   ```bash
   docker-compose up --build -d
   ```

The application will be available at:
- Frontend (Web): http://localhost:8080
- Backend API Docs: http://localhost:8000/docs

### Default Credentials (after initial seed)

| Role | Email | Password |
|---|---|---|
| Super Admin | `super@awoken.com` | `password` |
| Admin | `admin@awoken.com` | `password` |
| User | `john@example.com` | `password` |
| User | `jane@example.com` | `password` |

## Local Development Setup (Without Docker)

### Backend
1. Navigate to `/backend`
2. Create virtual environment: `python -m venv venv`
3. Activate: `source venv/bin/activate` (Linux/Mac) or `venv\Scripts\activate` (Windows)
4. Install requirements: `pip install -r requirements.txt`
5. Setup a local PostgreSQL instance and update `.env`
6. Run migrations: `alembic upgrade head`
7. Start server: `uvicorn app.main:app --reload`

### Frontend
1. Navigate to `/mobile`
2. Run `flutter pub get`
3. Run `flutter run -d chrome` or select an emulator

## Features

- **Role-based Access Control**: SuperAdmin, Admin, and User roles.
- **Multi-currency Support**: Track balances in USD, TZS, and KES.
- **Dashboard**: Overview of balances, self-receipt percentage, and recent transactions.
- **Expense Management**: Add, edit, delete, and view expenses with filtering options.
- **User Management**: Admins can view users; SuperAdmins can change user roles.
"# exp" 
"# exp" 
