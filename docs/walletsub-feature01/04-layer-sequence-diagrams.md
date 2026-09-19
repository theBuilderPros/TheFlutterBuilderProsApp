# Wallet Sub-Feature 01 — Layer Sequence Diagrams

The Wallet SDK is intentionally a black box. These diagrams show only the interface available to application developers. NOWNodes is named only in App Master Advanced; Builder-facing screens continue to use plain Rewards language.

## 0. Builder and App interaction sequence

```mermaid
sequenceDiagram
    actor Builder
    participant BuilderUI as Builder App
    actor Master as App Master
    participant MasterUI as App Master App

    Master->>MasterUI: Interaction 0 - Save NOWNodes configuration
    MasterUI-->>Master: Configuration verified and ready
    Builder->>BuilderUI: Interaction 1 - Enter name and phone
    Builder->>BuilderUI: Interaction 2 - Start activation
    BuilderUI-->>Builder: Interaction 3 - Show request QR
    Master->>MasterUI: Interaction 4 - Scan or import request QR
    MasterUI-->>Master: Interaction 5 - Show Builder review
    Master->>MasterUI: Interaction 6 - Approve setup
    MasterUI-->>Master: Interaction 7 - Show response QR with protected configuration
    Builder->>BuilderUI: Interaction 8 - Scan or import response QR
    BuilderUI-->>Builder: Interaction 9 - Show activation review
    Builder->>BuilderUI: Interaction 10 - Approve activation
    BuilderUI-->>Builder: Interaction 11 - Install configuration and show verified Rewards
```

## 1. Create activation request

```mermaid
sequenceDiagram
    actor Builder
    participant Screen as Rewards Screen
    participant Controller as WalletController
    participant SDK as WalletSdk

    Builder->>Screen: Interaction 1 - Enter name and phone
    Builder->>Screen: Interaction 2 - Start activation
    Screen->>Controller: startActivation()
    Controller->>SDK: startActivation(builder)
    SDK-->>Controller: ActivationRequestView
    Controller-->>Screen: Request view state
    Screen-->>Builder: Interaction 3 - Show request QR
```

## 2. App Master prepares response

```mermaid
sequenceDiagram
    actor Master as App Master
    participant Screen as App Master Screen
    participant Controller as AppMasterController
    participant SDK as WalletSdk

    Master->>Screen: Interaction 0 - Enter NOWNodes settings in Advanced
    Screen->>Controller: saveProviderConfiguration(input)
    Controller->>SDK: saveAppMasterProviderConfiguration(input)
    SDK-->>Controller: Safe verified status
    Controller-->>Screen: Clear API key and show ready status
    Master->>Screen: Interaction 4 - Scan or import request QR
    Screen->>Controller: inspectRequest(qrValue)
    Controller->>SDK: inspectBuilderRequest(qrValue)
    SDK-->>Controller: ActivationRequestReview
    Controller-->>Screen: Safe review state
    Screen-->>Master: Interaction 5 - Show Builder review
    Master->>Screen: Interaction 6 - Approve setup
    Screen->>Controller: approveRequest(requestId)
    Controller->>SDK: approveBuilderRequest(requestId)
    Note over SDK: Include encrypted device-bound NOWNodes configuration
    SDK-->>Controller: ActivationResponseView
    Controller-->>Screen: Response view state
    Screen-->>Master: Interaction 7 - Show protected response QR
```

## 3. Builder completes activation

```mermaid
sequenceDiagram
    actor Builder
    participant Screen as Rewards Screen
    participant Controller as WalletController
    participant SDK as WalletSdk

    Builder->>Screen: Interaction 8 - Scan or import response QR
    Screen->>Controller: inspectResponse(qrValue)
    Controller->>SDK: inspectActivationResponse(qrValue)
    SDK-->>Controller: ActivationReview
    Controller-->>Screen: Safe review state
    Screen-->>Builder: Interaction 9 - Show activation review
    Builder->>Screen: Interaction 10 - Approve activation
    Screen->>Controller: approveActivation(responseId)
    Controller->>SDK: approveActivation(responseId)
    Note over SDK: Verify, health-check, and install NOWNodes configuration
    SDK-->>Controller: ActivationOutcome
    Controller-->>Screen: Safe outcome state
    Screen-->>Builder: Interaction 11 - Show verified Rewards
```

## 4. Failure and restoration

```mermaid
sequenceDiagram
    participant Screen as Rewards Screen
    participant Controller as WalletController
    participant SDK as WalletSdk

    Screen->>Controller: App starts or resumes
    Controller->>SDK: getActivationStatus()
    SDK-->>Controller: ActivationStatus
    alt Continue safely
        Controller-->>Screen: Restore matching screen
    else Retry is safe
        Controller-->>Screen: Show retry action
    else Restart is required
        Controller-->>Screen: Show start-again action
    end
```

No application-layer diagram expands the Wallet SDK internals.
