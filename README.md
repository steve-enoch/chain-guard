# ChainGuard - Decentralized Identity Verification Protocol

## Overview

**ChainGuard** is a decentralized identity verification protocol designed for compliance-critical applications such as border control, financial services, and credential verification systems.

Built on **Stacks**, which anchors directly to **Bitcoin** through Proof of Transfer (PoX), ChainGuard ensures **tamper-proof, globally verifiable identity credentials** without reliance on centralized authorities.

The protocol introduces **sovereign identity management**, where credential issuance, verification, and revocation are handled transparently on-chain while preserving privacy through a decentralized trust model.

---

## System Overview

ChainGuard enables a fully decentralized identity lifecycle:

1. **Authority Registry**

   * Only trusted, registered authorities (e.g., governments, financial institutions) can issue or revoke credentials.
   * Authorities are managed by the contract owner and may be added or revoked as needed.

2. **Credential Management**

   * Credentials (e.g., passports) are issued as immutable on-chain records.
   * Each credential includes metadata, validity period, issuing authority, and a status flag.
   * Credentials are uniquely tied to both a holder (principal address) and a credential identifier.

3. **Verification**

   * Anyone can verify the validity of a credential using read-only contract functions.
   * Status checks (active/revoked/expired) allow for fast, permissionless verification.

4. **Lifecycle Operations**

   * Issuance, revocation, metadata updates, and validity extensions are supported.
   * Only the original issuing authority may update or revoke a credential.

---

## Contract Architecture

The protocol is designed around four main state maps:

* **`Passports`**
  Core credential storage. Indexed by `passport-id`, storing details such as holder, issuer, issue/expiry date, metadata, and status.

* **`PassportAuthorities`**
  Registry of issuing authorities. Each authority is represented by a principal and a flag indicating active status.

* **`HolderPassports`**
  Reverse lookup table mapping holder addresses to their credential identifiers. Ensures one credential per holder.

* **`PassportNumbers`**
  Uniqueness registry ensuring that credential identifiers are never reused.

---

## Data Flow

### 1. Credential Issuance

* Authority calls `issue-passport`.
* Contract enforces uniqueness (no duplicate IDs, no multiple credentials per holder).
* Credential details are stored in `Passports`.
* Reverse lookup and uniqueness maps updated.

### 2. Credential Verification

* Third-party verifier calls `get-passport` or `is-valid-passport?`.
* Contract checks `status` and `expiry-date`.
* Returns immutable, cryptographically verifiable on-chain record.

### 3. Credential Revocation

* Issuer calls `revoke-passport`.
* Contract updates `status` to `revoked`.
* Credential remains permanently recorded but flagged as invalid.

### 4. Metadata or Validity Updates

* Issuer may update `metadata` or extend validity via dedicated functions.
* Preserves continuity of credential while ensuring flexibility for real-world use cases.

---

## Error Handling

The protocol defines strict error codes for robust handling:

* `u1` → Unauthorized operation
* `u2` → Invalid input
* `u3` → Already exists
* `u4` → Not found
* `u5` → Invalid operation
* `u6` → Operation failed

---

## Example Usage

* **Add Authority**

  ```clarity
  (contract-call? .chain-guard add-authority 'SP123... u"Immigration Authority")
  ```

* **Issue Passport**

  ```clarity
  (contract-call? .chain-guard issue-passport 
    { passport-id: u"PASS123",
      holder: 'SP789...,
      metadata: u"Nationality: NGN, Name: John Doe",
      expiry-date: u120000 })
  ```

* **Verify Passport**

  ```clarity
  (contract-call? .chain-guard is-valid-passport? u"PASS123")
  ```

* **Revoke Passport**

  ```clarity
  (contract-call? .chain-guard revoke-passport u"PASS123")
  ```

---

## Security & Design Principles

* **Sovereignty:** Identities are owned by users, not platforms.
* **Decentralization:** No single entity controls the verification process.
* **Auditability:** All state changes are permanently recorded on Bitcoin.
* **Privacy-aware:** Minimal sensitive data on-chain; metadata fields allow flexible encoding strategies.
* **Compliance-ready:** Built for regulated industries requiring strict identity guarantees.

---

## Future Extensions

* Integration with **zk-proofs** for privacy-preserving selective disclosure.
* Support for multiple credential types beyond passports (IDs, licenses, certificates).
* Decentralized authority governance to remove single-contract-owner dependency.
* Off-chain indexing and verifiable credential interoperability (DID/VC standards).