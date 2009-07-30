#!/Users/taro/mosh/mosh
;/usr/local/bin/mosh
(import (rnrs)
        (prefix (mosh cgi) cgi:)
        (mosh)
        (only (srfi :13) string-pad)
        (srfi :2)
        (only (srfi :1) last)
        (memcached))

(include "template/header.scm")
(include "template/article.scm")
(include "template/footer.scm")

(define (make-article-no num)
  (define max-digit 6)
  (string-append "article-" (string-pad (number->string num) max-digit #\0)))

(define max-article-no (make-article-no 999999))
(define min-article-no (make-article-no 0))
(define article-num-page (number->string 3))

(let-values (([get-parameter get-request-method] (cgi:init)))
  (cgi:header)
  (let* ([conn (memcached-connect "localhost" "11211")]
         [next-article-no (or (memcached-get conn "next-article-no") 1)])

;;         (memcached-set! conn "bbs1" 0 0 '((name . "higepon")
;;                                           (body . "例が載っているが、z は mpz_init(z) と初期化しておく必要がある。ML でも指摘されているのだけどマニュアルが不親切なので注意。")))
;;         (memcached-set! conn "bbs2" 0 0 '((name . "higepon")
;;                                           (body . "hello2")))

    (display header)

    ;; Post
    (and-let* ([(eq? 'POST (get-request-method))]
               [name (get-parameter "name")]
               [body (get-parameter "body")])
      (memcached-set! conn (make-article-no next-article-no)
                      0 0 `((name . ,(cgi:decode name))
                            (body . ,(cgi:decode body))))
      ;; ToDo: incr protocol
      (memcached-set! conn "next-article-no" 0 0 (+ next-article-no 1)))

    (let* ([from-article-no (or (get-parameter "from-ano") min-article-no)]
           [to-article-no (or (get-parameter "to-ano") max-article-no)]
           [article* (memcached-gets conn "mio:range-search" from-article-no to-article-no article-num-page "desc")]
           [first-article (if (null? article*) #f (car article*))]
           [last-article (if (null? article*) #f (last article*))])
      (for-each
       (lambda (article)
         (format #t  t-article
                 (cgi:escape (assoc-ref (cdr article) 'name))
                 (car article)
                 (cgi:escape (assoc-ref (cdr article) 'body))))
       article*)
      (format #t footer
              (string-append (car first-article))
              article-num-page
              (string-append (car last-article))
              article-num-page))))
;; #| apache
;; Listen 8003
;; <VirtualHost *:8003>
;;     DocumentRoot /Users/taro/higepon/mio/example/
;;     AllowEncodedSlashes On
;;     <Directory "/Users/taro/higepon/mio/example/">
;;         DirectoryIndex bbs.scm
;;         Options Indexes FollowSymLinks
;;         AllowOverride None
;;         <FilesMatch ".scm$">
;;         SetHandler cgi-script
;;         </FilesMatch>
;;         Options ExecCGI
;;         Order allow,deny
;;         Allow from all
;;     </Directory>
;;     ErrorLog  /var/log/apache2/bbs.error_log
;;     CustomLog /var/log/apache2/bbs.access_log combined env=!nolog
;; </VirtualHost>
;; #|
