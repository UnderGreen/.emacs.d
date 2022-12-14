;;; For performance
(setq gc-cons-threshold 100000000)
(setq read-process-output-max (* 1024 1024)) ;; 1mb


(add-hook 'after-init-hook #'(lambda ()
                               ;; restore after startup
                               (setq gc-cons-threshold 800000)))

;;; Disable menu-bar, tool-bar, and scroll-bar.
(if (fboundp 'menu-bar-mode)
    (menu-bar-mode -1))
(if (fboundp 'tool-bar-mode)
    (tool-bar-mode -1))
(if (fboundp 'scroll-bar-mode)
    (scroll-bar-mode -1))

;;; Fix this bug:
;;; https://www.reddit.com/r/emacs/comments/cueoug/the_failed_to_download_gnu_archive_is_a_pretty/
(when (version< emacs-version "26.3")
  (setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3"))

;; start the initial frame maximized
(add-to-list 'initial-frame-alist '(fullscreen . maximized))

;; start every frame maximized
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;;; Setup straight
(setq-default straight-repository-branch "master"
              straight-fix-org t
              straight-fix-flycheck t
              straight-use-package-by-default t
              straight-check-for-modifications '(check-on-save find-when-checking))
(setq vc-follow-symlinks t)
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)

(use-package use-package-ensure-system-package)

;;; Help keeping .emacs.d clean!
(use-package no-littering)

(require 'recentf)
(add-to-list 'recentf-exclude no-littering-var-directory)
(add-to-list 'recentf-exclude no-littering-etc-directory)

(setq auto-save-file-name-transforms
	`((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))

(setq custom-file (no-littering-expand-etc-file-name "custom.el"))

;;; Useful Defaults
(setq inhibit-startup-screen t)           ; Disable startup screen
(setq initial-scratch-message "")         ; Make *scratch* buffer blank
(setq-default frame-title-format '("%b")) ; Make window title the buffer name
(setq ring-bell-function 'ignore)         ; Disable bell sound
(global-hl-line-mode t)                   ; Enable cursor line highlighting
(save-place-mode t)                       ; Open file on the last visited position
(fset 'yes-or-no-p 'y-or-n-p)             ; y-or-n-p makes answering questions faster
(show-paren-mode 1)                       ; Show closing parens by default
(setq linum-format "%4d ")                ; Line number format
(delete-selection-mode 1)                 ; Selected text will be overwritten when you start typing
(global-auto-revert-mode t)               ; Auto-update buffer if file has changed on disk
(add-hook 'before-save-hook
	  'delete-trailing-whitespace)    ; Delete trailing whitespace on save
(add-hook 'prog-mode-hook                 ; Show line numbers in programming modes
          (if (and (fboundp 'display-line-numbers-mode) (display-graphic-p))
              #'display-line-numbers-mode
            #'linum-mode))
(setq kill-whole-line t)

;;; Put Emacs auto-save and backup files to /tmp/ or C:/Temp/
(defconst emacs-tmp-dir (expand-file-name (format "emacs%d" (user-uid)) temporary-file-directory))
(setq
   backup-by-copying t                                        ; Avoid symlinks
   delete-old-versions t
   kept-new-versions 6
   kept-old-versions 2
   version-control t
   backup-directory-alist `((".*" . ,emacs-tmp-dir)))


;; utf-8 everywhere
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)

(electric-pair-mode 1) ; auto parens in pairs

(setq-default
 ;; these settings still should be set on a per language basis, this is just a general default
 indent-tabs-mode nil ; spaces > tabs
 tab-width 4 ; tab is 4 spaces
 fill-column 119

 ;; better security
 gnutls-verify-error t
 gnutls-min-prime-bits 2048

 mouse-yank-at-point t
 save-interprogram-paste-before-kill t
 apropos-do-all t
 require-final-newline t
 ediff-window-setup-function 'ediff-setup-windows-plain

 ;; the most reliable tramp setup I have found (used at work every day...)
 tramp-default-method "ssh"
 tramp-copy-size-limit nil
 tramp-use-ssh-controlmaster-options nil

 ;; I recommend the following ~/.ssh/config settings be used with the tramp settings in this cfg:
 ;; Host *
 ;; ForwardAgent yes
 ;; AddKeysToAgent yes
 ;; ControlMaster auto
 ;; ControlPath ~/.ssh/master-%r@%h:%p
 ;; ControlPersist yes
 ;; ServerAliveInterval 10
 ;; ServerAliveCountMax 10

 ring-bell-function 'ignore ; be quiet

 browse-url-browser-function 'eww-browse-url ; use a text browser --great for clicking documentation links
 )

;;; Lockfiles unfortunately cause more pain than benefit
(setq create-lockfiles nil)

;;; Modeline
(use-package doom-modeline
  :init
  (doom-modeline-mode 1)
  :config
  (setq doom-modeline-height 15))

;;; Theme
(use-package doom-themes
  :custom
  (doom-dracula-brighter-modeline t)
  (doom-dracula-brighter-comments nil)
  :custom-face
  (selectrum-current-candidate ((t (:background "#44475a" :weight bold :foreground "#ff79c6"))))
  (prescient-primary-highlight ((t :foreground "#ffb86c")))
  (prescient-secondary-highlight ((t :foreground "#0189cc")))
  :config
  (load-theme 'doom-dracula t)
  (doom-themes-visual-bell-config))

(use-package all-the-icons)

;;; Fonts
(set-face-attribute 'default nil :font "MesloLGS Nerd Font Mono" :height 190)
(let ((faces '(mode-line
               mode-line-buffer-id
               mode-line-emphasis
               mode-line-highlight
               mode-line-inactive)))
  (mapc
   (lambda (face) (set-face-attribute face nil :font "MesloLGS Nerd Font Mono" :height 170))
   faces))

;; Enable rich annotations using the Marginalia package
(use-package marginalia
  ;; Either bind `marginalia-cycle' globally or only in the minibuffer
  :bind (("M-A" . marginalia-cycle)
         :map minibuffer-local-map
         ("M-A" . marginalia-cycle))

  ;; The :init configuration is always executed (Not lazy!)
  :init

  ;; Must be in the :init section of use-package such that the mode gets
  ;; enabled right away. Note that this forces loading the package.
  (marginalia-mode))

;;; Blackout
(use-package blackout)

(use-package undo-tree                    ; Enable undo-tree, sane undo/redo behavior
  :blackout
  :init (global-undo-tree-mode)
  :config (setq undo-tree-auto-save-history nil))

(use-package tree-sitter
  :config
  ;; activate tree-sitter on any buffer containing code for which it has a parser available
  (global-tree-sitter-mode)
  ;; you can easily see the difference tree-sitter-hl-mode makes for python, ts or tsx
  ;; by switching on and off
  (add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode))

(use-package tree-sitter-langs
  :after tree-sitter)

(use-package lsp-mode
  :init
  ;; set prefix for lsp-command-keymap (few alternatives - "C-l", "C-c l")
  (setq lsp-keymap-prefix "C-c l")
  :hook (;; replace XXX-mode with concrete major-mode(e. g. python-mode)
         (javascript-mode . lsp-deferred)
         ;; if you want which-key integration
         (lsp-mode . lsp-enable-which-key-integration))
  :commands lsp lsp-deferred)

;; optional if you want which-key integration
(use-package which-key
  :blackout
  :config
  (which-key-mode))

(use-package typescript-mode
  :after tree-sitter
  :config
  ;; we choose this instead of tsx-mode so that eglot can automatically figure out language for server
  ;; see https://github.com/joaotavora/eglot/issues/624 and https://github.com/joaotavora/eglot#handling-quirky-servers
  (define-derived-mode typescriptreact-mode typescript-mode
    "TypeScript TSX")

  ;; use our derived mode for tsx files
  (add-to-list 'auto-mode-alist '("\\.tsx?\\'" . typescriptreact-mode))
  ;; by default, typescript-mode is mapped to the treesitter typescript parser
  ;; use our derived mode to map both .tsx AND .ts -> typescriptreact-mode -> treesitter tsx
  (add-to-list 'tree-sitter-major-mode-language-alist '(typescriptreact-mode . tsx)))

(use-package yaml-mode
  :defer t
  :hook (yaml-mode . lsp-deferred))

(use-package terraform-mode
  :defer t
  :hook (terraform-mode . terraform-format-on-save-mode))

(use-package go-mode
  :defer t
  :hook (go-mode . lsp-deferred))

(use-package lsp-docker
  :config
  (defvar lsp-docker-client-packages
    '(lsp-clients lsp-go))
  (setq lsp-docker-client-configs
        '((:server-id gopls :docker-server-id gopls-docker :server-command "gopls")
          ))
  (lsp-docker-init-clients
   :path-mappings '(("~/go/src/github.com/gravitational/gravity" . "/projects"))
   :client-packages lsp-docker-client-packages
   :client-configs lsp-docker-client-configs))

(use-package exec-path-from-shell
  :if (memq window-system '(mac ns))
  :init
  (setq exec-path-from-shell-arguments '("-l"))
  :config
  (exec-path-from-shell-initialize))

(use-package magit)

(use-package selectrum
  :init
  (selectrum-mode t)
  :config
  (setq prescient-completion-highlight-matches t))

(use-package selectrum-prescient
  :init
  ;; to make sorting and filtering more intelligent
  (selectrum-prescient-mode t)

  ;; to save your command history on disk, so the sorting gets more
  ;; intelligent over time
  (prescient-persist-mode t))

;;;;; ctrlf
;; single-buffer text search in Emacs
;; [[https://github.com/raxod502/ctrlf#usage][ctrlf]]
(use-package ctrlf
  :straight t
  :init (ctrlf-mode +1))

(use-package groovy-mode)

(use-package rg
  :ensure-system-package
  (rg . ripgrep))

(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-cycle t)
  :init
  (global-corfu-mode))

(setq completion-cycle-threshold 3)
(setq tab-always-indent 'complete)
(setq read-extended-command-predicate
  #'command-completion-default-include-p)
