;;; mu4e-compat.el --- Compatibility aliases for mu4e -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2024 TEC
;;
;; Author: TEC <contact@tecosaur.net>
;; Maintainer: TEC <contact@tecosaur.net>
;; Created: April 11, 2024
;; Modified: April 11, 2024
;; Version: 0.1.0
;; Keywords: mail
;; Homepage: https://github.com/tecosaur/mu4e-compat
;; Package-Requires: ((emacs "26.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  Usually packages handle their own compatibility with
;;  define-obsolete-{function,variable}-alias, but not mu4e.
;;  Mu4e's too good for that.
;;
;;; Code:

(require 'mu4e)

(defconst mu4e-compat-mu-version
  (let ((ver (version-to-list mu4e-mu-version)))
    (list (car ver) (cadr ver)))
  "The (MAJOR MINOR) mu4e version.")

(defvar mu4e-compat--needlessly-breaking-renames-sofar)

(defvar mu4e-compat--needlessly-breaking-renames-future)

(cond
 ((version-list-< mu4e-compat-mu-version '(1 0))
  (user-error "Your mu4e version is older than mu4e-compat supports"))
 ((equal mu4e-compat-mu-version '(1 0))
  (load "mu4e-compat-1.0"))
 ((equal mu4e-compat-mu-version '(1 8))
  (load "mu4e-compat-1.8"))
 ((equal mu4e-compat-mu-version '(1 10))
  (load "mu4e-compat-1.10"))
 ((equal mu4e-compat-mu-version '(1 12))
  (load "mu4e-compat-1.12"))
 ((version-list-< '(1 12) mu4e-compat-mu-version)
  (user-error "Your mu4e version is newer than mu4e-compat supports")))

(defun mu4e-compat-define-aliases-backwards ()
  "Define backwards-compatible aliases, back to Mu4e 1.8."
  (dolist (rename-set mu4e-compat--needlessly-breaking-renames-sofar)
    (let ((version (car rename-set)))
      (dolist (rename (cdr rename-set))
        (let ((old (car rename))
              (new (cdr rename))
              (val (symbol-value (cdr rename))))
          (cond
           ((functionp val)
            (define-obsolete-function-alias old new version))
           ((facep val)
            (define-obsolete-variable-alias old new version))
           ((boundp val)
            (define-obsolete-variable-alias old new version))))))))

(defun mu4e-compat-define-aliases-forwards ()
  "Define backwards-compatible aliases, forwards to Mu4e 1.12."
  (dolist (rename-set mu4e-compat--needlessly-breaking-renames-future)
    (let ((version (car rename-set)))
      (dolist (rename (cdr rename-set))
        (let ((old (car rename))
              (new (cdr rename))
              (val (symbol-value (car rename))))
          (cond
           ((functionp val)
            (define-obsolete-function-alias old new version))
           ((facep val)
            (define-obsolete-variable-alias old new version))
           ((boundp val)
            (define-obsolete-variable-alias old new version))))))))

(provide 'mu4e-compat)
;;; mu4e-compat.el ends here