# Requirements Document

## Introduction

This document defines the requirements for a mobile-first authentication system for the Lubricentros SaaS application. The system enables users to register, log in, recover passwords, and maintain secure sessions across a Flutter mobile app and Go backend with PostgreSQL database.

The authentication system prioritizes user experience with minimal friction, clear feedback, and consistent interaction patterns while maintaining security best practices.

## Glossary

- **Auth_System**: The complete authentication subsystem including mobile UI, backend API, and database
- **Mobile_App**: The Flutter mobile application client
- **Backend_API**: The Go REST API server
- **User**: A person who owns vehicles and uses the mobile app to manage services
- **Session**: An authenticated period where a user can access protected resources
- **JWT**: JSON Web Token used for stateless authentication
- **Password_Hash**: Bcrypt-hashed password stored in the database
- **Auth_Token**: The JWT token returned after successful authentication
- **Refresh_Token**: A long-lived token used to obtain new auth tokens
- **Registration_Flow**: The process of creating a new user account
- **Login_Flow**: The process of authenticating an existing user
- **Password_Recovery_Flow**: The process of resetting a forgotten password
- **Session_Manager**: Component responsible for maintaining authentication state
- **Input_Validator**: Component that validates user input before submission
- **Error_Handler**: Component that displays error messages to users
- **Loading_State**: Visual indication that an operation is in progress
- **Success_State**: Visual confirmation that an operation completed successfully
- **Error_State**: Visual indication that an operation failed with details
- **Empty_State**: Visual indication when no data is available

## Requirements

### Requirement 1: User Registration

**User Story:** As a new user, I want to create an account with my email and password, so that I can access the lubricentros app and manage my vehicles.

#### Acceptance Criteria

1. THE Mobile_App SHALL display a registration screen with email, password, password confirmation, and name input fields
2. WHEN a user enters text in the email field, THE Input_Validator SHALL validate the email format in real-time
3. WHEN a user enters text in the password field, THE Input_Validator SHALL display password strength indicators
4. WHEN a user enters text in the password confirmation field, THE Input_Validator SHALL verify it matches the password field
5. WHEN all fields are valid and the user taps the register button, THE Mobile_App SHALL display a Loading_State
6. WHEN the register button is tapped with valid data, THE Backend_API SHALL hash the password using bcrypt
7. WHEN the Backend_API receives a registration request with a unique email, THE Backend_API SHALL create a user record in the database
8. WHEN the Backend_API receives a registration request with a duplicate email, THE Backend_API SHALL return a 409 Conflict error
9. WHEN registration succeeds, THE Backend_API SHALL return a 201 Created status with Auth_Token and user data
10. WHEN registration succeeds, THE Mobile_App SHALL store the Auth_Token securely and navigate to the home screen
11. WHEN registration fails, THE Error_Handler SHALL display the error message and maintain form data
12. THE Mobile_App SHALL provide a link to navigate to the login screen for existing users

### Requirement 2: User Login

**User Story:** As a registered user, I want to log in with my email and password, so that I can access my account and vehicle data.

#### Acceptance Criteria

1. THE Mobile_App SHALL display a login screen with email and password input fields
2. WHEN a user enters text in the email field, THE Input_Validator SHALL validate the email format
3. WHEN all fields are filled and the user taps the login button, THE Mobile_App SHALL display a Loading_State
4. WHEN the login button is tapped, THE Backend_API SHALL verify the email exists in the database
5. WHEN the email exists, THE Backend_API SHALL compare the provided password with the stored Password_Hash using bcrypt
6. WHEN credentials are valid, THE Backend_API SHALL generate a JWT token with user ID and expiration
7. WHEN credentials are valid, THE Backend_API SHALL return a 200 OK status with Auth_Token and user data
8. WHEN credentials are invalid, THE Backend_API SHALL return a 401 Unauthorized error
9. WHEN login succeeds, THE Mobile_App SHALL store the Auth_Token securely and navigate to the home screen
10. WHEN login fails, THE Error_Handler SHALL display a generic error message without revealing whether email or password was incorrect
11. THE Mobile_App SHALL provide a link to navigate to the password recovery screen
12. THE Mobile_App SHALL provide a link to navigate to the registration screen for new users

### Requirement 3: Password Recovery

**User Story:** As a user who forgot my password, I want to reset it using my email, so that I can regain access to my account.

#### Acceptance Criteria

1. THE Mobile_App SHALL display a password recovery screen with an email input field
2. WHEN a user enters text in the email field, THE Input_Validator SHALL validate the email format
3. WHEN the user taps the send recovery email button, THE Mobile_App SHALL display a Loading_State
4. WHEN the Backend_API receives a password recovery request, THE Backend_API SHALL verify the email exists in the database
5. WHEN the email exists, THE Backend_API SHALL generate a unique recovery token with 1 hour expiration
6. WHEN the email exists, THE Backend_API SHALL store the recovery token in the database associated with the user
7. WHEN the email exists, THE Backend_API SHALL send a recovery email with a reset link containing the token
8. WHEN the email does not exist, THE Backend_API SHALL return a 200 OK status without revealing the email is not registered
9. WHEN the recovery email is sent, THE Mobile_App SHALL display a Success_State with instructions to check email
10. WHEN a user opens the recovery link, THE Mobile_App SHALL display a password reset screen with the token
11. WHEN the user enters a new password and confirmation, THE Input_Validator SHALL validate password strength and match
12. WHEN the user submits the new password, THE Backend_API SHALL verify the recovery token is valid and not expired
13. WHEN the token is valid, THE Backend_API SHALL hash the new password and update the user record
14. WHEN the token is valid, THE Backend_API SHALL invalidate the recovery token
15. WHEN password reset succeeds, THE Mobile_App SHALL display a Success_State and navigate to the login screen
16. WHEN the token is invalid or expired, THE Error_Handler SHALL display an error and offer to resend recovery email

### Requirement 4: Session Management

**User Story:** As a logged-in user, I want my session to persist across app restarts, so that I don't have to log in every time I open the app.

#### Acceptance Criteria

1. WHEN a user successfully authenticates, THE Session_Manager SHALL store the Auth_Token in secure local storage
2. WHEN the Mobile_App starts, THE Session_Manager SHALL check for a stored Auth_Token
3. WHEN a stored Auth_Token exists, THE Session_Manager SHALL verify the token is not expired
4. WHEN the token is valid and not expired, THE Mobile_App SHALL navigate directly to the home screen
5. WHEN the token is expired or invalid, THE Session_Manager SHALL clear the stored token and navigate to the login screen
6. WHEN the Backend_API receives a request with an Auth_Token, THE Backend_API SHALL validate the JWT signature and expiration
7. WHEN the token is invalid, THE Backend_API SHALL return a 401 Unauthorized error
8. WHEN the user logs out, THE Session_Manager SHALL clear the stored Auth_Token
9. WHEN the user logs out, THE Mobile_App SHALL navigate to the login screen
10. THE Auth_Token SHALL expire after 24 hours
11. WHEN a token expires during app use, THE Mobile_App SHALL display a session expired message and navigate to the login screen

### Requirement 5: Protected API Endpoints

**User Story:** As a system administrator, I want API endpoints to be protected by authentication, so that only authorized users can access their data.

#### Acceptance Criteria

1. THE Backend_API SHALL provide an authentication middleware that validates Auth_Token on protected endpoints
2. WHEN a request to a protected endpoint includes a valid Auth_Token, THE Backend_API SHALL extract the user ID from the token
3. WHEN a request to a protected endpoint includes a valid Auth_Token, THE Backend_API SHALL allow the request to proceed
4. WHEN a request to a protected endpoint lacks an Auth_Token, THE Backend_API SHALL return a 401 Unauthorized error
5. WHEN a request to a protected endpoint includes an invalid Auth_Token, THE Backend_API SHALL return a 401 Unauthorized error
6. WHEN a request to a protected endpoint includes an expired Auth_Token, THE Backend_API SHALL return a 401 Unauthorized error with an expiration message
7. THE Backend_API SHALL include the authenticated user ID in the request context for use by endpoint handlers

### Requirement 6: Input Validation and Security

**User Story:** As a system administrator, I want user inputs to be validated and sanitized, so that the system is protected from malicious data and users receive clear feedback.

#### Acceptance Criteria

1. THE Input_Validator SHALL require email addresses to match RFC 5322 format
2. THE Input_Validator SHALL require passwords to be at least 8 characters long
3. THE Input_Validator SHALL require passwords to contain at least one uppercase letter, one lowercase letter, and one number
4. THE Input_Validator SHALL require name fields to be at least 2 characters long
5. THE Backend_API SHALL validate all input data before processing
6. WHEN validation fails, THE Backend_API SHALL return a 400 Bad Request error with specific field errors
7. THE Backend_API SHALL sanitize all text inputs to prevent SQL injection
8. THE Backend_API SHALL rate limit authentication endpoints to 5 requests per minute per IP address
9. WHEN rate limit is exceeded, THE Backend_API SHALL return a 429 Too Many Requests error
10. THE Backend_API SHALL log all failed authentication attempts with timestamp and IP address

### Requirement 7: User Experience States

**User Story:** As a user, I want clear visual feedback for all authentication actions, so that I understand what is happening and can respond appropriately.

#### Acceptance Criteria

1. WHEN an authentication operation is in progress, THE Mobile_App SHALL display a Loading_State with a spinner and disable input fields
2. WHEN an authentication operation succeeds, THE Mobile_App SHALL display a Success_State for 1 second before navigation
3. WHEN an authentication operation fails, THE Error_Handler SHALL display an Error_State with the error message below the relevant field
4. WHEN network connectivity is unavailable, THE Error_Handler SHALL display a specific offline error message
5. WHEN the Backend_API is unreachable, THE Error_Handler SHALL display a service unavailable message
6. THE Mobile_App SHALL display field-level validation errors in real-time as users type
7. THE Mobile_App SHALL disable submit buttons when form validation fails
8. THE Mobile_App SHALL enable submit buttons when all form fields are valid
9. WHEN a user taps outside an input field, THE Input_Validator SHALL display validation errors for that field
10. THE Mobile_App SHALL maintain consistent error message styling across all authentication screens

### Requirement 8: Navigation and Flow Consistency

**User Story:** As a user, I want intuitive navigation between authentication screens, so that I can easily switch between login, registration, and password recovery.

#### Acceptance Criteria

1. THE Mobile_App SHALL provide a back button on registration and password recovery screens that returns to login
2. WHEN a user is not authenticated, THE Mobile_App SHALL prevent access to protected screens
3. WHEN a user attempts to access a protected screen without authentication, THE Mobile_App SHALL navigate to the login screen
4. THE Mobile_App SHALL preserve navigation history to allow back navigation within authentication flows
5. WHEN a user successfully authenticates, THE Mobile_App SHALL clear the authentication navigation stack
6. THE Mobile_App SHALL display consistent header styling across all authentication screens
7. THE Mobile_App SHALL use consistent button styling and placement across all authentication screens
8. THE Mobile_App SHALL use consistent input field styling across all authentication screens

### Requirement 9: Offline Capability

**User Story:** As a user with intermittent connectivity, I want to understand when authentication requires network access, so that I can plan accordingly.

#### Acceptance Criteria

1. WHEN the Mobile_App detects no network connectivity, THE Mobile_App SHALL display an offline indicator
2. WHEN a user attempts authentication without network connectivity, THE Error_Handler SHALL display an offline error message
3. WHEN network connectivity is restored, THE Mobile_App SHALL remove the offline indicator
4. THE Session_Manager SHALL allow access to the app with a valid stored Auth_Token even when offline
5. WHEN offline with a valid token, THE Mobile_App SHALL display a banner indicating limited functionality

### Requirement 10: Database Schema

**User Story:** As a system administrator, I want the database schema to support authentication requirements, so that user data is stored securely and efficiently.

#### Acceptance Criteria

1. THE Backend_API SHALL use the existing users table with id, email, password_hash, name, phone, created_at, and updated_at columns
2. THE Backend_API SHALL create a password_reset_tokens table with user_id, token, expires_at, and created_at columns
3. THE Backend_API SHALL create a unique index on the email column in the users table
4. THE Backend_API SHALL create an index on the token column in the password_reset_tokens table
5. WHEN a password reset token is used, THE Backend_API SHALL delete the token from the password_reset_tokens table
6. THE Backend_API SHALL automatically delete expired tokens from the password_reset_tokens table daily
