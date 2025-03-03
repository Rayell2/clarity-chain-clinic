;; Provider registry with enhanced features
(define-map providers
  { provider: principal }
  { 
    name: (string-utf8 100),
    license: (string-ascii 50),
    active: bool,
    verified: bool,
    specialty: (optional (string-utf8 50)),
    contact: (optional (string-utf8 100)),
    rating-sum: uint,
    rating-count: uint,
    suspended: bool
  }
)

;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-found (err u102))
(define-constant err-invalid-rating (err u103))
(define-constant err-suspended (err u104))

;; Register provider
(define-public (register-provider 
  (name (string-utf8 100)) 
  (license (string-ascii 50))
  (contact (string-utf8 100))
)
  (begin
    (asserts! (is-none (map-get? providers {provider: tx-sender})) err-already-registered)
    (print {event: "provider-registered", provider: tx-sender})
    (ok (map-set providers
      {provider: tx-sender}
      {
        name: name,
        license: license,
        active: true,
        verified: false,
        specialty: none,
        contact: (some contact),
        rating-sum: u0,
        rating-count: u0,
        suspended: false
      }
    ))
  )
)

;; Update provider info
(define-public (update-provider-specialty (specialty (string-utf8 50)))
  (let ((provider-data (unwrap! (map-get? providers {provider: tx-sender}) err-not-found)))
    (asserts! (not (get suspended provider-data)) err-suspended)
    (ok (map-set providers
      {provider: tx-sender}
      (merge provider-data {specialty: (some specialty)})
    ))
  )
)

;; Add provider rating
(define-public (rate-provider (provider principal) (rating uint))
  (let ((provider-data (unwrap! (map-get? providers {provider: provider}) err-not-found)))
    (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
    (ok (map-set providers
      {provider: provider}
      (merge provider-data {
        rating-sum: (+ (get rating-sum provider-data) rating),
        rating-count: (+ (get rating-count provider-data) u1)
      })
    ))
  )
)

;; Get provider rating
(define-read-only (get-provider-rating (provider principal))
  (match (map-get? providers {provider: provider})
    provider-data (ok (tuple 
      (average (if (is-eq (get rating-count provider-data) u0)
        u0
        (/ (get rating-sum provider-data) (get rating-count provider-data))
      ))
      (count (get rating-count provider-data))
    ))
    err-not-found
  )
)

;; [Previous functions remain unchanged: verify-provider, deactivate-provider, get-provider-info]

;; Suspend provider
(define-public (suspend-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (match (map-get? providers {provider: provider})
      provider-data (begin
        (print {event: "provider-suspended", provider: provider})
        (ok (map-set providers
          {provider: provider}
          (merge provider-data {suspended: true})
        ))
      )
      err-not-found
    )
  )
)

;; Search providers by specialty
(define-read-only (search-providers-by-specialty (specialty (string-utf8 50)))
  (filter map-entries providers
    (lambda (entry)
      (and
        (get verified (get value entry))
        (get active (get value entry))
        (not (get suspended (get value entry)))
        (is-eq (get specialty (get value entry)) (some specialty))
      )
    )
  )
)
