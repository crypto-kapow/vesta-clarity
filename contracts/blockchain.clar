(impl-trait .trait-blockchain.blockchain)

(define-constant mining-start-block u170)
(define-constant burn-blocks-per-mining u6) ;; every 6 BTC blocks ~1 hour

(define-read-only (get-mining-start-block) ;; has tests
  mining-start-block
  ;; should this return the burn-blocks-per-mining amount too? 
  ;; That or a separate function
)

;; get the current block information
(define-read-only (next-mining-block) ;; has tests
  (if (< burn-block-height mining-start-block) (ok {height: u0, burnBlock: mining-start-block}) ;; if mining hasn't started yet, return block 0
    (let (
      (burn-height burn-block-height)
      (next-height (/ (- burn-height mining-start-block) burn-blocks-per-mining))
      (next-burn (+ burn-height (- burn-blocks-per-mining (mod (- burn-height mining-start-block) burn-blocks-per-mining))) )
    )
        (ok {
          height: (+ next-height u1), 
          burnBlock: next-burn
        }
        )
    )
  )
)

;; Get the BTC burn height for a specific coin block
(define-read-only (burn-height-for-block (height uint)) ;; has tests
  (ok (+ mining-start-block (* height burn-blocks-per-mining)))
)

;; Check if a block is in the future (false - already been mined)
(define-read-only (is-future-block (height uint)) ;; has tests
  (ok (<= burn-block-height (unwrap-panic (burn-height-for-block height))))
)