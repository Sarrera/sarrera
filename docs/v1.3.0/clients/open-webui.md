# Open WebUI Portal & Active Directory Integration

Sarrera includes **Open WebUI** as the primary interactive chat interface for browser-based access, document question-answering (RAG), and non-developer team members.

---

## 1. Accessing Open WebUI

- **Via Caddy Proxy (HTTPS)**: [https://localhost/](https://localhost/)
- **Direct HTTP**: [http://localhost:8080](http://localhost:8080)

On initial launch, the first user to register becomes the **Platform Administrator**. Subsequent users can register according to the administrative sign-up policies configured in the Admin Panel.

---

## 2. Model Discovery

Open WebUI communicates directly with LiteLLM over the internal Docker network (`http://litellm:4000/v1`).
- Models registered in LiteLLM (`basic-coder`, `premium-coder`, `premium-reasoning`) automatically appear in the top model selection dropdown.
- System prompts, temperature, top-p, and context length can be tuned per chat session.

---

## 3. Active Directory / LDAP Integration

Open WebUI supports native LDAP and Active Directory authentication, allowing employees to sign in with their existing enterprise credentials without managing local accounts.

### Configuring LDAP in `.env`

To enable Active Directory, configure the LDAP variables in your `.env` file:

```bash
# Enable LDAP authentication
ENABLE_LDAP=true

# Hostname or IP of your Active Directory Domain Controller
LDAP_SERVER_HOST=ldap://dc.company.local
LDAP_SERVER_PORT=389

# Base DN where user accounts reside
LDAP_BASE_DN=DC=company,DC=local
LDAP_USER_DN=CN=Users,DC=company,DC=local

# Attribute used for username matching in Active Directory
LDAP_SEARCH_FILTER=(sAMAccountName={username})
```

After modifying `.env`, restart the Open WebUI container:
```bash
docker compose up -d open-webui
```

### Role Mapping
Inside the Open WebUI Admin Panel (**Admin Panel** -> **Settings** -> **Users**):
- You can designate default roles (`User` or `Admin`) assigned to newly authenticated LDAP accounts.
- You can restrict chat access to specific security groups within Active Directory.
