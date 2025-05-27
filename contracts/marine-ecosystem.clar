;; Marine Ecosystem Contract
;; Tracks ocean ecosystem restoration and health metrics

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-not-found (err u201))
(define-constant err-invalid-data (err u202))

;; Ecosystem zones
(define-map ecosystem-zones
  { zone-id: uint }
  {
    name: (string-ascii 100),
    location: (string-ascii 100),
    area-size: uint,
    ecosystem-type: (string-ascii 50),
    baseline-health: uint,
    current-health: uint,
    restoration-start: uint,
    manager: principal
  }
)

;; Health measurements over time
(define-map health-records
  { zone-id: uint, timestamp: uint }
  {
    biodiversity-index: uint,
    water-quality: uint,
    coral-coverage: uint,
    fish-population: uint,
    pollution-level: uint,
    recorded-by: principal
  }
)

;; Restoration activities
(define-map restoration-activities
  { activity-id: uint }
  {
    zone-id: uint,
    activity-type: (string-ascii 50),
    start-date: uint,
    end-date: uint,
    cost: uint,
    impact-score: uint,
    executor: principal
  }
)

(define-data-var next-zone-id uint u1)
(define-data-var next-activity-id uint u1)

;; Create new ecosystem zone
(define-public (create-zone (name (string-ascii 100)) (location (string-ascii 100)) (area-size uint) (ecosystem-type (string-ascii 50)) (baseline-health uint))
  (let ((zone-id (var-get next-zone-id)))
    (map-set ecosystem-zones
      { zone-id: zone-id }
      {
        name: name,
        location: location,
        area-size: area-size,
        ecosystem-type: ecosystem-type,
        baseline-health: baseline-health,
        current-health: baseline-health,
        restoration-start: block-height,
        manager: tx-sender
      }
    )
    (var-set next-zone-id (+ zone-id u1))
    (ok zone-id)
  )
)

;; Record ecosystem health measurement
(define-public (record-health (zone-id uint) (biodiversity-index uint) (water-quality uint) (coral-coverage uint) (fish-population uint) (pollution-level uint))
  (match (map-get? ecosystem-zones { zone-id: zone-id })
    zone
    (let ((health-score (calculate-health-score biodiversity-index water-quality coral-coverage fish-population pollution-level)))
      (map-set health-records
        { zone-id: zone-id, timestamp: block-height }
        {
          biodiversity-index: biodiversity-index,
          water-quality: water-quality,
          coral-coverage: coral-coverage,
          fish-population: fish-population,
          pollution-level: pollution-level,
          recorded-by: tx-sender
        }
      )
      (map-set ecosystem-zones
        { zone-id: zone-id }
        (merge zone { current-health: health-score })
      )
      (ok health-score)
    )
    err-not-found
  )
)

;; Log restoration activity
(define-public (log-restoration-activity (zone-id uint) (activity-type (string-ascii 50)) (end-date uint) (cost uint) (impact-score uint))
  (match (map-get? ecosystem-zones { zone-id: zone-id })
    zone
    (let ((activity-id (var-get next-activity-id)))
      (map-set restoration-activities
        { activity-id: activity-id }
        {
          zone-id: zone-id,
          activity-type: activity-type,
          start-date: block-height,
          end-date: end-date,
          cost: cost,
          impact-score: impact-score,
          executor: tx-sender
        }
      )
      (var-set next-activity-id (+ activity-id u1))
      (ok activity-id)
    )
    err-not-found
  )
)

;; Calculate health score from metrics
(define-private (calculate-health-score (biodiversity uint) (water-quality uint) (coral-coverage uint) (fish-population uint) (pollution-level uint))
  (let ((positive-score (+ (+ biodiversity water-quality) (+ coral-coverage fish-population)))
        (negative-impact (/ pollution-level u2)))
    (if (> positive-score negative-impact)
      (- positive-score negative-impact)
      u0
    )
  )
)

;; Read functions
(define-read-only (get-zone (zone-id uint))
  (map-get? ecosystem-zones { zone-id: zone-id })
)

(define-read-only (get-health-record (zone-id uint) (timestamp uint))
  (map-get? health-records { zone-id: zone-id, timestamp: timestamp })
)

(define-read-only (get-restoration-activity (activity-id uint))
  (map-get? restoration-activities { activity-id: activity-id })
)

;; Calculate ecosystem improvement
(define-read-only (get-ecosystem-improvement (zone-id uint))
  (match (map-get? ecosystem-zones { zone-id: zone-id })
    zone
    (let ((baseline (get baseline-health zone))
          (current (get current-health zone)))
      (if (> current baseline)
        (some (- current baseline))
        (some u0)
      )
    )
    none
  )
)
