You are an elite senior software architect, Flutter expert, Supabase expert, and AI systems engineer.

You are tasked to DESIGN and BUILD a COMPLETE, PRODUCTION-READY mobile application called:

========================
🏥 MEDTRACE
========================

This application MUST be ready for:
- Google Play Store submission
- Apple App Store submission

NO missing features.
NO incomplete logic.
NO placeholder code.
NO skipped steps.

Everything must be fully working.

This is a tuberculosis (TBC) monitoring ecosystem with:
- Mobile app (Flutter)
- Backend (Supabase)
- Realtime system
- AI chatbot
- Geospatial analysis

This is NOT a demo.
This must be FULLY FUNCTIONAL, SCALABLE, and PRODUCTION-READY.

You MUST NOT skip anything.

==================================================
🧠 PRIMARY MISSION
==================================================

Solve real-world tuberculosis monitoring problems:

1. Track TB spread geographically
2. Centralize patient data
3. Monitor treatment adherence
4. Prevent treatment dropouts
5. Provide accessible public education

==================================================
👥 ROLE SYSTEM (STRICT SEPARATION)
==================================================

There are ONLY TWO ROLES:

1. DOCTOR (complex system, data-heavy, analytics-heavy)
2. PATIENT (simple, guided, easy UX)

STRICT separation:
- Patient cannot access doctor features
- Doctor has full control over their patients

STRICT ROLE-BASED SYSTEM — NO OVERLAP

==================================================
🎨 DESIGN SYSTEM (MUST MATCH PROVIDED UI IMAGES)
==================================================

Follow the UI style EXACTLY like the provided design references.

GENERAL STYLE:
- Modern medical UI
- Minimalist
- Soft shadows
- Rounded cards
- Clean spacing
- High readability

--------------------------------
🎨 PATIENT THEME (SIMPLER UI)
--------------------------------
- Primary: #0F766E (Teal)
- Secondary: #14B8A6
- Background: #F0FDFA
- Accent: #EAB308

UI behavior:
- Simple
- Guided
- Clear actions
- Minimal data overload

--------------------------------
🎨 DOCTOR THEME (MORE COMPLEX UI)
--------------------------------
- Primary: #134E4A (Darker teal)
- Secondary: #0F766E
- Background: #ECFEFF
- Alert colors:
  - Red: for critical alerts
  - Yellow: warnings
  - Green: stable patients

UI behavior:
- Data-rich dashboards
- Analytical cards
- Dense but structured info
- Multi-layer navigation

==================================================
🔐 AUTHENTICATION SYSTEM (CRITICAL)
==================================================

DOCTOR:
- Created ONLY by admin manually via database
- Has role = "doctor"

PATIENT:
- CANNOT register freely
- MUST use doctor-provided registration code

PATIENT REGISTRATION FLOW:
1. Input:
   - doctor_code
   - email
   - password
2. Validate doctor_code
3. Create auth user
4. Link to doctor_id
5. Insert profile

PASSWORD RESET:
- via email

DOCTOR:
- Created ONLY via database (admin controlled)
- Cannot self-register

PATIENT:
- MUST register using:
  - doctor_code
  - email
  - password

REGISTRATION FLOW:
1. Validate doctor_code from database
2. Create auth user
3. Link to doctor_id
4. Insert into profiles table

PASSWORD RESET:
- Email-based recovery

SESSION:
- Persist login securely

==================================================
🗄️ DATABASE DESIGN (STRICT REQUIREMENT)
==================================================

Use Supabase PostgreSQL

You MUST:
- Full SQL schema
- Create FULL SQL migration
- Include relationships
- Use foreign keys
- Add indexes
- Constraints
- Enable RLS
- RLS Policies

TABLES:

1. profiles
2. doctor_codes
3. patients
4. treatments
5. medication_logs
6. reminders
7. chatbot_logs
8. notifications

TREATMENT LOGIC (VERY IMPORTANT):

phase:
- intensive (first 0-2 months)
- continuation (next 3-6 months)

status:
- ongoing
- completed
- defaulted (patient stopped treatment)

adherence_percentage:
- calculated from medication_logs
- calculated dynamically

==================================================
🔒 RLS (MANDATORY, NO EXCEPTION)
==================================================

PATIENT:
- can only read/write their own data

DOCTOR:
- can only access their patients

BLOCK ALL UNAUTHORIZED ACCESS

==================================================
📱 MOBILE APP (FLUTTER)
==================================================

Use:

- Flutter (latest stable)
- Riverpod
- GoRouter
- Clean Architecture

Structure MUST include:

lib/
  core/
  data/
  features/
  shared/

Include:
- service layer
- repository layer
- model layer


==================================================
📲 FEATURES — PATIENT APP
==================================================

1. DASHBOARD
- greeting
- Adherence percentage %
- today's medication
- Medication reminder
- therapy progress

2. MAP (SPATIAL)
- show TB cases
- TB distribution markers
- markers from patient locations
- gather data from permission app on flutter

3. TREATMENT TRACKER
- phase indicator
- progress bar
- status

4. MEDICATION REMINDER
- Daily schedule
- Schedule
- mark as taken
- auto logging

5. CHATBOT AI
- conversational UI
- health assistant
- context-aware answers
- Educational responses

==================================================
🧑‍⚕️ FEATURES — DOCTOR APP
==================================================

1. DASHBOARD
- total patients
- adherence rate
- alerts
- High-risk alerts

2. PATIENT MANAGEMENT
- list
- Patient list
- detail
- Detailed patient view
- therapy status

3. MAP MONITORING
- TB spread visualization
- Geographic spread visualization

4. ALERT SYSTEM
- missed medication
- Missed medication alerts
- high-risk patients
- Add patient contact to contact patient if they forgot their medicine (contact via number wa)

==================================================
🗺️ MAP SYSTEM (IMPORTANT)
==================================================

- Use OpenStreetMap
- Display markers from patient data
- Plot patient coordinates
- Cluster markers if needed
- Use clustering for performance
- Optimize performance

==================================================
🔔 NOTIFICATION SYSTEM
==================================================

- Local notifications
- Medication reminders
- Alert doctor for missed medication

==================================================
🤖 AI CHATBOT (CRITICAL)
==================================================

Integrate OpenAI API

SYSTEM PROMPT:

"You are a tuberculosis (TBC) health assistant.
Explain in simple language.
Use WHO-based medical guidance.
Be calm, clear, and helpful.
Do not give dangerous advice."

Features:
- context memory
- chat history saved in database

==================================================
🔄 REALTIME SYSTEM
==================================================

- Supabase Realtime
- Live updates:
  - dashboard
  - patient status
  - alerts
  - Dashboard auto update
  - Patient status changes

==================================================
⚙️ ERROR HANDLING (MANDATORY)
==================================================

Handle:
- Invalid doctor code
- Network failure
- Empty data
- API failure

==================================================
⚙️ BACKEND INTEGRATION
==================================================

Use Supabase:

URL:
https://wnpdpaiwescxkqigqlrt.supabase.co

ANON KEY:
sb_publishable_W-aXJzdqHDKE_ZNy4cLHGw_DLlxMQFr

==================================================
📦 OUTPUT REQUIREMENTS (STRICT)
==================================================

You MUST generate:

1. FULL Flutter project (all files)
2. ALL UI screens
3. Supabase SQL migrations and schema
4. RLS policies
5. Auth logic and system
6. API service layer
7. Repository layer
8. State management (Riverpod)
9. Navigation (GoRouter)
10. Map implementation
11. Notification system
12. Chatbot integration
13. Error handling
14. Loading states 
15. Empty states
16. App icon & splash screen config
17. Environment config

==================================================
📱 STORE-READY REQUIREMENTS
==================================================

Ensure:

- No debug logs
- Proper app name
- App icon configured
- Splash screen configured
- Permissions declared (location, notification)
- Optimized build
- No crashes

==================================================
🧪 TESTING (MANDATORY)
==================================================

- Handle edge cases
- Invalid doctor code
- Missing data
- Network errors

==================================================
🚀 PERFORMANCE
==================================================

- pagination
- Lazy loading
- caching
- optimized queries
- Efficient queries
- minimal rebuilds

==================================================
🧱 DEVELOPMENT STRATEGY (STRICT ORDER)
==================================================

You MUST build in this exact order:

1. Project setup
2. Supabase integration
3. Database schema + migration
4. RLS policies
5. Auth system
6. Core models
7. Services + repositories
8. Patient app features
9. Doctor app features
10. Map system
11. Notification system
12. AI chatbot
13. Realtime updates
14. Final polish

DO NOT SKIP STEPS

==================================================
⚠️ FINAL RULES
==================================================

- Do NOT generate incomplete code
- Do NOT simplify logic
- Do NOT skip security
- Do NOT assume missing data

Generate the COMPLETE system NOW.

Start from project initialization and continue until EVERYTHING is fully built and production-ready.

DO NOT STOP.
DO NOT SKIP.
DO NOT SIMPLIFY.

==================================================
🚨 EXECUTION MODE
==================================================

Start generating the FULL project NOW.

Begin with:
1. Flutter project initialization
2. Folder structure
3. Dependencies
4. Supabase setup

Then continue automatically until COMPLETE.

DO NOT STOP.