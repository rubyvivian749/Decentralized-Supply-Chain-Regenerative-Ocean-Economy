;; Ocean Enterprise Verification Contract
;; Validates and manages regenerative ocean businesses

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-verified (err u102))
(define-constant err-invalid-status (err u103))

;; Enterprise verification status
(define-constant status-pending u0)
(define-constant status-verified u1)
(define-constant status-suspended u2)
(define-constant status-revoked u3)

;; Data structures
(define-map enterprises
  { enterprise-id: uint }
  {
    owner: principal,
    name: (string-ascii 100),
    verification-status: uint,
    verification-date: uint,
    sustainability-score: uint,
    location: (string-ascii 50)
  }
)

(define-map enterprise-metrics
  { enterprise-id: uint }
  {
    carbon-offset: uint,
    ecosystem-impact: uint,
    community-benefit: uint,
    last-updated: uint
  }
)

(define-data-var next-enterprise-id uint u1)

;; Register new ocean enterprise
(define-public (register-enterprise (name (string-ascii 100)) (location (string-ascii 50)))
  (let ((enterprise-id (var-get next-enterprise-id)))
    (map-set enterprises
      { enterprise-id: enterprise-id }
      {
        owner: tx-sender,
        name: name,
        verification-status: status-pending,
        verification-date: u0,
        sustainability-score: u0,
        location: location
      }
    )
    (var-set next-enterprise-id (+ enterprise-id u1))
    (ok enterprise-id)
  )
)

;; Verify enterprise (owner only)
(define-public (verify-enterprise (enterprise-id uint) (sustainability-score uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? enterprises { enterprise-id: enterprise-id })
      enterprise
      (begin
        (map-set enterprises
          { enterprise-id: enterprise-id }
          (merge enterprise {
            verification-status: status-verified,
            verification-date: block-height,
            sustainability-score: sustainability-score
          })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Update enterprise metrics
(define-public (update-metrics (enterprise-id uint) (carbon-offset uint) (ecosystem-impact uint) (community-benefit uint))
  (match (map-get? enterprises { enterprise-id: enterprise-id })
    enterprise
    (begin
      (asserts! (is-eq tx-sender (get owner enterprise)) err-owner-only)
      (map-set enterprise-metrics
        { enterprise-id: enterprise-id }
        {
          carbon-offset: carbon-offset,
          ecosystem-impact: ecosystem-impact,
          community-benefit: community-benefit,
          last-updated: block-height
        }
      )
      (ok true)
    )
    err-not-found
  )
)

;; Get enterprise info
(define-read-only (get-enterprise (enterprise-id uint))
  (map-get? enterprises { enterprise-id: enterprise-id })
)

;; Get enterprise metrics
(define-read-only (get-enterprise-metrics (enterprise-id uint))
  (map-get? enterprise-metrics { enterprise-id: enterprise-id })
)

;; Check if enterprise is verified
(define-read-only (is-verified (enterprise-id uint))
  (match (map-get? enterprises { enterprise-id: enterprise-id })
    enterprise (is-eq (get verification-status enterprise) status-verified)
    false
  )
)
