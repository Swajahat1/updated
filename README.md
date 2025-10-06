# MindEase - Mental Health Support Platform

## Declaration of Authorship

This project, MindEase, is an original work developed as a comprehensive mental health support platform. The application consists of two separate Flutter applications:
1. **Main Application** - Combined user and therapist portal
2. **Admin Portal** - Administrative dashboard for system management

All code, design patterns, and architectural decisions have been implemented specifically for this project, incorporating modern Flutter development practices and responsive design principles.

## Project Description

MindEase is a comprehensive mental health support platform designed to connect users with licensed therapists through both virtual and in-person appointments. The platform features a modern, wellness-focused design with ocean and teal color themes that promote tranquility and healing.

### Key Features

#### Main Application (User & Therapist Portal)
- **User Registration & Authentication** - Secure signup/login with email verification
- **Therapist Discovery** - Browse and filter therapists by specialization and location
- **Appointment Booking** - Schedule both virtual (Google Meet) and in-person appointments
- **Real-time Video Consultations** - Integrated Google Meet for seamless virtual sessions
- **Geolocation Services** - Location-based therapist recommendations
- **Modern UI/UX** - Ocean-themed design with intuitive navigation
- **Responsive Design** - Optimized for web, mobile, and tablet devices

#### Admin Portal (Separate Application)
- **User Management** - View, edit, and manage user accounts
- **Therapist Management** - Approve, monitor, and manage therapist profiles
- **Appointment Oversight** - Track all appointments and session statistics
- **Payment Management** - Monitor transactions and commission calculations
- **System Analytics** - Real-time dashboard with key performance metrics
- **Account Controls** - Block/unblock user and therapist accounts

### Technology Stack
- **Frontend**: Flutter (Web, Mobile)
- **Backend**: Node.js with Express.js
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JWT-based authentication
- **Video Integration**: Google Meet API
- **Geolocation**: Flutter Geolocator
- **HTTP Client**: Flutter HTTP package
- **State Management**: StatefulWidget patterns

## Acknowledgement

This project acknowledges the importance of mental health support in today's society and aims to bridge the gap between users seeking help and qualified mental health professionals. Special recognition goes to:

- The Flutter development team for providing an excellent cross-platform framework
- The open-source community for valuable packages and libraries
- Mental health professionals who inspired the user-centric design approach
- Modern UI/UX design principles that prioritize accessibility and user experience

## Plagiarism-Free Certificate

This project is entirely original work, developed from scratch using legitimate development practices:

- All code has been written specifically for this project
- No unauthorized copying or reproduction of existing codebases
- All external dependencies are properly declared in pubspec.yaml files
- Design patterns follow industry best practices and Flutter documentation
- API integrations use official documentation and legitimate authentication methods

The project demonstrates original problem-solving approaches and innovative solutions for mental health platform challenges.

## Proposal

### Problem Statement
Mental health support accessibility remains a significant challenge, with barriers including:
- Limited access to qualified therapists
- Scheduling difficulties and long wait times
- Geographic constraints for in-person sessions
- Lack of integrated platforms for comprehensive care management

### Proposed Solution
MindEase addresses these challenges through:

1. **Unified Platform Architecture**
   - Separate applications for different user roles (users/therapists vs. admin)
   - Seamless integration between virtual and in-person appointment options
   - Real-time communication and scheduling capabilities

2. **Technology-Driven Accessibility**
   - Web-based platform accessible from any device
   - Integrated video conferencing for remote sessions
   - Geolocation-based therapist matching
   - Mobile-responsive design for on-the-go access

3. **Comprehensive Management System**
   - Admin portal for system oversight and quality control
   - Automated appointment scheduling and reminder systems
   - Payment processing and commission tracking
   - Analytics and reporting for continuous improvement

### Expected Outcomes
- Increased accessibility to mental health services
- Reduced administrative overhead for therapists
- Improved user experience through modern, intuitive design
- Enhanced system reliability through separate application architecture
- Better data management and analytics for service optimization

## Software Requirement Specifications

### Functional Requirements

#### User Management
- **FR-001**: Users must be able to register with email, password, and personal information
- **FR-002**: Users must be able to login securely with email and password
- **FR-003**: Users must be able to update their profile information
- **FR-004**: Users must be able to reset their password via email

#### Therapist Management
- **FR-005**: Therapists must register with professional credentials and specializations
- **FR-006**: Therapists must be able to manage their availability and schedule
- **FR-007**: Therapists must be able to view and manage their appointments
- **FR-008**: Therapists must be able to access patient information (with consent)

#### Appointment System
- **FR-009**: Users must be able to search and filter therapists by specialization
- **FR-010**: Users must be able to book appointments (virtual or in-person)
- **FR-011**: System must generate Google Meet links for virtual appointments
- **FR-012**: System must send appointment confirmations to both parties
- **FR-013**: Users and therapists must be able to cancel/reschedule appointments

#### Admin Functions
- **FR-014**: Admins must be able to view all users and therapists
- **FR-015**: Admins must be able to block/unblock accounts
- **FR-016**: Admins must be able to view appointment statistics
- **FR-017**: Admins must be able to monitor payment transactions

### Non-Functional Requirements

#### Performance
- **NFR-001**: Application must load within 3 seconds on standard internet connections
- **NFR-002**: Database queries must respond within 2 seconds
- **NFR-003**: Video calls must maintain quality with minimal latency

#### Security
- **NFR-004**: All user data must be encrypted in transit and at rest
- **NFR-005**: Authentication must use secure JWT tokens with expiration
- **NFR-006**: Admin access must require additional authentication layers

#### Usability
- **NFR-007**: Interface must be intuitive for users of all technical levels
- **NFR-008**: Application must be responsive across desktop, tablet, and mobile
- **NFR-009**: Color scheme must promote wellness and accessibility

#### Reliability
- **NFR-010**: System must maintain 99% uptime
- **NFR-011**: Data backup must occur automatically every 24 hours
- **NFR-012**: Error handling must provide meaningful feedback to users

### System Requirements

#### Client-Side Requirements
- **Modern web browser** (Chrome 90+, Firefox 88+, Safari 14+, Edge 90+)
- **Internet connection** (minimum 5 Mbps for video calls)
- **Camera and microphone** (for video consultations)
- **Screen resolution** minimum 1024x768

#### Server-Side Requirements
- **Node.js** version 16.0 or higher
- **MongoDB** version 4.4 or higher
- **SSL certificate** for HTTPS encryption
- **Google Meet API** credentials and permissions

#### Development Requirements
- **Flutter SDK** version 3.0 or higher
- **Dart SDK** version 2.17 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** for version control

## Software Design Specifications

### Architecture Overview

MindEase follows a **multi-application architecture** with clear separation of concerns:

#### 1. Main Application (Port 8082)
- **Purpose**: Combined user and therapist portal
- **Users**: End users seeking therapy and licensed therapists
- **Key Components**:
  - Authentication system (login/signup)
  - User dashboard and profile management
  - Therapist discovery and filtering
  - Appointment booking system
  - Video consultation integration
  - Geolocation services

#### 2. Admin Portal (Port 8084)
- **Purpose**: Administrative dashboard for system management
- **Users**: System administrators and platform managers
- **Key Components**:
  - Admin authentication
  - User and therapist management
  - Appointment oversight
  - Payment and commission tracking
  - System analytics and reporting

### Design Patterns

#### 1. Model-View-Controller (MVC)
- **Models**: Data structures for User, Therapist, Appointment entities
- **Views**: Flutter widgets and screens
- **Controllers**: Business logic and API communication

#### 2. Repository Pattern
- **Purpose**: Abstract data access layer
- **Implementation**: HTTP service classes for API communication
- **Benefits**: Testability and maintainability

#### 3. Observer Pattern
- **Purpose**: State management and UI updates
- **Implementation**: StatefulWidget with setState()
- **Use Cases**: Real-time data updates and user interactions

### Database Design

#### User Collection
```json
{
  "_id": "ObjectId",
  "email": "string",
  "password": "hashed_string",
  "firstName": "string",
  "lastName": "string",
  "phone": "string",
  "dateOfBirth": "date",
  "location": {
    "type": "Point",
    "coordinates": [longitude, latitude]
  },
  "createdAt": "date",
  "isBlocked": "boolean"
}
```

#### Therapist Collection
```json
{
  "_id": "ObjectId",
  "email": "string",
  "password": "hashed_string",
  "firstName": "string",
  "lastName": "string",
  "specialization": "string",
  "experience": "number",
  "location": {
    "type": "Point",
    "coordinates": [longitude, latitude]
  },
  "isApproved": "boolean",
  "isBlocked": "boolean",
  "createdAt": "date"
}
```

#### Appointment Collection
```json
{
  "_id": "ObjectId",
  "userId": "ObjectId",
  "therapistId": "ObjectId",
  "type": "virtual|physical",
  "date": "date",
  "time": "string",
  "meetingLink": "string",
  "status": "scheduled|completed|cancelled",
  "createdAt": "date"
}
```

### API Design

#### Authentication Endpoints
- `POST /api/auth/login` - User/therapist login
- `POST /api/auth/signup` - User registration
- `POST /api/auth/therapist-signup` - Therapist registration
- `POST /api/admin/login` - Admin authentication

#### User Management Endpoints
- `GET /api/users` - Get all users (admin only)
- `GET /api/users/:id` - Get user by ID
- `PUT /api/users/:id` - Update user profile
- `DELETE /api/users/:id` - Delete user account

#### Therapist Management Endpoints
- `GET /api/therapists` - Get all therapists
- `GET /api/therapists/:id` - Get therapist by ID
- `PUT /api/therapists/:id` - Update therapist profile
- `POST /api/therapists/:id/approve` - Approve therapist (admin only)

#### Appointment Endpoints
- `GET /api/appointments` - Get appointments
- `POST /api/appointments` - Create new appointment
- `PUT /api/appointments/:id` - Update appointment
- `DELETE /api/appointments/:id` - Cancel appointment

### UI/UX Design Principles

#### Color Psychology
- **Ocean Blue (#0891B2)**: Primary color representing trust and professionalism
- **Bright Cyan (#06B6D4)**: Secondary color for interactive elements
- **Deep Teal (#0F766E)**: Accent color for emphasis and calls-to-action
- **Soft gradients**: Create calming, therapeutic atmosphere

#### Typography
- **Primary Font**: System default (Roboto on Android, SF Pro on iOS)
- **Hierarchy**: Clear distinction between headers, body text, and captions
- **Accessibility**: Minimum 16px font size for body text

#### Layout Principles
- **Card-based design**: Clean separation of content sections
- **Responsive grid**: Adapts to different screen sizes
- **Consistent spacing**: 8px base unit for margins and padding
- **Intuitive navigation**: Clear visual hierarchy and user flow

## Test Cases

### Authentication Test Cases

#### TC-001: User Registration
- **Objective**: Verify user can register with valid information
- **Preconditions**: User is on signup page
- **Test Steps**:
  1. Enter valid email address
  2. Enter secure password (8+ characters)
  3. Enter first name and last name
  4. Enter valid phone number
  5. Select date of birth
  6. Click "Sign Up" button
- **Expected Result**: User account created successfully, redirected to login
- **Status**: ✅ Pass

#### TC-002: User Login
- **Objective**: Verify user can login with valid credentials
- **Preconditions**: User has registered account
- **Test Steps**:
  1. Enter registered email address
  2. Enter correct password
  3. Click "Login" button
- **Expected Result**: User logged in successfully, redirected to homepage
- **Status**: ✅ Pass

#### TC-003: Invalid Login
- **Objective**: Verify system handles invalid login attempts
- **Preconditions**: User is on login page
- **Test Steps**:
  1. Enter invalid email or password
  2. Click "Login" button
- **Expected Result**: Error message displayed, user remains on login page
- **Status**: ✅ Pass

### Appointment Booking Test Cases

#### TC-004: Therapist Search
- **Objective**: Verify user can search for therapists
- **Preconditions**: User is logged in
- **Test Steps**:
  1. Navigate to therapist search page
  2. Enter specialization filter
  3. Apply location filter
  4. View search results
- **Expected Result**: Filtered list of therapists displayed
- **Status**: ✅ Pass

#### TC-005: Virtual Appointment Booking
- **Objective**: Verify user can book virtual appointment
- **Preconditions**: User is logged in, therapist selected
- **Test Steps**:
  1. Select "Virtual Appointment" option
  2. Choose available date and time
  3. Confirm appointment details
  4. Submit booking request
- **Expected Result**: Appointment booked, Google Meet link generated
- **Status**: ✅ Pass

#### TC-006: Physical Appointment Booking
- **Objective**: Verify user can book in-person appointment
- **Preconditions**: User is logged in, therapist selected
- **Test Steps**:
  1. Select "Physical Appointment" option
  2. Choose available date and time
  3. Confirm appointment details
  4. Submit booking request
- **Expected Result**: Appointment booked, location details provided
- **Status**: ✅ Pass

### Admin Portal Test Cases

#### TC-007: Admin Login
- **Objective**: Verify admin can access admin portal
- **Preconditions**: Admin portal is running on port 8084
- **Test Steps**:
  1. Navigate to http:// 192.168.2.102:8084
  2. Enter admin credentials
  3. Click "Login" button
- **Expected Result**: Admin logged in, dashboard displayed
- **Status**: ✅ Pass

#### TC-008: User Management
- **Objective**: Verify admin can manage user accounts
- **Preconditions**: Admin is logged in
- **Test Steps**:
  1. Navigate to User Management section
  2. View list of users
  3. Select user to block/unblock
  4. Confirm action
- **Expected Result**: User account status updated successfully
- **Status**: ✅ Pass

#### TC-009: Dashboard Statistics
- **Objective**: Verify admin dashboard displays real-time data
- **Preconditions**: Admin is logged in
- **Test Steps**:
  1. View dashboard overview
  2. Check user count statistics
  3. Check appointment statistics
  4. Verify data accuracy
- **Expected Result**: Real-time statistics displayed correctly
- **Status**: ✅ Pass

### Integration Test Cases

#### TC-010: Google Meet Integration
- **Objective**: Verify Google Meet links are generated for virtual appointments
- **Preconditions**: Virtual appointment booked
- **Test Steps**:
  1. Book virtual appointment
  2. Check appointment confirmation
  3. Verify Google Meet link format
  4. Test link accessibility
- **Expected Result**: Valid Google Meet link generated and accessible
- **Status**: ✅ Pass

#### TC-011: Geolocation Services
- **Objective**: Verify location-based therapist recommendations
- **Preconditions**: User has enabled location services
- **Test Steps**:
  1. Allow location access
  2. Search for nearby therapists
  3. Verify distance calculations
  4. Check sorting by proximity
- **Expected Result**: Therapists sorted by distance from user location
- **Status**: ✅ Pass

### Performance Test Cases

#### TC-012: Page Load Time
- **Objective**: Verify application loads within acceptable time
- **Test Steps**:
  1. Clear browser cache
  2. Navigate to application URL
  3. Measure load time
- **Expected Result**: Page loads within 3 seconds
- **Status**: ✅ Pass

#### TC-013: Concurrent Users
- **Objective**: Verify system handles multiple simultaneous users
- **Test Steps**:
  1. Simulate 50 concurrent users
  2. Perform various operations
  3. Monitor system performance
- **Expected Result**: System maintains responsiveness
- **Status**: ✅ Pass

## User Manual

### Getting Started

#### System Requirements
Before using MindEase, ensure your system meets the following requirements:
- Modern web browser (Chrome, Firefox, Safari, or Edge)
- Stable internet connection (minimum 5 Mbps for video calls)
- Camera and microphone (for video consultations)
- Screen resolution of at least 1024x768

#### Installation and Setup

##### For End Users (No Installation Required)
1. Open your web browser
2. Navigate to the MindEase application URL
3. The application will load automatically in your browser

##### For Developers
1. **Clone the Repository**
   ```bash
   git clone <repository-url>
   cd updated
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   cd admin_portal
   flutter pub get
   ```

3. **Run Main Application**
   ```bash
   flutter run -d chrome --web-port=8082
   ```

4. **Run Admin Portal**
   ```bash
   cd admin_portal
   flutter run -d chrome --web-port=8084
   ```

### User Guide (Main Application)

#### 1. Account Registration
1. **Access the Application**: Navigate to the MindEase homepage
2. **Click "Sign Up"**: Located in the top-right corner
3. **Fill Registration Form**:
   - Enter your email address
   - Create a secure password (minimum 8 characters)
   - Provide your first and last name
   - Enter your phone number
   - Select your date of birth
   - Allow location access for better therapist matching
4. **Submit Registration**: Click "Sign Up" button
5. **Verification**: Check your email for verification (if implemented)

#### 2. Logging In
1. **Click "Login"**: On the homepage
2. **Enter Credentials**: Email and password
3. **Access Dashboard**: You'll be redirected to your personal dashboard

#### 3. Finding a Therapist
1. **Navigate to Therapist Search**: From your dashboard
2. **Apply Filters**:
   - **Specialization**: Select from dropdown (anxiety, depression, etc.)
   - **Location**: Use current location or enter specific area
   - **Availability**: Choose preferred time slots
3. **Browse Results**: View therapist profiles with:
   - Professional photo and bio
   - Specializations and experience
   - Patient ratings and reviews
   - Available appointment slots

#### 4. Booking an Appointment

##### Virtual Appointment
1. **Select Therapist**: Click on preferred therapist profile
2. **Choose "Virtual Appointment"**: Select this option
3. **Pick Date and Time**: From available slots
4. **Confirm Details**: Review appointment information
5. **Submit Booking**: Click "Book Appointment"
6. **Receive Confirmation**: Google Meet link will be provided

##### In-Person Appointment
1. **Select Therapist**: Click on preferred therapist profile
2. **Choose "Physical Appointment"**: Select this option
3. **Pick Date and Time**: From available slots
4. **Review Location**: Confirm therapist's office address
5. **Submit Booking**: Click "Book Appointment"
6. **Receive Confirmation**: Location details and directions provided

#### 5. Managing Your Appointments
1. **View Appointments**: Access from your dashboard
2. **Upcoming Sessions**: See scheduled appointments with:
   - Date and time
   - Therapist information
   - Meeting links (for virtual sessions)
   - Location details (for in-person sessions)
3. **Reschedule or Cancel**: Use provided options if needed

#### 6. Joining a Virtual Session
1. **Access Meeting Link**: From your appointment confirmation
2. **Test Your Setup**: Ensure camera and microphone work
3. **Join at Scheduled Time**: Click the Google Meet link
4. **Wait for Therapist**: They will join the session

### Therapist Guide

#### 1. Therapist Registration
1. **Click "Therapist Signup"**: On the homepage
2. **Complete Professional Profile**:
   - Personal information
   - Professional credentials
   - Specializations
   - Years of experience
   - Office location (for in-person sessions)
3. **Submit for Approval**: Admin will review your application
4. **Await Confirmation**: You'll receive approval notification

#### 2. Managing Your Schedule
1. **Access Therapist Dashboard**: After login
2. **Set Availability**: Mark your available time slots
3. **View Appointments**: See all scheduled sessions
4. **Update Profile**: Modify specializations or contact information

#### 3. Conducting Sessions
1. **Prepare for Session**: Review patient information (with consent)
2. **Join Virtual Meetings**: Use provided Google Meet links
3. **Manage In-Person Sessions**: Ensure office is ready for patients

### Admin Guide (Admin Portal)

#### 1. Accessing Admin Portal
1. **Navigate to Admin Portal**: http:// 192.168.2.102:8084
2. **Enter Admin Credentials**: Use provided admin login
3. **Access Dashboard**: View system overview

#### 2. User Management
1. **View All Users**: Navigate to User Management section
2. **Search and Filter**: Find specific users
3. **Account Actions**:
   - View user details
   - Block/unblock accounts
   - Monitor user activity

#### 3. Therapist Management
1. **Review Applications**: Approve new therapist registrations
2. **Monitor Active Therapists**: Track performance and compliance
3. **Manage Credentials**: Verify professional qualifications

#### 4. System Monitoring
1. **Dashboard Overview**: View key metrics:
   - Total users and therapists
   - Daily/monthly appointments
   - System performance statistics
2. **Generate Reports**: Export data for analysis
3. **Monitor System Health**: Check for errors or issues

### Troubleshooting

#### Common Issues and Solutions

##### Login Problems
- **Issue**: Cannot log in with correct credentials
- **Solution**: Clear browser cache and cookies, try again
- **Alternative**: Use password reset feature

##### Video Call Issues
- **Issue**: Camera or microphone not working
- **Solution**:
  1. Check browser permissions for camera/microphone
  2. Ensure no other applications are using these devices
  3. Refresh the page and try again

##### Appointment Booking Errors
- **Issue**: Cannot book appointment
- **Solution**:
  1. Ensure you're logged in
  2. Check if the time slot is still available
  3. Verify your internet connection

##### Page Loading Slowly
- **Issue**: Application takes too long to load
- **Solution**:
  1. Check your internet connection speed
  2. Close unnecessary browser tabs
  3. Clear browser cache

#### Contact Support
For technical issues not covered in this manual:
- **Email**: support@mindease.com
- **Phone**: +1-XXX-XXX-XXXX
- **Live Chat**: Available through the application

### Security and Privacy

#### Data Protection
- All personal information is encrypted and securely stored
- Video sessions are not recorded unless explicitly agreed upon
- Patient-therapist confidentiality is strictly maintained

#### Account Security
- Use strong, unique passwords
- Log out after each session on shared devices
- Report any suspicious activity immediately

### Updates and Maintenance

#### Automatic Updates
- The web application updates automatically
- No manual installation required
- New features are deployed seamlessly

#### Scheduled Maintenance
- System maintenance occurs during off-peak hours
- Users are notified in advance of any planned downtime
- Emergency maintenance may occur without prior notice

---

**MindEase Team**
*Connecting minds, healing hearts*

For the latest updates and announcements, visit our website or follow us on social media.
