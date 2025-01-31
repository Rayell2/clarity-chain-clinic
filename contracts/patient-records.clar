;; Storage for patient records and consents
(define-map patient-records 
  { patient: principal } 
  { 
    records: (list 200 { id: uint, provider: principal, data-hash: (buff 32), timestamp: uint })
    authorized-providers: (list 50 principal)
  }
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-no-record (err u101))
(define-constant err-already-exists (err u102))

;; Initialize patient record
(define-public (initialize-patient)
  (begin
    (asserts! (is-none (map-get? patient-records {patient: tx-sender})) err-already-exists)
    (ok (map-set patient-records
      {patient: tx-sender}
      {
        records: (list),
        authorized-providers: (list)
      }
    ))
  )
)

;; Add provider to authorized list
(define-public (authorize-provider (provider principal))
  (let (
    (patient-data (unwrap! (map-get? patient-records {patient: tx-sender}) err-no-record))
  )
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

;; Add medical record
(define-public (add-record (patient principal) (data-hash (buff 32)))
  (let (
    (patient-data (unwrap! (map-get? patient-records {patient: patient}) err-no-record))
  )
    (asserts! 
      (is-some (index-of (get authorized-providers patient-data) tx-sender))
      err-not-authorized
    )
    (ok (map-set patient-records
      {patient: patient}
      (merge patient-data {
        records: (unwrap-panic (as-max-len?
          (append 
            (get records patient-data)
            {
              id: (len (get records patient-data)),
              provider: tx-sender,
              data-hash: data-hash,
              timestamp: block-height
            }
          )
          u200
        ))
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
