(impl-trait .trait-oracle.oracle)
(use-trait block-trait .trait-blockchain.blockchain)

;; constants
(define-constant ERR_NOT_AUTH (err u100))
;;

;; data vars
(define-data-var contract-owner principal contract-caller)


;; data maps
(define-map StxPriceHistory
  { height: uint }
  { updates: uint, price: uint }
)
;;

(define-read-only (get-price-at-height (height uint))
  (ok (default-to {updates: u0, price: u0} (map-get? StxPriceHistory {height: height} )))
)

;; public functions
(define-public (set-current-price (price uint))
    ;; caller check is done in add-price-at-height
    (let
        (
            (nextBlock (unwrap-panic (contract-call? .blockchain next-mining-block)))
        )
        (add-price-at-height (get height nextBlock) price)
    )
)

(define-public (add-price-at-height (height uint) (price uint))
    (begin 
        (asserts! (is-eq contract-caller tx-sender) ERR_NOT_AUTH)
        (let 
            (
                (currentMap (default-to {updates: u0, price: u0}  (map-get? StxPriceHistory {height: height } )))
                (lastUpdateCnt (get updates currentMap))
                (nextUpdateCnt (+ lastUpdateCnt u1))
                (numerator (if (is-eq lastUpdateCnt u0) price (+ (* (get price currentMap) lastUpdateCnt) price)))
                (new-price (/ numerator nextUpdateCnt) )
            )
            (asserts! (map-set StxPriceHistory {height: height }
                { updates: nextUpdateCnt, price: new-price }
            ) (err u101))
            (ok { updates: nextUpdateCnt, price: new-price })
        )
    )
)

;; Shouldn't be used normally.
(define-public (reset-price-at-height (height uint))
    (begin 
        (asserts! (is-eq contract-caller tx-sender) ERR_NOT_AUTH)
        (ok (map-set StxPriceHistory {height: height} {updates: u0, price: u0}))
    )
)
