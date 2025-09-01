# CI/CD Pipeline

Roadtrip Planner uses GitHub Actions for continuous integration and deployment, ensuring code quality and automated testing.

## Pipeline Overview

The CI/CD pipeline consists of several automated workflows that run on different triggers:

### 1. Continuous Integration (CI)

**Trigger**: Pull requests and pushes to `main` branch  
**File**: `.github/workflows/ci.yml`

```mermaid
graph LR
    A[Code Push/PR] --> B[Security Scan - Ruby]
    A --> C[Security Scan - JS]
    A --> D[Code Linting]
    A --> E[Test Suite]
    
    B --> F[Brakeman Analysis]
    C --> G[Importmap Audit]
    D --> H[RuboCop Check]
    E --> I[RSpec Tests]
    
    F --> J[CI Complete]
    G --> J
    H --> J
    I --> J
```

### 2. Documentation Deployment (CD)

**Trigger**: Manual workflow dispatch  
**File**: `.github/workflows/docs.yml` (created as part of this implementation)

```mermaid
graph LR
    A[Manual Trigger] --> B[Build Docusaurus]
    B --> C[Deploy to GitHub Pages]
    C --> D[Documentation Live]
```

## CI Workflow Details

### Job: `scan_ruby`

**Purpose**: Security vulnerability scanning for Ruby dependencies

```yaml
scan_ruby:
  runs-on: ubuntu-latest
  steps:
    - name: Checkout code
      uses: actions/checkout@v5
    
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: .ruby-version
        bundler-cache: true
    
    - name: Scan for common Rails security vulnerabilities
      run: bin/brakeman --no-pager
```

**What it does**:
- Checks out the latest code
- Sets up Ruby environment with version from `.ruby-version`
- Caches bundle for faster runs
- Runs **Brakeman** static analysis for security vulnerabilities

**Key Benefits**:
- Detects common Rails security issues
- Identifies potential SQL injection, XSS, and other vulnerabilities
- Fails the build if critical security issues are found

### Job: `scan_js`

**Purpose**: Security audit for JavaScript dependencies

```yaml
scan_js:
  runs-on: ubuntu-latest
  steps:
    - name: Checkout code
      uses: actions/checkout@v5
    
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: .ruby-version
        bundler-cache: true
    
    - name: Scan for security vulnerabilities in JavaScript dependencies
      run: bin/importmap audit
```

**What it does**:
- Audits JavaScript dependencies managed by importmaps
- Checks for known security vulnerabilities in npm packages
- Reports vulnerable packages and suggested fixes

**Key Benefits**:
- Protects against vulnerable JavaScript dependencies
- Works with Rails' importmap system
- No separate Node.js setup required

### Job: `lint`

**Purpose**: Code style and quality enforcement

```yaml
lint:
  runs-on: ubuntu-latest
  steps:
    - name: Checkout code
      uses: actions/checkout@v5
    
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: .ruby-version
        bundler-cache: true
    
    - name: Lint code for consistent style
      run: bin/rubocop -f github
```

**What it does**:
- Runs **RuboCop** with Rails Omakase configuration
- Checks code style, syntax, and best practices
- Outputs GitHub-formatted annotations for easy review

**Key Benefits**:
- Maintains consistent code style across the team
- Catches common Ruby/Rails anti-patterns
- Provides inline PR feedback with GitHub annotations

### Job: `test`

**Purpose**: Comprehensive test suite execution

```yaml
test:
  runs-on: ubuntu-latest
  
  services:
    postgres:
      image: postgres
      env:
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: postgres
      ports:
        - 5432:5432
      options: --health-cmd="pg_isready" --health-interval=10s --health-timeout=5s --health-retries=3
```

**Service Configuration**:
- **PostgreSQL**: Database service for integration tests
- **Health checks**: Ensures database is ready before tests run
- **Port mapping**: Connects test environment to database

**Test Execution Steps**:

```yaml
steps:
  - name: Install packages
    run: sudo apt-get update && sudo apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config google-chrome-stable
  
  - name: Checkout code
    uses: actions/checkout@v5
  
  - name: Set up Ruby
    uses: ruby/setup-ruby@v1
    with:
      ruby-version: .ruby-version
      bundler-cache: true
  
  - name: Run tests
    env:
      RAILS_ENV: test
      DATABASE_URL: postgres://postgres:postgres@localhost:5432
    run: bin/rails db:test:prepare test test:system
  
  - name: Keep screenshots from failed system tests
    uses: actions/upload-artifact@v4
    if: failure()
    with:
      name: screenshots
      path: ${{ github.workspace }}/tmp/screenshots
      if-no-files-found: ignore
```

**What it does**:
1. **System Dependencies**: Installs required packages including Chrome for system tests
2. **Environment Setup**: Configures Ruby and bundles dependencies
3. **Database Preparation**: Sets up test database schema
4. **Test Execution**: Runs both unit tests and system tests
5. **Artifact Collection**: Saves screenshots from failed system tests for debugging

**Key Benefits**:
- Full test coverage including system/integration tests
- Real browser testing with Chrome
- Automatic screenshot capture for debugging failed tests
- Database integration testing with PostgreSQL

## Pipeline Configuration Best Practices

### Ruby Version Management

```yaml
# Uses .ruby-version file for consistency
ruby-version: .ruby-version
bundler-cache: true  # Speeds up builds
```

### Environment Variables

```yaml
env:
  RAILS_ENV: test
  DATABASE_URL: postgres://postgres:postgres@localhost:5432
```

### Caching Strategy

- **Bundle cache**: Automatically managed by `ruby/setup-ruby` action
- **Fast builds**: Dependencies cached between runs
- **Cache invalidation**: Automatic when Gemfile.lock changes

### Error Handling

- **Screenshot collection**: Failed system tests automatically save screenshots
- **GitHub annotations**: RuboCop provides inline PR feedback
- **Build artifacts**: Test results and logs available for download

## GitHub Actions Features Used

### Actions and Versions

| Action | Version | Purpose |
|--------|---------|---------|
| `actions/checkout` | v5 | Code checkout |
| `ruby/setup-ruby` | v1 | Ruby environment |
| `actions/upload-artifact` | v4 | Artifact storage |

### Workflow Triggers

```yaml
on:
  pull_request:     # All PR events
  push:
    branches: [main] # Only main branch pushes
```

### Job Dependencies

```yaml
# Jobs run in parallel by default
# No explicit dependencies needed for current setup
```

## Security Considerations

### Secrets Management

- **Database credentials**: Using default PostgreSQL setup for tests
- **No sensitive data**: Test environment uses safe defaults
- **Branch protection**: Main branch requires passing CI

### Permissions

```yaml
# Default permissions are sufficient
# No custom permissions needed for current workflow
```

## Performance Optimization

### Build Speed

- **Parallel jobs**: Security scans and tests run simultaneously
- **Bundle caching**: Ruby dependencies cached between runs
- **Minimal installs**: Only required packages installed

### Resource Usage

- **Standard runners**: `ubuntu-latest` for all jobs
- **Efficient cleanup**: Automatic cleanup after workflow completion
- **Memory usage**: Optimized for GitHub Actions limits

## Monitoring and Alerts

### Build Status

- **PR checks**: Required status checks on pull requests
- **Branch protection**: Main branch requires passing CI
- **Email notifications**: GitHub sends failure notifications

### Metrics

- **Build duration**: Typically 3-5 minutes for full pipeline
- **Success rate**: Track via GitHub Actions dashboard
- **Test coverage**: Reported through RSpec output

## Local Development Integration

### Running CI Locally

```bash
# Run the same checks locally before pushing

# Security scan
docker compose exec web bin/brakeman --no-pager

# JavaScript audit  
docker compose exec web bin/importmap audit

# Code linting
docker compose exec web bin/rubocop

# Test suite
docker compose exec web bin/rails test test:system
```

### Pre-commit Hooks

Consider adding pre-commit hooks to run these checks:

```bash
# .git/hooks/pre-commit
#!/bin/sh
docker compose exec web bin/rubocop --parallel
docker compose exec web bin/rspec --fail-fast
```

## Deployment Pipeline (Future)

### Staging Deployment

**Planned workflow for staging environment**:

```mermaid
graph LR
    A[Main Branch] --> B[CI Pipeline]
    B --> C[Deploy to Staging]
    C --> D[Integration Tests]
    D --> E[Manual Approval]
    E --> F[Deploy to Production]
```

### Production Deployment

**Planned workflow using Kamal**:

```yaml
# Future: .github/workflows/deploy.yml
deploy:
  runs-on: ubuntu-latest
  if: github.ref == 'refs/heads/main'
  needs: [scan_ruby, scan_js, lint, test]
  
  steps:
    - name: Deploy with Kamal
      run: kamal deploy
```

## Troubleshooting CI Issues

### Common Problems

1. **Bundle Install Failures**
   - Check Gemfile.lock is committed
   - Verify Ruby version compatibility

2. **Database Connection Issues**
   - Ensure PostgreSQL service is healthy
   - Check DATABASE_URL format

3. **Test Failures**
   - Review test logs in GitHub Actions
   - Download screenshots for system test failures

4. **RuboCop Violations**
   - Run `rubocop -a` locally to auto-fix
   - Review style guide for complex issues

### Getting Help

- **GitHub Actions logs**: Detailed execution logs for each step
- **Build artifacts**: Screenshots and test results downloadable
- **Community**: GitHub Discussions for workflow questions

The CI/CD pipeline ensures code quality, security, and reliability through automated testing and checks, providing confidence for continuous development and deployment.