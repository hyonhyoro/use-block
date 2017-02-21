;;; use-block.el --- Integrate Emacs Lisp source code blocks in Org mode into the form of use-package -*- lexical-binding: t; -*-

;; Copyright (c) 2017 Kazuho Sakoda

;; Author: Kazuho Sakoda <hyonhyoro.kazuho@gmail.com>
;; Maintainer: Kazuho Sakoda <hyonhyoro.kazuho@gmail.com>
;; Version: 0.1.0
;; Keywords: config, init, org
;; Package-Requires: ((emacs "24.3") (dash "2.13.0"))
;; URL: https://github.com/hyonhyoro/use-block

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:
(require 'ob-core)
(require 'dash)


(defun use-block--make-package-object (&optional alist)
  "Make a package object from ALIST.
To get ALIST, use `use-block--get-alist'.
To put a package, use `use-block--put-package'."
  (let ((get (lambda () alist))
        (put (lambda (name prop sequence)
               (let ((old-plist (cdr (assoc name alist))))
                 (if old-plist
                     (plist-put old-plist
                                prop
                                (append (plist-get old-plist prop) sequence))
                   (push `(,name . (,prop ,sequence)) alist))))))
    (lambda (m) (cond ((eq m 'get) get)
                      ((eq m 'put) put)))))


(defun use-block--get-alist (obj)
  "Get an alist from OBJ."
  (funcall (funcall obj 'get)))


(defun use-block--put-package (obj name prop sequence)
  "Put a package to OBJ.
NAME is the string of the package.
PROP is a symbol and SEQUENCE is a list of expressions."
  (funcall (funcall obj 'put) name prop sequence))


(defun use-block--find-header-arg (args)
  "Return a header argument whose car is :pre-init or :post-init from ARGS."
  (-last #'(lambda (arg) (memq (car arg) '(:pre-init :post-init)))
         args))


(defun use-block--expand-use-package (form plist)
  "Expand use-package FORM according to PLIST.
The property of PLIST is :pre-init and :post-init.
The value of PLIST is a list of expressions."
  (let ((pre-init (plist-get plist :pre-init))
        (post-init (plist-get plist :post-init)))
    `(,@form :init ,@pre-init :config ,@post-init)))


(defun use-block--expand-body (body obj)
  "Expand BODY according to OBJ.
If BODY is the form of the use-package, expand it by
`use-block--expand-use-package'."
  (if (and (eq 'use-package (car body)) (<= 2 (length body)))
      (let* ((name (format "%s" (cadr body)))
             (plist (cdr (assoc name (use-block--get-alist obj)))))
        (use-block--expand-use-package body plist))
    body))


;;;###autoload
(defun use-block-extract-file (file &optional target-file)
  "Extract the bodies of source code blocks in FILE.
Source code blocks are extracted with `use-block--expand-body'.
Optional argument TARGET-FILE can be used to specify a default export file
for all source code blocks."
  (interactive "fFile to tangle: \nP")
  (let ((body-list nil)
        (package-object (use-block--make-package-object)))
    (org-babel-map-src-blocks file
      (let ((lang (org-no-properties lang))
            (src-block (car (read-from-string (concat "(" body ")"))))
            (header-args (org-babel-parse-header-arguments header-args)))
        (when (and (string= "emacs-lisp" lang)
                   (not (string= "no" (cdr (assq :tangle header-args)))))
          (let ((header-arg (use-block--find-header-arg header-args)))
            (if header-arg
                (use-block--put-package package-object
                                        (cdr header-arg)
                                        (car header-arg)
                                        src-block)
              (dolist (body src-block) (push body body-list)))))))
    (with-temp-file (or target-file
                        (concat (file-name-sans-extension file) ".el"))
      (dolist (body (reverse body-list))
        (insert (concat "\n"
                        (pp-to-string (use-block--expand-body body package-object))))))))


;;;###autoload
(defun use-block-load-file (file &optional compile)
  "Load Emacs Lisp source code blocks in the Org-mode FILE.
This function exports the source code using `use-block-extract-file'
and then loads the resulting file using `load-file'.
If COMPILE is Non-nil, byte-compile the exported Emacs Lisp file
before it's loaded."
  (interactive "fFile to load: \nP")
  (let* ((base-name (file-name-sans-extension file))
         (exported-file (concat base-name ".el")))
    (unless (and (file-exists-p exported-file)
                 (file-newer-than-file-p exported-file file))
      (use-block-extract-file file exported-file))
    (message "%s %s" (if compile
                         (progn (byte-compile-file exported-file 'load)
                                "Compiled and loaded")
                       (progn (load-file exported-file) "Loaded"))
             exported-file)))


(provide 'use-block)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; use-block.el ends here
