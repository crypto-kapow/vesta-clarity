
;; title: pool
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
(define-constant ERR_NOT_ALLOWED (err u1))
(define-constant contract-owner tx-sender)

;;

;; data vars
;; This should be a map to allow updates, but unsure how to set a default on deploy (or an initial tx)
(define-data-var allowed-caller principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.miner)
;;

;; data maps
(define-map pool-rewards uint uint)
(define-map authorized-callers principal bool)
(map-insert authorized-callers .miner true)
;;

;; public functions
(define-public (add-to-pool (height uint) (amount uint) )
    ;; TODO: Authorized contract check
    (begin 
        (asserts! (is-allowed) ERR_NOT_ALLOWED)
        (asserts! (and (>= amount u0) (>= height u0)) (err u2))
        (map-set pool-rewards height (+ (default-to u0 (map-get? pool-rewards height)) amount))
        (ok (print {
            event: "add-to-pool",
            amount: amount,
            height: height
        }))
    )
)

(define-public (allow-contract-calls-from (address principal))
    (begin 
        (asserts! (is-allowed) ERR_NOT_ALLOWED)
        (ok true) 
        ;;(map-insert allowed-list address true)
    )
)
;;

;; read only functions
(define-read-only (get-pool-at-height (height uint))
    (
        ok (default-to u0 (map-get? pool-rewards height))
    )
)
;;

;; private functions

;; UPDATE this to allow a map of contract callers?
(define-private (is-allowed)
    (default-to false (map-get? authorized-callers tx-sender))
)
;;