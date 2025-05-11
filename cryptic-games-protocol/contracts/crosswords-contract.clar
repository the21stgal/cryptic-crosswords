;; Cryptic Crosswords Smart Contract - v2
;; Added team functionality and puzzle participation

;; Error codes
(define-constant ERR-NO-PERMISSION (err u100))
(define-constant ERR-PUZZLE-NOT-FOUND (err u101))
(define-constant ERR-TEAM-EXISTS (err u102))
(define-constant ERR-PUZZLE-CLOSED (err u103))
(define-constant ERR-CLUE-NOT-FOUND (err u104))
(define-constant ERR-ANSWER-SUBMITTED (err u105))
(define-constant ERR-WRONG-ANSWER (err u106))
(define-constant ERR-PUZZLE-INACTIVE (err u107))
(define-constant ERR-NOT-TEAM-MEMBER (err u108))
(define-constant ERR-SYSTEM-LOCKED (err u113))
(define-constant ERR-TEAM-NOT-FOUND (err u114))
(define-constant ERR-ALREADY-TEAM-MEMBER (err u115))
(define-constant ERR-INVALID-INPUT (err u116))
(define-constant ERR-TEAM-FULL (err u112))

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
    difficulty: uint,
    teams-completed: uint
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

(define-map teams
  { team-id: uint }
  {
    name: (string-ascii 30),
    founder: principal,
    member-count: uint,
    puzzles-attempted: uint,
    puzzles-completed: uint,
    total-points: uint
  }
)

(define-map team-members
  { team-id: uint, player: principal }
  {
    joined-at: uint,
    clues-solved: uint,
    points-contributed: uint
  }
)

(define-map team-puzzle-progress
  { team-id: uint, puzzle-id: uint }
  {
    started-at: uint,
    completed-at: (optional uint),
    clues-solved: uint,
    total-points: uint,
    completion-time: (optional uint)
  }
)

(define-map team-clue-solutions
  { team-id: uint, puzzle-id: uint, clue-id: uint }
  {
    solution: (string-ascii 20),
    solved-by: principal,
    solved-at: uint,
    attempt-count: uint,
    points-earned: uint
  }
)

;; Variables
(define-data-var puzzle-counter uint u0)
(define-data-var team-counter uint u0)
(define-data-var contract-manager principal tx-sender)
(define-data-var system-locked bool false)
(define-data-var max-team-size uint u5) ;; Maximum members per team

;; Access control
(define-private (is-manager)
  (is-eq tx-sender (var-get contract-manager))
)

(define-private (is-team-founder (team-id uint))
  (match (map-get? teams { team-id: team-id })
    team (is-eq tx-sender (get founder team))
    false
  )
)

(define-private (is-team-member (team-id uint))
  (is-some (map-get? team-members { team-id: team-id, player: tx-sender }))
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
        difficulty: difficulty,
        teams-completed: u0
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

;; Create a new team
(define-public (create-team (name (string-ascii 30)))
  (let (
    (team-id (+ (var-get team-counter) u1))
  )
    (asserts! (is-unlocked) ERR-SYSTEM-LOCKED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    
    ;; Create the team
    (map-set teams
      { team-id: team-id }
      {
        name: name,
        founder: tx-sender,
        member-count: u1,
        puzzles-attempted: u0,
        puzzles-completed: u0,
        total-points: u0
      }
    )
    
    ;; Add founder as a member
    (map-set team-members
      { team-id: team-id, player: tx-sender }
      {
        joined-at: block-height,
        clues-solved: u0,
        points-contributed: u0
      }
    )
    
    (var-set team-counter team-id)
    (ok team-id)
  )
)

;; Join a team
(define-public (join-team (team-id uint))
  (let (
    (team (unwrap! (map-get? teams { team-id: team-id }) ERR-TEAM-NOT-FOUND))
    (member-count (get member-count team))
  )
    (asserts! (is-unlocked) ERR-SYSTEM-LOCKED)
    (asserts! (< member-count (var-get max-team-size)) ERR-TEAM-FULL)
    (asserts! (is-none (map-get? team-members { team-id: team-id, player: tx-sender })) ERR-ALREADY-TEAM-MEMBER)
    
    ;; Add player to team
    (map-set team-members
      { team-id: team-id, player: tx-sender }
      {
        joined-at: block-height,
        clues-solved: u0,
        points-contributed: u0
      }
    )
    
    ;; Update team member count
    (map-set teams
      { team-id: team-id }
      (merge team {
        member-count: (+ member-count u1)
      })
    )
    
    (ok true)
  )
)

;; Start a puzzle for a team
(define-public (start-puzzle (team-id uint) (puzzle-id uint))
  (let (
    (team (unwrap! (map-get? teams { team-id: team-id }) ERR-TEAM-NOT-FOUND))
    (puzzle (unwrap! (map-get? puzzles { puzzle-id: puzzle-id }) ERR-PUZZLE-NOT-FOUND))
  )
    (asserts! (is-unlocked) ERR-SYSTEM-LOCKED)
    (asserts! (is-team-member team-id) ERR-NOT-TEAM-MEMBER)
    (asserts! (is-eq (get status puzzle) STATUS-ACTIVE) ERR-PUZZLE-INACTIVE)
    (asserts! (>= block-height (get start-block puzzle)) ERR-PUZZLE-INACTIVE)
    (asserts! (< block-height (get end-block puzzle)) ERR-PUZZLE-CLOSED)
    (asserts! (is-none (map-get? team-puzzle-progress { team-id: team-id, puzzle-id: puzzle-id })) ERR-PUZZLE-INACTIVE)
    
    ;; Set up team progress
    (map-set team-puzzle-progress
      { team-id: team-id, puzzle-id: puzzle-id }
      {
        started-at: block-height,
        completed-at: none,
        clues-solved: u0,
        total-points: u0,
        completion-time: none
      }
    )
    
    ;; Update team stats
    (map-set teams
      { team-id: team-id }
      (merge team {
        puzzles-attempted: (+ (get puzzles-attempted team) u1)
      })
    )
    
    (ok true)
  )
)

;; Submit a solution for a clue
(define-public (submit-solution (team-id uint) (puzzle-id uint) (clue-id uint) (solution (string-ascii 20)))
  (let (
    (team (unwrap! (map-get? teams { team-id: team-id }) ERR-TEAM-NOT-FOUND))
    (puzzle (unwrap! (map-get? puzzles { puzzle-id: puzzle-id }) ERR-PUZZLE-NOT-FOUND))
    (clue (unwrap! (map-get? puzzle-clues { puzzle-id: puzzle-id, clue-id: clue-id }) ERR-CLUE-NOT-FOUND))
    (progress (unwrap! (map-get? team-puzzle-progress { team-id: team-id, puzzle-id: puzzle-id }) ERR-PUZZLE-INACTIVE))
    (member-data (unwrap! (map-get? team-members { team-id: team-id, player: tx-sender }) ERR-NOT-TEAM-MEMBER))
    (solution-record (map-get? team-clue-solutions { team-id: team-id, puzzle-id: puzzle-id, clue-id: clue-id }))
  )
    (asserts! (is-unlocked) ERR-SYSTEM-LOCKED)
    (asserts! (is-eq (get status puzzle) STATUS-ACTIVE) ERR-PUZZLE-INACTIVE)
    (asserts! (< block-height (get end-block puzzle)) ERR-PUZZLE-CLOSED)
    (asserts! (is-none (get completed-at progress)) ERR-PUZZLE-CLOSED)
    
    ;; Check if clue already solved
    (asserts! (or (is-none solution-record) 
                (not (get attempt-count (default-to { attempt-count: u0 } solution-record)))) 
              ERR-ANSWER-SUBMITTED)
    
    ;; Check if solution is correct
    (let (
      (is-correct (is-eq (to-lowercase solution) (to-lowercase (get answer clue))))
      (attempt-count (if (is-some solution-record) 
                       (get attempt-count (unwrap! solution-record { attempt-count: u0, solution: "", solved-by: tx-sender, solved-at: u0, points-earned: u0 }))
                       u0))
      ;; Points calculation - base points with penalties for attempts
      (points-earned (if is-correct
                       (- (get points clue) (* attempt-count u5))
                       u0))
    )
      ;; Update or create solution record
      (map-set team-clue-solutions
        { team-id: team-id, puzzle-id: puzzle-id, clue-id: clue-id }
        {
          solution: solution,
          solved-by: tx-sender,
          solved-at: block-height,
          attempt-count: (+ attempt-count u1),
          points-earned: (if is-correct points-earned u0)
        }
      )
      
      ;; If correct, update progress
      (if is-correct
        (begin
          ;; Update player stats
          (map-set team-members
            { team-id: team-id, player: tx-sender }
            {
              joined-at: (get joined-at member-data),
              clues-solved: (+ (get clues-solved member-data) u1),
              points-contributed: (+ (get points-contributed member-data) points-earned)
            }
          )
          
          ;; Update team progress
          (map-set team-puzzle-progress
            { team-id: team-id, puzzle-id: puzzle-id }
            {
              started-at: (get started-at progress),
              completed-at: (get completed-at progress),
              clues-solved: (+ (get clues-solved progress) u1),
              total-points: (+ (get total-points progress) points-earned),
              completion-time: (get completion-time progress)
            }
          )
          
          ;; Check if puzzle complete
          (if (is-eq (+ (get clues-solved progress) u1) (get clue-count puzzle))
            (complete-puzzle team-id puzzle-id)
            (ok points-earned)
          )
        )
        (ok u0)
      )
    )
  )
)

;; Helper function to complete a puzzle
(define-private (complete-puzzle (team-id uint) (puzzle-id uint))
  (let (
    (puzzle (unwrap! (map-get? puzzles { puzzle-id: puzzle-id }) ERR-PUZZLE-NOT-FOUND))
    (team (unwrap! (map-get? teams { team-id: team-id }) ERR-TEAM-NOT-FOUND))
    (progress (unwrap! (map-get? team-puzzle-progress { team-id: team-id, puzzle-id: puzzle-id }) ERR-PUZZLE-INACTIVE))
    (completion-time (- block-height (get started-at progress)))
  )
    ;; Update team progress
    (map-set team-puzzle-progress
      { team-id: team-id, puzzle-id: puzzle-id }
      {
        started-at: (get started-at progress),
        completed-at: (some block-height),
        clues-solved: (get clues-solved progress),
        total-points: (get total-points progress),
        completion-time: (some completion-time)
      }
    )
    
    ;; Update team stats
    (map-set teams
      { team-id: team-id }
      (merge team {
        puzzles-completed: (+ (get puzzles-completed team) u1),
        total-points: (+ (get total-points team) (get total-points progress))
      })
    )
    
    ;; Update puzzle stats
    (map-set puzzles
      { puzzle-id: puzzle-id }
      (merge puzzle {
        teams-completed: (+ (get teams-completed puzzle) u1)
      })
    )
    
    (ok (get total-points progress))
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

;; Calculate team's position on leaderboard (simplified)
(define-read-only (get-team-rank (puzzle-id uint) (team-id uint))
  (let (
    (team-progress (unwrap! (map-get? team-puzzle-progress { team-id: team-id, puzzle-id: puzzle-id }) ERR-PUZZLE-INACTIVE))
  )
    ;; In a real contract, this would be more complex, comparing against all teams
    ;; This is a simplified version
    (if (is-some (get completed-at team-progress))
      (ok u1)  ;; Placeholder rank
      (ok u0)  ;; Not completed
    )
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

;; Get team details
(define-read-only (get-team (team-id uint))
  (map-get? teams { team-id: team-id })
)

;; Get team progress on a puzzle
(define-read-only (get-team-progress (team-id uint) (puzzle-id uint))
  (map-get? team-puzzle-progress { team-id: team-id, puzzle-id: puzzle-id })
)

;; Get member details
(define-read-only (get-team-member (team-id uint) (player principal))
  (map-get? team-members { team-id: team-id, player: player })
)

;; Get clue solution status
(define-read-only (get-solution-status (team-id uint) (puzzle-id uint) (clue-id uint))
  (map-get? team-clue-solutions { team-id: team-id, puzzle-id: puzzle-id, clue-id: clue-id })
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
  (var-set max-team-size u5)
)