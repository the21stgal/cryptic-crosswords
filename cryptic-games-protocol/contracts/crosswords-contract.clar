;; Cryptic Crosswords Smart Contract - v1

;; Error codes
(define-constant ERR-NO-PERMISSION (err u100))
(define-constant ERR-PUZZLE-NOT-FOUND (err u101))
(define-constant ERR-PUZZLE-CLOSED (err u103))
(define-constant ERR-CLUE-NOT-FOUND (err u104))
(define-constant ERR-PUZZLE-INACTIVE (err u107))
(define-constant ERR-SYSTEM-LOCKED (err u113))
(define-constant ERR-INVALID-INPUT (err u116))

;; Puzzle status
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-COMPLETE u2)
(define-constant STATUS-ARCHIVED u3)

;; Data maps
(define-map puzzles
  { puzzle-id: uint }
  {
    title: (string-ascii 50),
    description: (string-ascii 255),
    creator: principal,
    status: uint,
    clue-count: uint,
    start-block: uint,
    end-block: uint,
    difficulty: uint
  }
)

(define-map puzzle-clues
  { puzzle-id: uint, clue-id: uint }
  {
    text: (string-ascii 100),
    answer: (string-ascii 20),
    points: uint,
    across: bool,
    position: uint
  }
)

;; Variables
(define-data-var puzzle-counter uint u0)
(define-data-var contract-manager principal tx-sender)
(define-data-var system-locked bool false)

;; Access control
(define-private (is-manager)
  (is-eq tx-sender (var-get contract-manager))
)

;; Check if system is unlocked
(define-private (is-unlocked)
  (not (var-get system-locked))
)

;; Set contract manager
(define-public (set-manager (new-manager principal))
  (begin
    (asserts! (is-manager) ERR-NO-PERMISSION)
    (ok (var-set contract-manager new-manager))
  )
)

;; Set system lock state
(define-public (set-lock (lock-state bool))
  (begin
    (asserts! (is-manager) ERR-NO-PERMISSION)
    (ok (var-set system-locked lock-state))
  )
)

;; Create a new puzzle
(define-public (create-puzzle 
    (title (string-ascii 50)) 
    (description (string-ascii 255)) 
    (start-block uint)
    (end-block uint)
    (difficulty uint)
  )
  (let (
    (puzzle-id (+ (var-get puzzle-counter) u1))
  )
    (asserts! (is-manager) ERR-NO-PERMISSION)
    (asserts! (is-unlocked) ERR-SYSTEM-LOCKED)
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> (len description) u0) ERR-INVALID-INPUT)
    (asserts! (< start-block end-block) ERR-INVALID-INPUT)
    (asserts! (>= start-block block-height) ERR-INVALID-INPUT)
    (asserts! (and (>= difficulty u1) (<= difficulty u10)) ERR-INVALID-INPUT)
    
    (map-set puzzles
      { puzzle-id: puzzle-id }
      {
        title: title,
        description: description,
        creator: tx-sender,
        status: STATUS-ACTIVE,
        clue-count: u0,
        start-block: start-block,
        end-block: end-block,
        difficulty: difficulty
      }
    )
    
    (var-set puzzle-counter puzzle-id)
    (ok puzzle-id)
  )
)

;; Add a clue to a puzzle
(define-public (add-puzzle-clue
    (puzzle-id uint)
    (clue-text (string-ascii 100))
    (answer (string-ascii 20))
    (points uint)
    (across bool)
    (position uint)
  )
  (let (
    (puzzle (unwrap! (map-get? puzzles { puzzle-id: puzzle-id }) ERR-PUZZLE-NOT-FOUND))
    (clue-id (get clue-count puzzle))
  )
    (asserts! (is-manager) ERR-NO-PERMISSION)
    (asserts! (is-unlocked) ERR-SYSTEM-LOCKED)
    (asserts! (is-eq (get status puzzle) STATUS-ACTIVE) ERR-PUZZLE-INACTIVE)
    (asserts! (> (len clue-text) u0) ERR-INVALID-INPUT)
    (asserts! (> (len answer) u0) ERR-INVALID-INPUT)
    (asserts! (> points u0) ERR-INVALID-INPUT)
    
    ;; Add the clue
    (map-set puzzle-clues
      { puzzle-id: puzzle-id, clue-id: clue-id }
      {
        text: clue-text,
        answer: answer,
        points: points,
        across: across,
        position: position
      }
    )
    
    ;; Update clue count
    (map-set puzzles
      { puzzle-id: puzzle-id }
      (merge puzzle {
        clue-count: (+ clue-id u1)
      })
    )
    
    (ok clue-id)
  )
)

;; End an active puzzle
(define-public (end-puzzle (puzzle-id uint))
  (let (
    (puzzle (unwrap! (map-get? puzzles { puzzle-id: puzzle-id }) ERR-PUZZLE-NOT-FOUND))
  )
    (asserts! (is-manager) ERR-NO-PERMISSION)
    (asserts! (is-unlocked) ERR-SYSTEM-LOCKED)
    (asserts! (is-eq (get status puzzle) STATUS-ACTIVE) ERR-PUZZLE-INACTIVE)
    
    ;; Update puzzle status
    (map-set puzzles
      { puzzle-id: puzzle-id }
      (merge puzzle {
        status: STATUS-COMPLETE
      })
    )
    
    (ok true)
  )
)

;; Archive a completed puzzle
(define-public (archive-puzzle (puzzle-id uint))
  (let (
    (puzzle (unwrap! (map-get? puzzles { puzzle-id: puzzle-id }) ERR-PUZZLE-NOT-FOUND))
  )
    (asserts! (is-manager) ERR-NO-PERMISSION)
    (asserts! (is-unlocked) ERR-SYSTEM-LOCKED)
    (asserts! (is-eq (get status puzzle) STATUS-COMPLETE) ERR-PUZZLE-INACTIVE)
    
    ;; Update puzzle status
    (map-set puzzles
      { puzzle-id: puzzle-id }
      (merge puzzle {
        status: STATUS-ARCHIVED
      })
    )
    
    (ok true)
  )
)

;; Get puzzle details
(define-read-only (get-puzzle (puzzle-id uint))
  (map-get? puzzles { puzzle-id: puzzle-id })
)

;; Get clue details
(define-read-only (get-clue (puzzle-id uint) (clue-id uint))
  (map-get? puzzle-clues { puzzle-id: puzzle-id, clue-id: clue-id })
)

;; Helper function to convert string to lowercase (simplified)
(define-private (to-lowercase (s (string-ascii 20)))
  ;; In a real contract, this would do actual case conversion
  ;; This is just a placeholder that returns the original string
  s
)

;; Initialize contract
(begin
  (var-set contract-manager tx-sender)
  (var-set system-locked false)
)