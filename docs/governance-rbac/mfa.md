# Multi-Factor Authentication (TOTP / QR)

> [!NOTE]
> **Available since v1.3.0.**

Sarrera users can enable **time-based one-time passwords (TOTP, RFC 6238)** compatible with Google Authenticator, Microsoft Authenticator, Authy, 1Password, Bitwarden, etc.

---

## Enabling MFA for a user

1. Go to **Users & Keys** in the governance portal.
2. Click the **shield** icon in the **MFA SECURITY** column (tooltip *Setup MFA (Authenticator QR)*).
3. Scan the **QR code** with the authenticator app — or copy the **Base32 key** manually.
4. Enter the current **6-digit code** to verify and activate.

Once verified, the shield icon becomes solid (*MFA Configured*). The same dialog can disable MFA, which also deletes the stored secret.

---

## Technical details

| Parameter | Value |
| :--- | :--- |
| Algorithm | HMAC-SHA1 |
| Digits | 6 |
| Period | 30 s |
| Secret encoding | Base32 |
| URI | `otpauth://totp/Sarrera:<user>?secret=<KEY>&issuer=Sarrera&algorithm=SHA1&digits=6&period=30` |
| Implementation | [`totp_service.dart`](https://github.com/Sarrera/sarrera/blob/main/frontend/lib/core/services/totp_service.dart) |

**Persistence:** stored as `mfa_enabled` and `mfa_secret` in the user's `metadata` via LiteLLM `POST /user/update` (table `LiteLLM_UserTable` in PostgreSQL).

> [!WARNING]
> The TOTP secret lives in the LiteLLM database. Restrict access to PostgreSQL and the LiteLLM master key accordingly, and include the database in your backups so MFA enrolments survive restores.
