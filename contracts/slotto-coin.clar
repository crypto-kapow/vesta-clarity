
;; title: counter
;; version:
;; summary:
;; description:

;; traits
(impl-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait) 

;; token definitions
;; 100M cap w/ 6 decimals defined below
(define-fungible-token slotto-coin u100000000000000)

(define-read-only (get-decimals)
	(ok u6)
)
;;

;; Error responses
(define-constant ERR_NOT_TOKEN_OWNER (err u101))


;; constants
(define-constant ERR_NOT_OWNER (err u1))
;;

;; data vars
(define-data-var contract-owner principal contract-caller)
;;


;; data maps
;;

;; public functions
;;(define-public (set-contract-owner (new-owner principal)) 
;;    (begin 
;;      (try! (is-contract-owner)) 
;;      (ok (var-set contract-owner new-owner)) 
;;    )
;;)
;;

;; read only functions
(define-read-only (is-contract-owner) 
  (ok (asserts! (is-eq contract-caller (var-get contract-owner))
   ERR_NOT_OWNER)) 
) 

(define-read-only (get-contract-owner) (ok (var-get contract-owner)) ) 
;;

;; private functions
;;


;; `transfer` function to move tokens around from `contract-caller` to someone else
(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
	(begin
		(asserts! (is-eq contract-caller sender) ERR_NOT_TOKEN_OWNER)
		(try! (ft-transfer? slotto-coin amount sender recipient))
		(match memo to-print (print to-print) 0x)
		(ok true)
	)
)

(define-read-only (get-name)
	(ok "Slotto")
)

(define-read-only (get-symbol)
	(ok "SLOT")
)

(define-read-only (get-balance (who principal))
	(ok (ft-get-balance slotto-coin who))
)

(define-read-only (get-total-supply)
	(ok (ft-get-supply slotto-coin))
)

(define-read-only (get-token-uri)
	(ok none)
)

;; owner-only function to `mint` some `amount` of tokens to `recipient`
(define-public (mint (amount uint) (recipient principal))
	(begin
		;; double check this logic works and doesn't allow a public call directly (not from a contract)
		(asserts! (is-eq contract-caller (var-get contract-owner)) ERR_NOT_OWNER)
		(ft-mint? slotto-coin amount recipient)
	)
)