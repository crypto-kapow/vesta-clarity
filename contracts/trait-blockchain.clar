(define-trait blockchain
    (
        (next-mining-block () (response {height: uint, burnBlock: uint} uint) )
        (burn-height-for-block (uint) (response uint uint) )
        (is-future-block (uint) (response bool uint))
    )
)