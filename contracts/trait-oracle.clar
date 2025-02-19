(define-trait oracle
    (
        (get-price-at-height (uint) (response {updates: uint, price: uint} uint))
        (set-current-price (uint) (response {updates: uint, price: uint} uint))
        (add-price-at-height (uint uint) (response {updates: uint, price: uint} uint))
        (reset-price-at-height (uint) (response bool uint))

;;        (add-allowed-updater (principal) (response {updater: principal} uint))
;;        (remove-allowed-updater (principal) (response bool uint))

;;        (set-owner (principal) (response bool uint))
    )
)