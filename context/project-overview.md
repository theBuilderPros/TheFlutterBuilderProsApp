# Project Overview

## Product

theBuilderPros is a focused mobile Rewards experience for Builders. The first release covers Builder identity and Rewards activation and use.

This document describes the intended product. See `current-state.md` for what is implemented now.

## Users and Needs

The primary user is a Builder who wants to:

- provide their Builder identity for Rewards activation
- check, receive, and send Builder Rewards

## Product Areas

### Rewards

Provides the first-release entry experience: Builder identity capture, Rewards activation, balance, receive, send, and history flows.

## Domain Language

- A **Builder** is the member identity.
- Use **Rewards**, **Builder Rewards**, and **Rewards Balance** in Builder-facing language. Avoid wallet and Web3 terminology.

## Product Boundaries

The mobile app is a focused companion, not a replacement for the Builder Workspace. It does not own:

- desktop coordination or Work board editing
- public marketing or landing pages
- chapters, guilds, tribes, or broader group administration
- privileged backend administration

Security-sensitive Rewards custody and signing must only be exposed through an explicitly designed and reviewed product flow.

## Product Principles

- Keep the mobile experience focused and easy to scan.
- Use established Builder Workspace terminology consistently.
- Distinguish clearly between implemented behavior and the intended product.
- Treat privacy, authorization, and Rewards security as product requirements, not implementation afterthoughts.
