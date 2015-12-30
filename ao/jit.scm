(define-module (ao jit))

(use-modules (system foreign))
(use-modules (ice-9 common-list))
(use-modules (ao lib) (ao ptr))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; This is our local store.  When populated, it's an opaque pointer to a
;; Store object (created in C++ with make-store)
(define store #nil)

;; Converts the given argument to a token
;; Based on argument type, the following behavior occurs
;; - A number is converted to constant
;; - A symbol and further arguments is converted to an operator
(define-public (make-token a . args)
    "Creates a token in the global store.
A token is returned without changes
A number is converted to a constant
A symbol and further arguments are converted to an operation"
    (if (= 0 (length args))
        (cond ((tagged-ptr? 'Token a) a)
              ((number? a) (token-const store a))
              (else (error "Failed to construct token" a)))
        (token-op store a (map make-token args))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-public (interval? i)
    "Check to see if the given argument is a valid Interval"
    (and (pair? i) (not (list? i)) (number? (car i)) (number? (cdr i))))

(define-public (wrap-tree t)
    " Wraps a tagged tree pointer in a callable interface "
    (lambda (x y z) ;; Generic evaluator that dispatches based on argument type
        (cond ((every interval? (list x y z))
                    (tree-eval-interval t x y z))
              ((every number? (list x y z))
                    (tree-eval-double t x y z))
              (else (error "Input arguments are of invalid types")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-public (jit f)
    "Compile an arithmetic lambda function to a bare tree pointer"
    (set! store (make-store))
    (let* ((x (token-x store))
           (y (token-y store))
           (z (token-z store))
           (root (make-token (f x y z)))
           (out (make-tree store root)))
       (set! store #nil)
       out))
