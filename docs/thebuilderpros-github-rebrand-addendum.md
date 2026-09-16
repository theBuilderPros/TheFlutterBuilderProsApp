# theBuilderPros GitHub Rebrand Addendum

> Superseded for execution by `docs/thebuilderpros-rebrand-plan-final.md`.


Status: required companion to `docs/thebuilderpros-rebrand-plan.md`  
Prepared: 2026-09-16

## Confirmed repository state

- Current GitHub repository: `https://github.com/theBuilderPros/TheFlutterBuilderStudioApp`
- Confirmed GitHub organization: `theBuilderPros`
- Current repository name: `TheFlutterBuilderStudioApp`
- Proposed final repository: `https://github.com/theBuilderPros/TheFlutterBuilderProsApp`
- Current local `origin`: `https://github.com/theBuilderUni/TheFlutterBuilderStudioApp.git`
- Default branch: `main`
- Other remote branches found: `production`, `MiniAppStore`, and `Wallet`
- `main` and `production` currently reference the same commit; `MiniAppStore` and `Wallet` reference different commits.

This addendum replaces the main plan's open question about the GitHub organization. The organization has already changed to `theBuilderPros`. Only the repository rename and final canonical URL still require confirmation.

## Required GitHub updates

### 1. Rename the repository

After approving the final repository name, rename `TheFlutterBuilderStudioApp` to `TheFlutterBuilderProsApp` through GitHub repository settings.

Use GitHub's rename operation so that commit history, issues, pull requests, stars, releases, and URL redirects are retained. Do not create a replacement repository, recreate Git history, or force-push rewritten history.

### 2. Update the local remote

After the GitHub rename, update and verify the local remote:

```powershell
git remote set-url origin https://github.com/theBuilderPros/TheFlutterBuilderProsApp.git
git remote -v
git ls-remote origin
```

Do not leave the local repository dependent on GitHub's redirect from the former `theBuilderUni` URL.

### 3. Update repository-facing metadata

Review and update:

- repository About description
- repository website URL
- repository topics
- README repository and clone URLs
- README product name and technical identity table
- status badges and links
- issue and pull-request templates
- contributing, security, support, funding, and code-owner files if present
- release titles, release notes, and downloadable artifact names
- package or container metadata if introduced
- GitHub Pages configuration, site URLs, and custom domain if used

The repository description should use the approved `theBuilderPros` wording and must not imply that mock functionality is production-ready.

### 4. Audit automation and integrations

Search GitHub Actions and related configuration for:

```text
theBuilderStudio
the_builder_studio
thebuilderstudio
TheFlutterBuilderStudioApp
theBuilderUni
thebuilderuni
com.thebuilderuni
```

Update relevant occurrences in:

- workflow names and triggers
- build and release artifact names
- cache keys
- environment names
- deployment jobs and target URLs
- repository and organization variables
- reusable workflow references
- package publishing configuration

Review installed GitHub Apps, deploy keys, webhooks, environments, environment protection rules, Actions permissions, rulesets, branch protection, Pages deployments, and external CI/CD integrations. Verify that each integration followed the rename redirect or update it explicitly.

Preserve secrets. Do not expose, copy into documentation, or commit secret values during this audit.

### 5. Review all branches

The current remote exposes:

- `main`
- `production`
- `MiniAppStore`
- `Wallet`

Before changing branch contents:

1. Decide whether `MiniAppStore` and `Wallet` are still maintained.
2. Confirm the role of `production` and whether deployments depend on it.
3. Apply the rebrand to every maintained branch so an old-brand merge cannot reintroduce obsolete names or assets.
4. Resolve rebrand conflicts before merging divergent branches.
5. Archive or delete a branch only with explicit approval.
6. Confirm that `main` remains the intended default branch.

### 6. Audit collaboration records and organization links

Search for former product, organization, repository, and application-ID references in:

- open and closed issues
- open and merged pull requests
- discussions
- wiki pages
- GitHub Projects
- releases and tags
- organization profile content
- pinned repositories
- organization-level documentation
- organization Actions secrets and variables whose names encode the former identity

Preserve historical statements when accuracy matters. If an old name must remain, label it clearly as the former identity rather than rewriting history misleadingly.

### 7. Update controlled external links

GitHub may redirect the former repository URL after a rename, but all controlled references should be updated to the final canonical URL. Check:

- local developer clones and onboarding instructions
- other repositories
- product and documentation sites
- CI/CD services
- app-store listings
- Supabase, Firebase, OAuth, or analytics dashboards when introduced
- bookmarks and internal team documentation

Verify the redirect, but do not rely on it indefinitely.

## Recommended execution order

1. Approve `TheFlutterBuilderProsApp` as the final repository name.
2. Complete and verify the local product/package/platform rebrand.
3. Update repository documentation and GitHub-specific files in the same focused change.
4. Review all maintained branches and deployment dependencies.
5. Rename the GitHub repository through repository settings.
6. Update the local `origin` and other controlled clone URLs.
7. Verify Actions, branch protection, environments, webhooks, GitHub Apps, Pages, and external integrations.
8. Perform a final old-name search across the repository and GitHub collaboration surfaces.

## Acceptance criteria

The GitHub portion of the rebrand is complete when:

- the repository is owned by the confirmed `theBuilderPros` organization;
- the repository name and About description use the approved theBuilderPros identity;
- local `origin` and all controlled clone instructions use the final canonical URL;
- README links, badges, workflows, releases, and artifacts use the new identity;
- maintained branches cannot unintentionally reintroduce the former brand;
- branch protections, Actions, environments, Pages, deployments, and webhooks still work;
- external integrations have been verified rather than assumed to follow redirects;
- repository history, issues, pull requests, releases, and collaboration records remain intact;
- no secrets were disclosed or committed during the migration.
