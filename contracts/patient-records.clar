;; Storage for patient records and consents
(define-map patient-records 
  { patient: principal } 
  { 
    records: (list 200 { id: uint, provider: principal, data-hash: (buff 32), timestamp: uint }),
    authorized-providers: (list 50 principal),
    record-count: uint
  }
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-no-record (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-list-full (err u103))

;; Initialize patient record
(define-public (initialize-patient)
  (begin
    (asserts! (is-none (map-get? patient-records {patient: tx-sender})) err-already-exists)
    (ok (map-set patient-records
      {patient: tx-sender}
      {
        records: (list),
        authorized-providers: (list),
        record-count: u0
      }
    ))
  )
)

;; Add provider to authorized list
(define-public (authorize-provider (provider principal))
  (let (
    (patient-data (unwrap! (map-get? patient-records {patient: tx-sender}) err-no-record))
  )
    (asserts! (< (len (get authorized-providers patient-data)) u50) err-list-full)
    (print {event: "provider-authorized", patient: tx-sender, provider: provider})
    (ok (map-set patient-records
      {patient: tx-sender}
      (merge patient-data {
        authorized-providers: (unwrap-panic (as-max-len? 
          (append (get authorized-providers patient-data) provider)
          u50
        ))
      })
    ))
  )
)

;; Revoke provider authorization
(define-public (revoke-provider (provider principal))
  (let (
    (patient-data (unwrap! (map-get? patient-records {patient: tx-sender}) err-no-record))
    (filtered-providers (filter not-eq? (get authorized-providers patient-data) provider))
  )
    (print {event: "provider-revoked", patient: tx-sender, provider: provider})
    (ok (map-set patient-records
      {patient: tx-sender}
      (merge patient-data {
        authorized-providers: filtered-providers
      })
    ))
  )
)

;; Add medical record
(define-public (add-record (patient principal) (data-hash (buff 32)))
  (let (
    (patient-data (unwrap! (map-get? patient-records {patient: patient}) err-no-record))
  )
    (asserts! 
      (is-some (index-of (get authorized-providers patient-data) tx-sender))
      err-not-authorized
    )
    (asserts! (< (len (get records patient-data)) u200) err-list-full)
    (print {event: "record-added", patient: patient, provider: tx-sender})
    (ok (map-set patient-records
      {patient: patient}
      (merge patient-data {
        records: (unwrap-panic (as-max-len?
          (append 
            (get records patient-data)
            {
              id: (get record-count patient-data),
              provider: tx-sender,
              data-hash: data-hash,
              timestamp: block-height
            }
          )
          u200
        )),
        record-count: (+ (get record-count patient-data) u1)
      })
    ))
  )
)

;; Get patient records
(define-read-only (get-records (patient principal))
  (let (
    (patient-data (unwrap! (map-get? patient-records {patient: patient}) err-no-record))
  )
    (asserts!
      (or
        (is-eq tx-sender patient)
        (is-some (index-of (get authorized-providers patient-data) tx-sender))
      )
      err-not-authorized
    )
    (ok (get records patient-data))
  )
)
