# JWT Authentication in ASP.NET Core Web API

Implements secure login for a microservice using JWT (JSON Web Tokens), as required for **Question 1**.

## What this covers

1. A new ASP.NET Core Web API project (`.NET 8`)
2. A `User` model and a `POST /api/auth/login` endpoint
3. JWT generation on successful login
4. A protected endpoint secured with `[Authorize]`

## Project structure

```
JwtAuthDemo/
├── Controllers/
│   ├── AuthController.cs      # POST api/auth/login -> issues JWT
│   └── SecureController.cs    # GET api/secure/data -> [Authorize] protected
├── Models/
│   ├── User.cs
│   ├── LoginModel.cs
│   └── TokenResponse.cs
├── Program.cs                 # JWT auth/authorization wiring
├── appsettings.json           # Jwt:Key / Issuer / Audience / DurationInMinutes
└── JwtAuthDemo.csproj
```

## Setup

```bash
dotnet restore
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
dotnet run
```

The API starts on `https://localhost:7080` (Swagger UI opens automatically at `/swagger`).

## appsettings.json

```json
{
  "Jwt": {
    "Key": "ThisIsASecretKeyForJwtToken",
    "Issuer": "MyAuthServer",
    "Audience": "MyApiUsers",
    "DurationInMinutes": 60
  }
}
```

> ⚠️ In a real deployment, move `Jwt:Key` out of source control (use user-secrets,
> environment variables, or a secret manager like Azure Key Vault).

## Try it out

**1. Log in to get a token**

```bash
curl -X POST https://localhost:7080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password123"}'
```

Response:

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresAt": "2026-07-14T15:30:00Z"
}
```

(The demo `IsValidUser` check accepts `admin` / `password123` — swap this for a real
database lookup with hashed passwords in production.)

**2. Call the protected endpoint**

```bash
curl https://localhost:7080/api/secure/data \
  -H "Authorization: Bearer <token-from-step-1>"
```

Without a valid token this returns `401 Unauthorized`.

## Key implementation notes

- `Program.cs` registers `AddAuthentication().AddJwtBearer(...)` with
  `TokenValidationParameters` that validate issuer, audience, lifetime, and
  signing key.
- `UseAuthentication()` is called **before** `UseAuthorization()` in the pipeline —
  order matters.
- `AuthController.GenerateJwtToken` signs tokens with `HmacSha256` using the
  same key configured in `appsettings.json`, and reads `Issuer`/`Audience`/
  `DurationInMinutes` from configuration instead of hardcoding them.
- `[Authorize]` on `SecureController.GetSecureData` rejects any request without
  a valid, unexpired, correctly-signed bearer token.
