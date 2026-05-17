# AI Interviewer (FYP)

Comprehensive Flask application for managing AI-driven interview workflows for companies. This project provides company-scoped dashboards, deployment of automated interview sessions, candidate evaluation, and basic admin functionality. It integrates with multiple LLM providers (OpenAI, Google Gemini, Anthropic) and stores interview and user data in a MySQL database.

## Table of contents

- Overview
- Architecture & key files
- Database schema (summary)
- Routes and features
- Setup & run
- Environment variables
- Troubleshooting
- Development notes

## Overview

This project is designed for companies to deploy automated AI interviews to their employees/candidates. Main capabilities:

- Deploy interviews targeted to specific designations and company users
- Track interview status (`pending`, `in_progress`, `completed`) and evaluation scores
- Map users to company-specific `employee_id` values via `company_users`
- Admin views for platform-wide management

## Architecture & key files

- `app.py`: Main Flask application with routes for admin, company, and client flows.
- `templates/`: Jinja2 templates for UI (dashboards, interview-management, modals).
- `static/`: CSS, JS, image assets and uploads (profiles, documents).
- `python/interview_service.py`: Interview orchestration and LLM provider integration.
- `python/dashboard_routes.py`: Shared UI context builder used by templates.
- `requirements.txt`: Python dependencies.

## Database schema (summary)

Key tables used by the app (see `database.sql` for full schema):

- `users`: platform users with `id`, `email`, `first_name`, `last_name`, `role` (admin, company, client, company_user), `company_id`, `profile_img`, etc.
- `companies`: company accounts with `id`, `company_name`, `email` (used to map company admin user), contact fields.
- `company_users`: mapping records with `user_id`, `company_id`, and `employee_id` (8-char company-specific identifier).
- `interviews`: interview records with `id`, `user_id`, `company_id`, `employee_id`, `target_role`, `status`, `duration`, `overall_score`, timestamps.
- `notifications`, `activities`, `subscriptions`: auxiliary tables used across the UI.

## Routes and features

### Company routes (protected by `session['role']=='company'`)

- `/companies/dashboard`: company dashboard and stats
- `/companies/interview-management`: list + manage active interviews (shows `pending` + `in_progress`)
- `/companies/interview/deploy` (POST): deploy interviews to selected users (accepts `user_id` or `employee_id` values)
- `/companies/interview/results`: fetch evaluated results for a role
- `/companies/notification`: company notifications and compose modal

### Admin routes

- `/admin/*` pages for managing platform data and viewing analytics.

### Key behaviors

- Deploy flow accepts either numeric `user_id` or `employee_id` strings; backend resolves `employee_id` to `user_id` and persists interviews.
- Interview listing joins `users` and `company_users` to show candidate names and `employee_id` and counts evaluated results per `target_role`.

## Setup & run

Prerequisites:

- Python 3.11 or 3.12 (recommended)
- MySQL server

Install dependencies and run locally:

```bash
python -m venv venv
# Windows
venv\Scripts\activate
pip install -r requirements.txt

# Import schema (adjust DB name as needed)
mysql -u root -p fyp_db < database.sql

# Run Flask app
setx FLASK_APP app.py
setx FLASK_ENV development
flask run

# or
python app.py
```

Open `http://127.0.0.1:5000` in your browser.

## Vercel + Supabase deployment

This project now supports deploying the Flask app on Vercel while pointing the database layer at Supabase Postgres.

1. Create a Supabase database and run [supabase.sql](supabase.sql) against it.
2. In Vercel, set `DATABASE_URL` to the Supabase connection string.
3. Set `FLASK_SECRET_KEY` and any email or LLM provider keys in Vercel environment variables.
4. Deploy the repo as-is. The Vercel entrypoint is [api/index.py](api/index.py) and the route config is [vercel.json](vercel.json).

For local Postgres testing, you can also set `DATABASE_URL` in your `.env` file. If `DATABASE_URL` is present, the app uses Postgres; otherwise it falls back to the existing MySQL settings.

## Environment variables

Create a `.env` file in the project root with these values (minimum):

```env
FLASK_SECRET_KEY=some_secret
DATABASE_URL=postgresql://user:password@host:5432/postgres
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=secret
DB_NAME=fyp_db
DB_PORT=3306
```

Optional (LLM provider API keys / email):

```env
OPENAI_API_KEY=
GEMINI_API_KEY=
ANTHROPIC_API_KEY=
BREVO_SMTP_HOST=
BREVO_SMTP_PORT=
BREVO_SMTP_USER=
BREVO_SMTP_PASSWORD=
BREVO_SENDER_EMAIL=
```

## Troubleshooting

- If no interviews appear on `/companies/interview-management`:

  - Check the debug banner at the top of the page (shows `Company ID` and upcoming count).
  - Look in the server console for debug prints like: `[debug] upcoming_count=<n> for company_id=<id>; upcoming_ids=[...]`.
  - Confirm `interviews` rows exist for that `company_id` and have `status` equal to `pending`, `in_progress`, or `completed` as appropriate.

- DB connection errors: validate `.env` credentials and that MySQL is running.
- LLM provider errors: ensure API keys are set in `.env` and that installed SDK versions match the requirements.

## Development notes

- Templates: `templates/companies/interview-management.html` contains the deploy modal, candidate selection UI, and the active interviews table.
- When adding features, keep UI flows company-scoped by using `session['email']` to resolve `company_id` and validating `company_id` on writes.
- The `InterviewService` encapsulates provider-specific logic and can be extended to add more providers or models.

## Next steps (suggestions)

- Add a `seed_demo.py` to populate sample companies, users, company_users, and interviews for local testing.
- Add unit tests for key DB queries and the deploy flow.
- Add Dockerfile + docker-compose for reproducible local environment.

If you want, I can add any of the suggested next-step files (seed script, tests, or Docker setup). Open an issue or ask me to scaffold one.
