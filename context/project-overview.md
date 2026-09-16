# Project Overview

## Product

theBuilderPros is theBuilderPros mobile companion. It is intentionally smaller than the Electron Builder Workspace: the desktop product coordinates and executes work, while mobile provides a convenient Builder-facing view of identity, Rewards, Apps, and App Squad progress.

## Users

The primary user is a Builder who wants to:

- see their Builder identity and level
- check Builder Rewards
- receive or send Rewards
- discover and follow Apps
- understand what an App Squad is building
- review WIP, Committed Work, and shipped Work History

## Current Phase

The repository is in a UI-first prototype phase. Screens, navigation, brand treatment, and mock read models are implemented. Real authentication, persistence, backend reads, and Rewards transactions are deferred to the integration phase.

## Mobile Read Model

### Home

Shows Builder profile, Rewards balance, and followed Apps derived eventually from `squad_builder`.

### Rewards

Shows balance, Receive, Send, and eventually basic history. Builder-facing language must not use wallet or Web3 terminology.

### Apps

Provides marketplace-style App discovery with name, description, status, WIP count, completed-work count, and a detail action.

### App Detail

Provides a read-only overview with WIP, Committed Work, and Work History. Work Item cards show title, outcome, state, cycle, week number, and week label.

## Shared Workspace Concepts

The mobile app should eventually read the same Supabase concepts as the desktop Workspace:

- `builder`
- `squad_app`
- `squad_builder`
- `work_item`
- `squad_work_item`
- `builder_work_item` where assignment data is needed

Work Items remain independent from Builders and Apps. Link tables represent participation and association.

## Out of Scope Today

- desktop Coordinate and Work board editing
- Work Item creation or lifecycle mutation
- public marketing/landing pages
- chapters, guilds, tribes, or broader group management
- privileged backend administration
- service-role credentials in the client
- real Rewards custody/signing until its security design is explicitly implemented

## Success Criteria for the Current Phase

- all reference mobile screens exist in Flutter
- navigation and presentation interactions work with mocks
- theBuilderPros branding is consistent and restrained
- terminology aligns with the Workspace data model
- architecture remains ready for service-backed integration
- documentation does not claim unimplemented behavior
