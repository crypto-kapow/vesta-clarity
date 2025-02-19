;; traits
;;

;; constants
(define-constant err-not-owner (err u10))

(define-constant ERR_UNAUTHORIZED (err u6000))
(define-constant ERR_INVALID_COMMITS (err u6007))
(define-constant ERR_NOT_ENOUGH_FUNDS (err u6008))
(define-constant ERR_ALREADY_MINED (err u6009))
(define-constant ERR_NO_MINER_DATA (err u6013))
(define-constant ERR_MINER_NOT_WINNER (err u6015))
(define-constant ERR_MINING_DISABLED (err u6016))

(define-constant ERR_MUST_MINE_WHOLE_STX (err u6020))
(define-constant ERR_ALREADY_CLAIMED (err u6022))
(define-constant ERR_INVALID_BLOCK (err u6023))
(define-constant ERR_FUTURE_BLOCK (err u6051))
(define-constant ERR_UNKNOWN (err u9999))

(define-constant DECIMALS u1000000)
;;

;; data vars
(define-data-var contract-owner principal tx-sender)

;; CHANGE THIS BEFORE GOING LIVE
(define-data-var conductor-principal principal 'STNHKEPYEPJ8ET55ZZ0M5A34J0R3N5FM2CMMMAZ6)

;; Set to 2 decimals
;;(define-data-var miner-pct uint u9000)
;;(define-data-var conductor-pct uint u0200)
;;(define-data-var backer-pct uint u0800)

;; mining setup
(define-data-var mining-enabled bool true)

;; data maps
(define-map Miners {height: uint, principal: principal} 
  {height: uint, principal: principal, commit: uint, start: uint, end: uint, winner: bool})

(define-map MiningStats
  { height: uint }
  { height: uint, miners: uint, commit: uint, coinReward: uint, stxReward: uint, claimed: bool }
)

(define-map DistributionSchedule uint 
  {
      miner-pct: uint,
      conductor-pct: uint,
      pool-pct: uint,
      coinbase-min: uint,
      coinbase-max: uint
  }
)


;;

;;;;;;;;;;;;;;;;;; MINING CALLS ;;;;;;;;;;;;;;;;;;

;; Entry point for mining. Takes a list of STX commits to mine over the next 'x' mining blocks
(define-public (pox-mine (start-height uint) (commits (list 48 uint)))
  (begin
    (asserts! (var-get mining-enabled) ERR_MINING_DISABLED)
    (asserts! (> (len commits) u0) ERR_INVALID_COMMITS) 
    (let
        (
          (next-block (unwrap-panic (contract-call? .blockchain next-mining-block)))
          (totalCommits (fold + commits u0))
        )
        (asserts! (>= start-height (get height next-block) ) ERR_ALREADY_MINED)
        (asserts! (<= (+ start-height (len commits)) (+ (get height next-block) u48)) ERR_INVALID_COMMITS) ;; Can't mine past 48 blacks no matter where you start mining from
        (asserts! (>= (stx-get-balance tx-sender) totalCommits) ERR_NOT_ENOUGH_FUNDS)
        (print {
            event: "pox-mine",
            sender: tx-sender,
            totalCommit: totalCommits,
            blocks: (len commits)
        })
        (try! (fold mine-block commits (ok {
            principal: tx-sender,
            height: start-height,
            totalCommit: u0,
        })))
        (let 
            (
              (dist (try! (get-distribution-amounts start-height)))
              (miner-amount (/ (* (unwrap! (get miner-pct dist) (err u1111)) totalCommits) u10000))
              (conductor-fee (/ (* (unwrap! (get conductor-pct dist) (err u1111)) totalCommits) u10000))
              (pool-reward (/ (* (unwrap! (get pool-pct dist) (err u1111)) totalCommits) u10000))
            )
            (try! (stx-transfer? conductor-fee tx-sender (var-get conductor-principal)))
            (try! (stx-transfer? miner-amount tx-sender .mining))
            (try! (stx-transfer? pool-reward tx-sender .pool))
            ;; TODO: Does not add to pool for next cycle if this list stradles 2..
            (try! (as-contract (contract-call? .pool add-to-pool start-height pool-reward)))
            
            (ok (print {
                event: "Mining Commit Complete",
                conductor: conductor-fee,
                miners: miner-amount,
                pool: pool-reward
              })
            )
        )
    )
  )
)

;; Called from pox-mine for each item in the list. Figures out the next burn-block to be mined in and records the given amount of STX to it.
(define-private (mine-block (commit uint)
  (return (response
    { principal: principal, height: uint, totalCommit: uint }
    uint
  )))
  (let
    (
      (okReturn (try! return))
      (height (get height okReturn))
    )
    (print {
        event: "fn mine-block",
        commit: commit,
        height: height
    })
    (asserts! (> commit u0) ERR_INVALID_COMMITS)
    (asserts! (is-eq (mod commit DECIMALS) u0) ERR_MUST_MINE_WHOLE_STX)
    (let
      (
        (blockStats (get-mining-stats height))
        (currentCommit (get commit blockStats))
        ;;(nextMinerNumber (get-total-commits height))
      )
      
      (map-set MiningStats
        { height: height }
        { height: height, miners: (+ (get miners blockStats) u1), commit: (+ currentCommit commit), coinReward: u0, stxReward: u0, claimed: false }
      )
      (asserts! (map-insert Miners
        { height: height, principal: tx-sender }
        {
          height: height,
          principal: tx-sender,
          commit: commit,
          start: currentCommit,
          end: (+ currentCommit commit),
          winner: false
        }
      ) ERR_ALREADY_MINED)
    )
    ;; Should find next block dynamically (instead of by a hard-coded amount) for when we set the burn-blocks-per-mining value to take effect at a specific height in the future
    (ok (merge okReturn
      { height: (+ height u1), totalCommit: (+ (get totalCommit okReturn) commit) }
    ))
  )
)

(define-read-only (miner-selection (height uint))
  (let
    (
      (block (unwrap! (map-get? MiningStats {height: height}) ERR_INVALID_BLOCK))
      (burn-hash (unwrap! (get-burn-block-info? header-hash height) ERR_FUTURE_BLOCK))
      (vrf (unwrap! (contract-call? .vrf get-random-uint-at-height height) ERR_INVALID_BLOCK))
      (sel (mod vrf (get commit block)))
    )
    (print {
      event: "Miner Selection",
      height: height,
      hash: burn-hash,
      vrf: vrf,
      sel: sel
    })
    (ok {hash: burn-hash, vrf: vrf, sel: sel, miner-cnt: (get miners block), commits: (get commit block) } )
  )
)

(define-public (claim (height uint))
    (let
      (
        (block (unwrap! (map-get? MiningStats {height: height}) ERR_INVALID_BLOCK))
        (burn-hash (unwrap! (get-burn-block-info? header-hash height) ERR_INVALID_BLOCK))
        (miner-selection (try! (miner-selection height)))
        (vrf-num (get sel miner-selection))
        (my-commit (unwrap! (map-get? Miners {height: height, principal: tx-sender} ) ERR_NO_MINER_DATA))
        (my-start (get start my-commit))
        (my-end (get end my-commit))
        (reward (try! (get-reward-at-height height)))
      )
      (print {event: "claim", my-start: my-start, my-end: my-end, sel: miner-selection})
      (asserts! (not (unwrap-panic (contract-call? .blockchain is-future-block height))) ERR_FUTURE_BLOCK)
      (asserts! (get claimed block) ERR_ALREADY_CLAIMED)
      (asserts! (and (>= vrf-num my-start) (<= vrf-num my-end)) ERR_MINER_NOT_WINNER)


      (print {event: "claim-success"})
      (ok (asserts! (map-set MiningStats {height: height} { height: height, miners: (get miners block), commit: (get commit block), stxReward: (get stxReward reward), coinReward: (get coinReward reward), claimed: true } ) ERR_UNKNOWN))
      ;; transfer STX and COIN
    )
)

;;;;;;;;;;;;;;;;; END MINING CALLS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;; BEGIN MINING STATS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Get the total commits to a block / Get the next starting number for a miner in the given block
(define-read-only (get-mining-stats (height uint))
  (default-to { height: height, miners: u0, commit: u0, coinReward: u0, stxReward: u0, claimed: false }
    (map-get? MiningStats { height: height })
  )
)
;;;;;;;;;;;;;;;;; END MINING STATS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;; BEGIN SETTINGS ;;;;;;;;;;;;;;;;;;;;;;;
;; Distribution settings
(define-constant cycle-length u1000)
(define-read-only (get-contract-owner) (ok (var-get contract-owner)) ) 
(define-read-only (get-conductor-address) (ok (var-get conductor-principal)) ) 

(define-read-only (is-contract-owner)
    (ok (asserts! (is-eq contract-caller (var-get contract-owner)) err-not-owner))
) 

(define-public (set-contract-owner (new-owner principal)) 
    (begin 
        (try! (is-contract-owner)) 
        (ok (var-set contract-owner new-owner)) 
    )
)

(define-public (set-conductor-address (new-address principal))
    (begin 
        (try! (is-contract-owner))
        (ok (var-set conductor-principal new-address))
    )
)

(define-public (update-mining-distributions (height uint) (miner uint) (pool uint) (conductor uint) (coinbase-min uint) (coinbase-max uint))
    ( begin
        (try! (is-contract-owner))
        (asserts! (is-eq (mod height cycle-length) u0 ) (err u1113))
        (asserts! (is-eq (+ miner pool conductor) u10000) (err u50)) ;; xxx.yy% for each
        (asserts! (>= height (get height (unwrap-panic (contract-call? .blockchain next-mining-block)))) (err u1113)) ;; must be in the future
        (map-set DistributionSchedule height {
            miner-pct: miner,
            pool-pct: pool,
            conductor-pct: conductor,
            coinbase-min: coinbase-min,
            coinbase-max: coinbase-max
          }
        )
        (ok (map-get? DistributionSchedule height))
    )
)
(update-mining-distributions u0 u9000 u0800 u0200 u1000 u10000)
(update-mining-distributions cycle-length u9000 u0900 u0100 u900 u9000)
(update-mining-distributions (* cycle-length u2) u9000 u0900 u0100 u800 u8000)
(update-mining-distributions (* cycle-length u3) u9000 u0900 u0100 u700 u7000)
(update-mining-distributions (* cycle-length u4) u9000 u0900 u0100 u600 u6000)
(update-mining-distributions (* cycle-length u5) u9000 u0900 u0100 u500 u5000)
(update-mining-distributions (* cycle-length u6) u9000 u0900 u0100 u400 u4000)

(define-read-only (get-cycle-start-block (height uint))
  (ok (- height (mod height cycle-length) ) )
)

(define-read-only (get-distribution-amounts (height uint)) 
  (let (
      (cycle-start (unwrap-panic (get-cycle-start-block height)))
      (resp (map-get? DistributionSchedule cycle-start))
    )
    (asserts! (is-some resp) (err u1112))
    (ok resp)
  )
)
;;;;;;;;;;;;;;;;; END SETTINGS ;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;; BEGIN WEB HELPERS ;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Read only functions that fetch lots of data to reduce calls. Need to determine if a separate API is better

;; Get 12 blocks of info at a time
(define-read-only (get-next-blocks (height uint))
    (let (
        (block-list (list 
            { height: height, miners: u0, commit: u0, coinReward: u0, stxReward: u0, claimed: false }
            { height: (+ height u1), miners: u0, commit: u0, coinReward: u0, stxReward: u0, claimed: false }
            { height: (+ height u2), miners: u0, commit: u0, coinReward: u0, stxReward: u0, claimed: false }
            { height: (+ height u3), miners: u0, commit: u0, coinReward: u0, stxReward: u0, claimed: false }
            { height: (+ height u4), miners: u0, commit: u0, coinReward: u0, stxReward: u0, claimed: false }
            { height: (+ height u5), miners: u0, commit: u0, coinReward: u0, stxReward: u0, claimed: false }
            { height: (+ height u6), miners: u0, commit: u0, coinReward: u0, stxReward: u0, claimed: false }
            { height: (+ height u7), miners: u0, commit: u0, coinReward: u0, stxReward: u0, claimed: false }
            { height: (+ height u8), miners: u0, commit: u0, coinReward: u0, stxReward: u0, claimed: false }
            { height: (+ height u9), miners: u0, commit: u0, coinReward: u0, stxReward: u0, claimed: false }
            { height: (+ height u10), miners: u0, commit: u0, coinReward: u0, stxReward: u0, claimed: false }
            { height: (+ height u11), miners: u0, commit: u0, coinReward: u0, stxReward: u0, claimed: false }
            ))
        )
        (map map-block-fields block-list)
    )
)

(define-read-only (map-block-fields (input {miners: uint, height: uint, commit: uint, coinReward: uint, stxReward: uint, claimed: bool}) )
    (get-mining-stats (get height input))
)

;; Get 12 blocks of miner information for the given principal
(define-read-only (get-commits (sender principal) (height uint))
  (let (
      (block-list (list 
            {height: height, principal: sender, commit: u0, start: u0, end: u0, winner: false}
            {height: (+ height u1), principal: sender, commit: u0, start: u0, end: u0, winner: false}
            {height: (+ height u2), principal: sender, commit: u0, start: u0, end: u0, winner: false}
            {height: (+ height u3), principal: sender, commit: u0, start: u0, end: u0, winner: false}
            {height: (+ height u4), principal: sender, commit: u0, start: u0, end: u0, winner: false}
            {height: (+ height u5), principal: sender, commit: u0, start: u0, end: u0, winner: false}
            {height: (+ height u6), principal: sender, commit: u0, start: u0, end: u0, winner: false}
            {height: (+ height u7), principal: sender, commit: u0, start: u0, end: u0, winner: false}
            {height: (+ height u8), principal: sender, commit: u0, start: u0, end: u0, winner: false}
            {height: (+ height u9), principal: sender, commit: u0, start: u0, end: u0, winner: false}
            {height: (+ height u10), principal: sender, commit: u0, start: u0, end: u0, winner: false}
            {height: (+ height u11), principal: sender, commit: u0, start: u0, end: u0, winner: false}
          ))
      )
      (map map-mining-commits block-list)
  )
)

(define-read-only (map-mining-commits (input {height: uint, principal: principal, commit: uint, start: uint, end: uint, winner: bool}) )
  (default-to { height: (get height input), principal: (get principal input), commit: u0, start: u0, end: u0, winner: false }
    (map-get? Miners { principal: (get principal input), height: (get height input) })
  )
)
;;;;;;;;;;;;;;;;; END WEB HELPERS ;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;; BEGIN COIN CALCULATION / REWARDS / INFORMATION ;;;;;;;


;; Determine the reward based on price, block height and STX mining commit
(define-read-only (get-reward-at-height (height uint))
  (let (
      (dist (try! (get-distribution-amounts height)))
      (commits (get commit (get-mining-stats height)) )
      (coin-price 
        (get price (unwrap! (contract-call? .slotto-oracle get-price-at-height height) (err u1111))))
  )
  (asserts! (> coin-price u0) (err u1111))
  (let (
        (stx-discount u80)
        (max-coin (unwrap! (get coinbase-max dist) (err u1112)))
        (min-coin (unwrap! (get coinbase-min dist) (err u1112)))
        ;; Simplified linear reduction of coin base on commits. To update with better logic
        
        (coin-amnt (- max-coin (* commits stx-discount))) 
        (amount (if (>= coin-amnt min-coin) coin-amnt min-coin))
        (stx-pct (unwrap! (get miner-pct dist) (err u1112)) )
      )
      (ok {
        coinReward: coin-amnt,
        stxReward: (* commits stx-pct),
        coinMin: min-coin,
        coinMax: max-coin,
        price: coin-price,
        }
      )
    )
  )
)
;;;;;;;;;;;;;;;;; END COIN CALCULATION / REWARDS / INFORMATION ;;;;;;;
