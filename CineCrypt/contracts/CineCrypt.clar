;; CineCrypt Smart Contract 

;; Constants
(define-constant ERR-D1 (err u1))
(define-constant ERR-D2 (err u2))
(define-constant ERR-D3 (err u3))
(define-constant ERR-D4 (err u4))
(define-constant ERR-D5 (err u5))
(define-constant ERR-D6 (err u6))
(define-constant ERR-D7 (err u7))
(define-constant ERR-D8 (err u8))
(define-constant ERR-D9 (err u9))
(define-constant ERR-D10 (err u10))
(define-constant ERR-D11 (err u11))
(define-constant ERR-D12 (err u12))
(define-constant ERR-D13 (err u13))
(define-constant ERR-D14 (err u14))
(define-constant ERR-D15 (err u15))
(define-constant ERR-D16 (err u16))

;; Validation Ranges
(define-constant RANGE-X1 u52560)
(define-constant RANGE-X2 u144)
(define-constant RANGE-X3 u105120)
(define-constant TITLE-LEN-MIN u10)

;; Global State
(define-data-var cinecrypt-brand (string-ascii 50) "CineCrypt Smart Contract")
(define-data-var cinecrypt-id-seq uint u1)
(define-data-var cinecrypt-curator principal tx-sender)

(define-data-var cinecrypt-eval-delay uint u10000)
(define-data-var cinecrypt-min-stake uint u10)
(define-data-var cinecrypt-max-stake uint u1000000)

;; Data Maps
(define-map cinecrypt-projects
  { prj-id: uint }
  {
    ttl: (string-ascii 256),
    outcome: (optional bool),
    lock: uint,
    cutoff: uint,
    creator: principal
  }
)

(define-map cinecrypt-stakes
  { prj-id: uint, addr: principal }
  { amt: uint, pred: bool }
)

;; Private Validations
(define-private (chk-id (pid uint))
  (< pid (var-get cinecrypt-id-seq))
)

(define-private (chk-ttl (t (string-ascii 256)))
  (and 
    (>= (len t) TITLE-LEN-MIN)
    (<= (len t) u256)
  )
)

(define-private (chk-lock (d uint))
  (let ((blk (- d u0)))
    (and (>= blk RANGE-X2) (<= blk RANGE-X1))
  )
)

(define-private (chk-cutoff (d uint) (e uint))
  (let ((diff (- e d)))
    (and (> e d) (<= diff RANGE-X3))
  )
)

(define-private (chk-stake (v uint))
  (and (>= v (var-get cinecrypt-min-stake)) (<= v (var-get cinecrypt-max-stake)))
)

;; Public Functions

(define-public (cinecrypt-init (t (string-ascii 256)) (lock uint))
  (let
    (
      (pid (var-get cinecrypt-id-seq))
      (cutoff (+ lock (var-get cinecrypt-eval-delay)))
    )
    (asserts! (chk-ttl t) ERR-D16)
    (asserts! (chk-lock lock) ERR-D1)
    (asserts! (chk-cutoff lock cutoff) ERR-D16)

    (map-set cinecrypt-projects
      { prj-id: pid }
      {
        ttl: t,
        outcome: none,
        lock: lock,
        cutoff: cutoff,
        creator: tx-sender
      }
    )
    (var-set cinecrypt-id-seq (+ pid u1))
    (ok pid)
  )
)

(define-public (cinecrypt-stake (pid uint) (pred bool) (amt uint))
  (let
    (
      (curr (default-to { amt: u0, pred: false } 
                        (map-get? cinecrypt-stakes { prj-id: pid, addr: tx-sender })))
    )
    (asserts! (chk-id pid) ERR-D5)
    (asserts! (chk-stake amt) ERR-D4)
    (let
      (
        (proj (unwrap! (map-get? cinecrypt-projects { prj-id: pid }) ERR-D5))
        (new-amt (+ amt (get amt curr)))
      )
      (asserts! (<= new-amt (var-get cinecrypt-max-stake)) ERR-D15)
      (asserts! (is-none (get outcome proj)) ERR-D3)
      (asserts! (>= (stx-get-balance tx-sender) amt) ERR-D6)

      (map-set cinecrypt-stakes
        { prj-id: pid, addr: tx-sender }
        { amt: new-amt, pred: pred }
      )
      (stx-transfer? amt tx-sender (as-contract tx-sender))
    )
  )
)

(define-public (set-cinecrypt-eval-delay (new-val uint))
  (begin
    (asserts! (is-eq tx-sender (var-get cinecrypt-curator)) ERR-D13)
    (asserts! (and (>= new-val u1000) (<= new-val u52560)) ERR-D16)
    (ok (var-set cinecrypt-eval-delay new-val))
  )
)

(define-public (set-cinecrypt-min-stake (min-val uint))
  (begin
    (asserts! (is-eq tx-sender (var-get cinecrypt-curator)) ERR-D13)
    (asserts! (and 
      (>= min-val u1)
      (< min-val (var-get cinecrypt-max-stake))
      (<= min-val u1000000)
    ) ERR-D16)
    (ok (var-set cinecrypt-min-stake min-val))
  )
)

(define-public (set-cinecrypt-max-stake (max-val uint))
  (begin
    (asserts! (is-eq tx-sender (var-get cinecrypt-curator)) ERR-D13)
    (asserts! (and 
      (> max-val (var-get cinecrypt-min-stake))
      (<= max-val u1000000000000)
      (>= max-val u1000)
    ) ERR-D16)
    (ok (var-set cinecrypt-max-stake max-val))
  )
)

(define-read-only (get-cinecrypt-curator)
  (ok (var-get cinecrypt-curator))
)

(define-public (transfer-cinecrypt-curator (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get cinecrypt-curator)) ERR-D13)
    (asserts! (not (is-eq new-owner (var-get cinecrypt-curator))) ERR-D16)
    (ok (var-set cinecrypt-curator new-owner))
  )
)
