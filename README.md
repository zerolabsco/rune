# Rune

Njalla on iOS.

Rune is a native iOS client for managing your Njalla account. It provides fast,
minimal access to domains, DNS, API tokens, and account balance without relying
on the web UI.

---

## Principles

- **Privacy first**  
  Token-based auth. No tracking. No analytics.

- **Minimal surface area**  
  Focus on what you actually need on mobile.

- **Native experience**  
  Built with SwiftUI. Fast, predictable, and simple.

- **No abstraction layers for the sake of it**  
  Direct API usage. Clear data flow.

---

## Features (v1.x)

### Domains
- List domains
- View domain details

### DNS
- View DNS records per domain
- Add, edit, delete records

### API Tokens
- List tokens
- Create tokens with restrictions
- Delete tokens

### Account
- View wallet balance

---

## Authentication

Rune uses **API tokens only**.

- Tokens are stored securely (Keychain)
- No username/password login
- Token is validated on first launch via API

---

## Tech Stack

- SwiftUI
- URLSession (no third-party networking)
- Njalla HTTP API

---

## Scope

Rune is intentionally limited.

Not supported:
- domain registration
- wallet top-ups
- server management
- destructive account actions

---

## Status

Active development.

Early versions focus on:
- correctness
- stability
- clean UX

---

## Why

Njalla has a clean API but no native mobile client. Rune exists to make routine
tasks fast and accessible on iOS.
