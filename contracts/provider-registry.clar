;; Provider registry
(define-map providers
  { provider: principal }
  { 
    name: (string-utf8 100),
    license: (string-ascii 50),
    active: bool,
    verified: bool,
    specialty: (optional (string-utf8 50))
  }
)

;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-found (err u102))

;; Register provider
(define-public (register-provider (name (string-utf8 100)) (license (string-ascii 50)))
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
        specialty: none
      }
    ))
  )
)

;; Update provider info
(define-public (update-provider-specialty (specialty (string-utf8 50)))
  (let ((provider-data (unwrap! (map-get? providers {provider: tx-sender}) err-not-found)))
    (ok (map-set providers
      {provider: tx-sender}
      (merge provider-data {specialty: (some specialty)})
    ))
  )
)

;; Verify provider 
(define-public (verify-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (match (map-get? providers {provider: provider})
      provider-data (begin
        (print {event: "provider-verified", provider: provider})
        (ok (map-set providers
          {provider: provider}
          (merge provider-data {verified: true})
        ))
      )
      err-unauthorized
    )
  )
)

;; Deactivate provider
(define-public (deactivate-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (match (map-get? providers {provider: provider})
      provider-data (begin
        (print {event: "provider-deactivated", provider: provider})
        (ok (map-set providers
          {provider: provider}
          (merge provider-data {active: false})
        ))
      )
      err-unauthorized
    )
  )
)

;; Get provider info
(define-read-only (get-provider-info (provider principal))
  (ok (map-get? providers {provider: provider}))
)

;; Get verified providers
(define-read-only (get-verified-providers (active bool))
  (filter map-entries providers
    (lambda (entry)
      (and
        (get verified (get value entry))
        (is-eq active (get active (get value entry)))
      )
    )
  )
)
