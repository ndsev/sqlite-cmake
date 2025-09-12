# CI Setup Instructions

## Setting up GitHub Secrets for NDS Forgejo Access

To enable CI builds with the NDS SQLite DevKit, you need to add a Forgejo API token as a GitHub secret. Follow these steps:

### 1. Generate a Forgejo Personal Access Token

1. Log in to your NDS Forgejo account at https://git.nds-association.org
2. Go to your user settings (click your avatar → Settings)
3. Navigate to "Applications" → "Access Tokens" (or similar section)
4. Click "Generate New Token"
5. Give it a descriptive name like "GitHub CI Access"
6. Select the required scopes:
   - `read:repository` - to clone/fetch repositories
   - Optionally: `read:user` - if user info is needed
7. Set an expiration date (or leave blank for no expiration)
8. Click "Generate Token"
9. **IMPORTANT**: Copy the token immediately - you won't be able to see it again!

### 2. Add the Token to GitHub Repository Secrets

1. Go to your GitHub repository page
2. Click on "Settings" tab (you need admin/maintainer permissions)
3. In the left sidebar, expand "Secrets and variables" → click "Actions"
4. Click "New repository secret" button
5. Add the secret:
   - **Name**: `NDS_FORGEJO_TOKEN`
   - **Secret**: Paste the Forgejo token you generated
6. Click "Add secret"

### 3. Alternative: Using GitHub CLI

If you have GitHub CLI installed, you can add the secret from command line:

```bash
gh secret set NDS_FORGEJO_TOKEN --repo your-org/your-repo
```

Then paste the token when prompted.

### 4. For Organization-wide Access

If multiple repositories need access to NDS Forgejo:

1. Go to your GitHub Organization settings
2. Navigate to "Secrets and variables" → "Actions"
3. Click "New organization secret"
4. Add the secret with name `NDS_FORGEJO_TOKEN`
5. Choose which repositories can access this secret

## Security Best Practices

1. **Token Permissions**: Only grant the minimum required permissions (read access)
2. **Token Expiration**: Set a reasonable expiration date and rotate regularly
3. **Secret Names**: Use clear, descriptive names for secrets
4. **Access Control**: Limit secret access to only repositories that need it
5. **Audit**: Regularly review and audit token usage in Forgejo settings

## Troubleshooting

### Authentication Failures

If you see authentication errors in CI:

1. Verify the token hasn't expired
2. Check the token has correct permissions
3. Ensure the secret name matches exactly: `NDS_FORGEJO_TOKEN`
4. Verify the repository URL is correct

### Testing Locally

To test the Git configuration locally:

```bash
# Set the token as environment variable
export NDS_FORGEJO_TOKEN="your-token-here"

# Configure git to use the token
git config --global url."https://oauth2:${NDS_FORGEJO_TOKEN}@git.nds-association.org/".insteadOf "https://git.nds-association.org/"

# Test cloning
git clone https://git.nds-association.org/NDS.Digital/nds-sqlite-devkit.git test-clone
```

## CI Workflow Overview

The CI workflow (`/.github/workflows/ci.yml`) builds both SQLite backends:

1. **Public SQLite**: Downloads amalgamation from sqlite.org
   - No authentication required
   - Tests on Ubuntu, Windows, macOS
   - Both Debug and Release builds

2. **NDS SQLite DevKit**: Uses NDS Forgejo repository
   - Requires `NDS_FORGEJO_TOKEN` secret
   - Tests on Ubuntu, Windows, macOS
   - Both Debug and Release builds
   - Includes compression features

Both configurations test:
- FTS5 (Full-Text Search)
- RTree (Spatial indexing)
- JSON1 (JSON functions)
- Math functions
- Column metadata
