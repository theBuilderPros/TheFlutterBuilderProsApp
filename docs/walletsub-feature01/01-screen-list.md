# Wallet Sub-Feature 01 — Screen List

The first release has no Home screen. First-time activation follows
`rewards-first-time-activation-spec-v2.md`. Every screen uses the Wallet SDK through
a controller; no screen handles activation internals.

## Builder Rewards

| ID | Screen | Purpose | Main actions |
| --- | --- | --- | --- |
| B-01 | Rewards — Not Activated | Collect Builder name and phone | Start activation |
| B-02 | Activation Request | Display the SDK-provided request QR | Copy request, scan response, import QR image |
| B-03 | Review Activation | Display the SDK-provided review | Approve, cancel |
| B-04 | Activation Progress | Show safe progress and outcome | Wait, retry when offered |
| B-05 | Rewards | Show Builder card, balance, and actions | Receive, Send, history, remove access |
| B-06 | Receive Rewards | Display SDK-provided receive QR | Copy, return |
| B-07 | Scan Recipient | Pass scanned/imported content to the SDK | Scan, import, cancel |
| B-08 | Send Amount | Collect Rewards amount | Continue, cancel |
| B-09 | Review Send | Display SDK-provided review | Confirm, cancel |
| B-10 | Confirm Action | Confirm a protected action | Confirm, cancel |
| B-11 | Send Outcome | Display SDK-provided outcome | Done, safe retry |
| B-12 | Rewards History | Display safe Rewards activity | Refresh, inspect |
| B-13 | Rewards Locked | Explain local protection | Unlock |
| B-14 | Remove Rewards Access | Remove access from this device | Confirm, cancel |

## App Master

| ID | Screen | Purpose | Main actions |
| --- | --- | --- | --- |
| M-01 | App Master Overview | Show activation capacity and Builder access | Scan/import request, open Advanced/My Rewards |
| M-02 | Activate Builder | Display the SDK-provided Builder review | Create activation QR, cancel |
| M-03 | Activation QR | Display the SDK-provided response QR | Save image, finish |
| M-04 | Advanced | Configure NOWNodes and show safe service/support status | Save endpoint/API key, rotate configuration, refresh status |
| M-05 | My Rewards | Reuse the Builder Rewards screens | Standard Rewards actions |

## UI rule

Screens render safe SDK view models and return user intent. They never decode QR
content, make activation decisions, manipulate protected values, or translate raw
provider failures.
