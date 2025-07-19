;; Genealogy Tracking Contract
;; Maintains family history and burial records

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-PERSON-NOT-FOUND (err u401))
(define-constant ERR-INVALID-INPUT (err u402))
(define-constant ERR-RELATIONSHIP-EXISTS (err u403))
(define-constant ERR-INVALID-RELATIONSHIP (err u404))

;; Data Variables
(define-data-var next-person-id uint u1)
(define-data-var total-records uint u0)

;; Data Maps
(define-map genealogy-records
  { person-id: uint }
  {
    full-name: (string-ascii 100),
    birth-date: (optional uint),
    death-date: (optional uint),
    burial-plot-id: (optional uint),
    burial-date: (optional uint),
    gender: (string-ascii 10),
    occupation: (optional (string-ascii 100)),
    notes: (optional (string-ascii 500)),
    created-by: principal,
    created-at: uint
  }
)

(define-map family-relationships
  { person-id: uint, related-person-id: uint }
  {
    relationship-type: (string-ascii 20),
    created-by: principal,
    created-at: uint
  }
)

(define-map person-children
  { parent-id: uint }
  { child-ids: (list 20 uint) }
)

(define-map person-parents
  { child-id: uint }
  { parent-ids: (list 2 uint) }
)

(define-map name-search
  { name-key: (string-ascii 100) }
  { person-ids: (list 50 uint) }
)

;; Read-only functions
(define-read-only (get-person (person-id uint))
  (map-get? genealogy-records { person-id: person-id })
)

(define-read-only (get-relationship (person-id uint) (related-person-id uint))
  (map-get? family-relationships { person-id: person-id, related-person-id: related-person-id })
)

(define-read-only (get-person-children (parent-id uint))
  (map-get? person-children { parent-id: parent-id })
)

(define-read-only (get-person-parents (child-id uint))
  (map-get? person-parents { child-id: child-id })
)

(define-read-only (search-by-name (name (string-ascii 100)))
  (map-get? name-search { name-key: name })
)

(define-read-only (get-total-records)
  (var-get total-records)
)

(define-read-only (is-deceased (person-id uint))
  (match (map-get? genealogy-records { person-id: person-id })
    person-data (is-some (get death-date person-data))
    false
  )
)

;; Public functions
(define-public (create-person-record
  (full-name (string-ascii 100))
  (birth-date (optional uint))
  (death-date (optional uint))
  (burial-plot-id (optional uint))
  (burial-date (optional uint))
  (gender (string-ascii 10))
  (occupation (optional (string-ascii 100)))
  (notes (optional (string-ascii 500)))
)
  (let ((person-id (var-get next-person-id)))
    (asserts! (> (len full-name) u0) ERR-INVALID-INPUT)
    (asserts! (or (is-eq gender "male") (is-eq gender "female") (is-eq gender "other")) ERR-INVALID-INPUT)

    ;; Validate dates if provided
    (asserts! (match birth-date
      some-date (> some-date u0)
      true
    ) ERR-INVALID-INPUT)

    (asserts! (match death-date
      some-date (> some-date u0)
      true
    ) ERR-INVALID-INPUT)

    (map-set genealogy-records
      { person-id: person-id }
      {
        full-name: full-name,
        birth-date: birth-date,
        death-date: death-date,
        burial-plot-id: burial-plot-id,
        burial-date: burial-date,
        gender: gender,
        occupation: occupation,
        notes: notes,
        created-by: tx-sender,
        created-at: block-height
      }
    )

    (update-name-search full-name person-id)
    (var-set next-person-id (+ person-id u1))
    (var-set total-records (+ (var-get total-records) u1))
    (ok person-id)
  )
)

(define-public (add-family-relationship
  (person-id uint)
  (related-person-id uint)
  (relationship-type (string-ascii 20))
)
  (begin
    (asserts! (is-some (map-get? genealogy-records { person-id: person-id })) ERR-PERSON-NOT-FOUND)
    (asserts! (is-some (map-get? genealogy-records { person-id: related-person-id })) ERR-PERSON-NOT-FOUND)
    (asserts! (not (is-eq person-id related-person-id)) ERR-INVALID-RELATIONSHIP)
    (asserts! (is-none (map-get? family-relationships { person-id: person-id, related-person-id: related-person-id })) ERR-RELATIONSHIP-EXISTS)
    (asserts! (is-valid-relationship-type relationship-type) ERR-INVALID-INPUT)

    (map-set family-relationships
      { person-id: person-id, related-person-id: related-person-id }
      {
        relationship-type: relationship-type,
        created-by: tx-sender,
        created-at: block-height
      }
    )

    ;; Update parent-child mappings if applicable
    (if (is-eq relationship-type "parent")
      (begin
        (update-person-children person-id related-person-id)
        (update-person-parents related-person-id person-id)
      )
      (if (is-eq relationship-type "child")
        (begin
          (update-person-children related-person-id person-id)
          (update-person-parents person-id related-person-id)
        )
        true
      )
    )

    (ok true)
  )
)

(define-public (update-burial-info (person-id uint) (burial-plot-id uint) (burial-date uint))
  (let ((person-data (unwrap! (map-get? genealogy-records { person-id: person-id }) ERR-PERSON-NOT-FOUND)))
    (asserts! (> burial-plot-id u0) ERR-INVALID-INPUT)
    (asserts! (> burial-date u0) ERR-INVALID-INPUT)

    (map-set genealogy-records
      { person-id: person-id }
      (merge person-data {
        burial-plot-id: (some burial-plot-id),
        burial-date: (some burial-date)
      })
    )

    (ok true)
  )
)

(define-public (update-death-date (person-id uint) (death-date uint))
  (let ((person-data (unwrap! (map-get? genealogy-records { person-id: person-id }) ERR-PERSON-NOT-FOUND)))
    (asserts! (> death-date u0) ERR-INVALID-INPUT)

    (map-set genealogy-records
      { person-id: person-id }
      (merge person-data { death-date: (some death-date) })
    )

    (ok true)
  )
)

(define-public (add-notes (person-id uint) (additional-notes (string-ascii 500)))
  (let ((person-data (unwrap! (map-get? genealogy-records { person-id: person-id }) ERR-PERSON-NOT-FOUND)))
    (asserts! (> (len additional-notes) u0) ERR-INVALID-INPUT)

    (map-set genealogy-records
      { person-id: person-id }
      (merge person-data {
        notes: (some additional-notes)
      })
    )

    (ok true)
  )
)

;; Private functions
(define-private (is-valid-relationship-type (relationship (string-ascii 20)))
  (or
    (is-eq relationship "parent")
    (is-eq relationship "child")
    (is-eq relationship "spouse")
    (is-eq relationship "sibling")
    (is-eq relationship "grandparent")
    (is-eq relationship "grandchild")
  )
)

(define-private (update-person-children (parent-id uint) (child-id uint))
  (let ((current-children (default-to { child-ids: (list) } (map-get? person-children { parent-id: parent-id }))))
    (match (as-max-len? (append (get child-ids current-children) child-id) u20)
      new-list (begin
        (map-set person-children
          { parent-id: parent-id }
          { child-ids: new-list }
        )
        true
      )
      false
    )
  )
)

(define-private (update-person-parents (child-id uint) (parent-id uint))
  (let ((current-parents (default-to { parent-ids: (list) } (map-get? person-parents { child-id: child-id }))))
    (match (as-max-len? (append (get parent-ids current-parents) parent-id) u2)
      new-list (begin
        (map-set person-parents
          { child-id: child-id }
          { parent-ids: new-list }
        )
        true
      )
      false
    )
  )
)

(define-private (update-name-search (name (string-ascii 100)) (person-id uint))
  (let ((current-search (default-to { person-ids: (list) } (map-get? name-search { name-key: name }))))
    (match (as-max-len? (append (get person-ids current-search) person-id) u50)
      new-list (begin
        (map-set name-search
          { name-key: name }
          { person-ids: new-list }
        )
        true
      )
      false
    )
  )
)
