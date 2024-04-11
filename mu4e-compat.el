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

(defun mu4e-compat-define-aliases-backwards (&optional oldest)
  "Define backwards-compatible aliases, back to Mu4e version OLDEST.
OLDEST can be a \"MAJOR.MINOR\" version string, or unset, in which case
aliases will be defined for all older versions."
  (dolist (rename-set mu4e-compat--needlessly-breaking-renames-sofar)
    (let ((version (car rename-set)))
      (when (or (not oldest)
                (version<= oldest version))
        (dolist (rename (cdr rename-set))
          (let ((old (car rename))
                (new (cdr rename)))
            (cond
             ((fboundp new)
              (define-obsolete-function-alias old new version))
             ((facep (and (boundp new) (symbol-value new)))
              (define-obsolete-face-alias old new version))
             ((boundp new)
              (define-obsolete-variable-alias old new version)))))))))

(defun mu4e-compat-define-aliases-forwards (&optional newest)
  "Define forwards-compatible aliases, up to Mu4e version NEWEST.
NEWEST can be a \"MAJOR.MINOR\" version string, or unset, in which case
aliases will be defined for all newer versions."
  (dolist (rename-set mu4e-compat--needlessly-breaking-renames-future)
    (let ((version (car rename-set)))
      (when (or (not newest)
                (version<= version newest))
        (dolist (rename (cdr rename-set))
          (let ((old (car rename))
                (new (cdr rename))
                (val (symbol-value (car rename))))
            (cond
             ((fboundp old)
              (defalias new old nil)
              (make-obsolete old new version))
             ((facep (and (boundp old) (symbol-value old)))
              (put new 'face-alias old)
              (put old 'obsolete-face (purecopy version)))
             ((boundp old)
              (defvaralias new old nil)
              (dolist (prop '(saved-value saved-variable-comment))
                (and (get old prop)
                     (null (get new prop))
                     (put new prop (get old prop))))
              (make-obsolete-variable old new version)))))))))

(provide 'mu4e-compat)
;;; mu4e-compat.el ends here
