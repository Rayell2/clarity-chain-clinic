;; Provider registry
(define-map providers
  { provider: principal }
  { 
    name: (string-utf8 100),
    license: (string-ascii 50),
    active: bool,
    verified: bool
  }
)

;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-already-registered (err u101))

;; Register provider
(define-public (register-provider (name (string-utf8 100)) (license (string-ascii 50)))
  (begin
    (asserts! (is-none (map-get? providers {provider: tx-sender})) err-already-registered)
    (ok (map-set providers
      {provider: tx-sender}
      {
        name: name,
        license: license,
        active: true,
        verified: false
      }
    ))
  )
)

;; Verify provider 
(define-public (verify-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (match (map-get? providers {provider: provider})
      provider-data (ok (map-set providers
        {provider: provider}
        (merge provider-data {verified: true})
      ))
      err-unauthorized
    )
  )
)

;; Deactivate provider
(define-public (deactivate-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (match (map-get? providers {provider: provider})
      provider-data (ok (map-set providers
        {provider: provider}
        (merge provider-data {active: false})
      ))
      err-unauthorized
    )
  )
)

;; Get provider info
(define-read-only (get-provider-info (provider principal))
  (ok (map-get? providers {provider: provider}))
)
