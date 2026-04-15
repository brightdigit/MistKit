# User Operations

User operations provide access to CloudKit user information, identity discovery, and contact lookup.

## current-user

Get information about the currently authenticated user.

### Syntax
```bash
mistdemo current-user [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--fields` | Specific user fields to retrieve |

### Authentication Requirements

- **Public Database**: Returns user record name only (anonymous identifier)
- **Private/Shared Database**: Requires web auth token, returns full user information

### User Information Fields

Available fields (when authenticated):
- `userRecordName` - Unique user identifier
- `firstName` - User's first name
- `lastName` - User's last name
- `emailAddress` - User's email (if shared)
- `contactsPermission` - Contacts access permission status

### Examples

**Get current user info:**
```bash
mistdemo current-user
```

**Get specific fields:**
```bash
mistdemo current-user --fields "userRecordName,firstName,lastName"
```

**With authentication:**
```bash
# Get web auth token first
export CLOUDKIT_WEBAUTH_TOKEN=$(mistdemo auth-token -a YOUR_API_TOKEN)

# Query current user
mistdemo current-user --database private
```

### Response Format (JSON)

```json
{
  "userRecordName": "_abc123def456",
  "firstName": "John",
  "lastName": "Doe",
  "emailAddress": "john@example.com",
  "contactsPermission": "granted"
}
```

### Common Use Cases

**Verify authentication:**
```bash
# Check if credentials are valid
if mistdemo current-user > /dev/null 2>&1; then
  echo "Authenticated successfully"
else
  echo "Authentication failed"
fi
```

**Get user identifier:**
```bash
USER_ID=$(mistdemo current-user --fields userRecordName -o json | jq -r '.userRecordName')
echo "Current user: $USER_ID"
```

## discover

Discover user identities by email, phone number, or user record name.

### Syntax
```bash
mistdemo discover <lookup-type> <values...> [options]
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `lookup-type` | Yes | Type of lookup: `email`, `phone`, or `record` |
| `values` | Yes | One or more values to lookup |

### Lookup Types

| Type | Description | Example |
|------|-------------|---------|
| `email` | Lookup by email addresses | `user@example.com` |
| `phone` | Lookup by phone numbers | `"+1234567890"` |
| `record` | Lookup by user record names | `"_abc123def456"` |

### Authentication Requirements

- Requires web authentication token
- User must have granted contacts permission
- Only works with private or shared databases

### Privacy Considerations

- Users must explicitly grant permission to discover their identity
- Only returns information for users who have enabled discoverability
- Email and phone lookups respect user privacy settings

### Examples

**Discover by email:**
```bash
mistdemo discover email user@example.com
```

**Discover multiple emails:**
```bash
mistdemo discover email user1@example.com user2@example.com
```

**Discover by phone:**
```bash
mistdemo discover phone "+1234567890"
```

**Discover by user record names:**
```bash
mistdemo discover record _abc123def456 _xyz789ghi012
```

**Discover from file:**
```bash
# emails.txt contains one email per line
cat emails.txt | xargs mistdemo discover email
```

### Response Format (JSON)

```json
{
  "users": [
    {
      "emailAddress": "user@example.com",
      "userRecordName": "_abc123def456",
      "firstName": "Jane",
      "lastName": "Smith"
    },
    {
      "emailAddress": "user2@example.com",
      "userRecordName": "_xyz789ghi012",
      "firstName": "Bob",
      "lastName": "Jones"
    }
  ]
}
```

### Error Responses

**No permission:**
```json
{
  "error": {
    "code": "NOT_AUTHORIZED",
    "message": "User has not granted contacts permission"
  }
}
```

**User not found:**
```json
{
  "users": [
    {
      "emailAddress": "notfound@example.com",
      "error": {
        "code": "NOT_FOUND",
        "message": "User not discoverable or does not exist"
      }
    }
  ]
}
```

## lookup-contacts

Lookup user contacts (requires contacts permission).

### Syntax
```bash
mistdemo lookup-contacts [options]
```

### Options

| Option | Description |
|--------|-------------|
| `--email` | Email addresses to lookup (repeatable) |
| `--phone` | Phone numbers to lookup (repeatable) |

### Authentication Requirements

- Requires web authentication token
- User must have granted contacts permission
- Only works with private database

### Permission Flow

1. User launches app/command
2. App requests contacts permission
3. User grants/denies permission
4. If granted, app can lookup contacts

### Examples

**Lookup contacts by email:**
```bash
mistdemo lookup-contacts --email user@example.com
```

**Lookup multiple contacts:**
```bash
mistdemo lookup-contacts \
  --email user1@example.com \
  --email user2@example.com \
  --phone "+1234567890"
```

**Lookup from configuration file:**
```bash
# config.json
{
  "contacts": {
    "emails": ["user1@example.com", "user2@example.com"],
    "phones": ["+1234567890"]
  }
}

# Script to process config
EMAILS=$(jq -r '.contacts.emails[]' config.json)
PHONES=$(jq -r '.contacts.phones[]' config.json)

mistdemo lookup-contacts \
  $(echo "$EMAILS" | xargs -I {} echo "--email {}") \
  $(echo "$PHONES" | xargs -I {} echo "--phone {}")
```

### Response Format (JSON)

```json
{
  "contacts": [
    {
      "emailAddress": "user1@example.com",
      "userRecordName": "_abc123",
      "firstName": "Alice",
      "lastName": "Johnson",
      "isContact": true
    },
    {
      "phoneNumber": "+1234567890",
      "userRecordName": "_def456",
      "firstName": "Bob",
      "lastName": "Smith",
      "isContact": true
    }
  ]
}
```

### Differences from discover

| Feature | `lookup-contacts` | `discover` |
|---------|------------------|------------|
| Permission | Requires contacts permission | Optional discoverability |
| Scope | User's contacts only | Any discoverable user |
| Database | Private only | Private or shared |
| Input | Emails and phones | Emails, phones, or record names |

## Common Workflows

### Verify Authentication and Get User Info
```bash
# Set up authentication
export CLOUDKIT_WEBAUTH_TOKEN=$(mistdemo auth-token -a YOUR_API_TOKEN)

# Get current user
mistdemo current-user --database private -o table
```

### Discover Users for Sharing
```bash
# Discover users by email
mistdemo discover email \
  alice@example.com \
  bob@example.com \
  -o json > discoverable_users.json

# Extract user record names for sharing
jq -r '.users[].userRecordName' discoverable_users.json > share_with.txt
```

### Check Contacts Permission
```bash
# Try to lookup contacts
if mistdemo lookup-contacts --email test@example.com 2>&1 | grep -q "NOT_AUTHORIZED"; then
  echo "Contacts permission not granted"
  echo "Please grant contacts permission in your iCloud settings"
else
  echo "Contacts permission granted"
fi
```

### Batch User Discovery
```bash
# Create email list
cat > emails.txt <<EOF
user1@example.com
user2@example.com
user3@example.com
EOF

# Discover all users
while read email; do
  mistdemo discover email "$email" -o json
done < emails.txt | jq -s 'add'
```

## Privacy and Security

### User Privacy
- Discovery requires user opt-in
- Users control their discoverability settings
- Contact lookup limited to actual contacts

### Data Handling
- Never log or store user emails/phones in plain text
- Respect user privacy preferences
- Follow platform privacy guidelines

### Best Practices
1. Request minimal user information needed
2. Explain why you need contacts access
3. Handle permission denial gracefully
4. Cache user record names, not personal info
5. Respect user privacy settings

## Related Documentation

- **[Overview](overview.md)** - Global options and authentication
- **[Authentication Operations](operations-auth.md)** - Web auth token workflow
- **[Error Handling](error-handling.md)** - Error codes and recovery
- **[Configuration](configuration.md)** - Managing credentials
