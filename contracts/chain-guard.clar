;; Title: ChainGuard - Decentralized Identity Verification Protocol
;;
;; Summary:
;; A trustless digital identity management system built on Bitcoin's security layer,
;; enabling sovereign identity verification without centralized gatekeepers.
;;
;; Description:
;; ChainGuard revolutionizes identity verification by leveraging Stacks' Bitcoin-anchored
;; infrastructure to create tamper-proof digital credentials. Authority nodes can issue,
;; manage, and revoke identity documents while maintaining cryptographic proof of authenticity.
;; Each credential is permanently recorded on Bitcoin through Stacks' Proof of Transfer,
;; ensuring immutability and global verifiability. The protocol enables permissionless
;; verification of identity status while preserving user privacy through decentralized
;; architecture. Built for compliance-critical applications including border control,
;; financial services, and credential verification systems.

;; CONSTANTS

(define-constant CONTRACT-OWNER tx-sender)

;; Error codes
(define-constant ERR-UNAUTHORIZED (err u1))
(define-constant ERR-INVALID-INPUT (err u2))
(define-constant ERR-ALREADY-EXISTS (err u3))
(define-constant ERR-NOT-FOUND (err u4))
(define-constant ERR-INVALID (err u5))
(define-constant ERR-OPERATION-FAILED (err u6))

;; DATA STRUCTURES

;; Core credential storage indexed by unique identifier
(define-map Passports
    { passport-id: (string-utf8 20) }
    {
        holder: principal,
        issue-date: uint,
        expiry-date: uint,
        metadata: (string-utf8 500),
        issuer: principal,
        status: (string-utf8 20)
    }
)

;; Authorized issuing authorities registry
(define-map PassportAuthorities
    { authority: principal }
    {
        active: bool,
        name: (string-utf8 100)
    }
)

;; Reverse lookup: holder address to credential identifier
(define-map HolderPassports
    { holder: principal }
    { passport-id: (string-utf8 20) }
)

;; Uniqueness enforcement for credential identifiers
(define-map PassportNumbers
    { passport-id: (string-utf8 20) }
    { exists: bool }
)

;; READ-ONLY FUNCTIONS

(define-read-only (get-passport (passport-id (string-utf8 20)))
    (map-get? Passports { passport-id: passport-id })
)

(define-read-only (get-holder-passport (holder principal))
    (map-get? HolderPassports { holder: holder })
)

(define-read-only (is-valid-passport? (passport-id (string-utf8 20)))
    (match (map-get? Passports { passport-id: passport-id })
        passport (is-eq (get status passport) u"active")
        false
    )
)

(define-read-only (is-authority (addr principal))
    (match (map-get? PassportAuthorities { authority: addr })
        auth (get active auth)
        false
    )
)

;; AUTHORITY MANAGEMENT

(define-public (add-authority
        (authority principal)
        (authority-name (string-utf8 100))
    )
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (map-set PassportAuthorities 
            { authority: authority }
            {
                active: true,
                name: authority-name
            }
        )
        (ok true)
    )
)

(define-public (remove-authority (authority principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (map-set PassportAuthorities 
            { authority: authority }
            {
                active: false,
                name: u"Revoked"
            }
        )
        (ok true)
    )
)

;; CREDENTIAL LIFECYCLE MANAGEMENT

(define-public (issue-passport (params {
    passport-id: (string-utf8 20),
    holder: principal,
    metadata: (string-utf8 500),
    expiry-date: uint
}))
    (let (
            (passport-id (get passport-id params))
            (holder (get holder params))
            (metadata (get metadata params))
            (expiry-date (get expiry-date params))
        )
        (begin
            (asserts! (is-authority tx-sender) ERR-UNAUTHORIZED)
            (asserts! (is-none (map-get? PassportNumbers { passport-id: passport-id })) ERR-ALREADY-EXISTS)
            (asserts! (is-none (map-get? HolderPassports { holder: holder })) ERR-ALREADY-EXISTS)
            
            (map-set Passports 
                { passport-id: passport-id }
                {
                    holder: holder,
                    issue-date: stacks-block-height,
                    expiry-date: expiry-date,
                    metadata: metadata,
                    issuer: tx-sender,
                    status: u"active"
                }
            )
            (map-set HolderPassports { holder: holder } { passport-id: passport-id })
            (map-set PassportNumbers { passport-id: passport-id } { exists: true })
            (ok passport-id)
        )
    )
)

(define-public (revoke-passport (passport-id (string-utf8 20)))
    (let (
            (passport (unwrap! (map-get? Passports { passport-id: passport-id }) ERR-NOT-FOUND))
        )
        (begin
            (asserts! (is-eq (get issuer passport) tx-sender) ERR-UNAUTHORIZED)
            (map-set Passports 
                { passport-id: passport-id }
                (merge passport { status: u"revoked" })
            )
            (ok true)
        )
    )
)

(define-public (update-passport-metadata
        (passport-id (string-utf8 20))
        (new-meta (string-utf8 500))
    )
    (let (
            (passport (unwrap! (map-get? Passports { passport-id: passport-id }) ERR-NOT-FOUND))
        )
        (begin
            (asserts! (is-eq (get issuer passport) tx-sender) ERR-UNAUTHORIZED)
            (map-set Passports 
                { passport-id: passport-id }
                (merge passport { metadata: new-meta })
            )
            (ok true)
        )
    )
)

(define-public (extend-passport-validity
        (passport-id (string-utf8 20))
        (new-expiry uint)
    )
    (let (
            (passport (unwrap! (map-get? Passports { passport-id: passport-id }) ERR-NOT-FOUND))
        )
        (begin
            (asserts! (is-eq (get issuer passport) tx-sender) ERR-UNAUTHORIZED)
            (map-set Passports 
                { passport-id: passport-id }
                (merge passport { expiry-date: new-expiry })
            )
            (ok true)
        )
    )
)