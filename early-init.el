;;; early-init.el --- Emacs pre package.el & GUI configuration -*- lexical-binding: t; -*-
;;; Code:

(setq package-enable-at-startup nil)
(setq inhibit-default-init nil)

(setq native-comp-async-report-warnings-errors nil)

(defvar default-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 1)

(defun +gc-after-focus-change ()
  "Run GC when frame loses focus."
  (run-with-idle-timer
   5 nil
   (lambda () (unless (frame-focus-state) (garbage-collect)))))

(defun +reset-init-values ()
  (run-with-idle-timer
   1 nil
   (lambda ()
     (setq file-name-handler-alist default-file-name-handler-alist
           gc-cons-percentage 0.1
           gc-cons-threshold 100000000)
     (message "gc-cons-threshold & file-name-handler-alist restored")
     (when (boundp 'after-focus-change-function)
       (add-function :after after-focus-change-function #'+gc-after-focus-change)))))

(with-eval-after-load 'elpaca
  (add-hook 'elpaca-after-init-hook '+reset-init-values))

(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

(setq frame-inhibit-implied-resize t)

(push '(font . "MesloLGS Nerd Font Mono 18") default-frame-alist)
(set-face-font 'default "MesloLGS Nerd Font Mono 18")
(set-face-font 'variable-pitch "Helvetica Neue 18")
(copy-face 'default 'fixed-pitch)

(advice-add #'x-apply-session-resources :override #'ignore)

(setq ring-bell-function #'ignore
      inhibit-startup-screen t)

(provide 'early-init)
;;; early-init.el ends here
