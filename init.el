;; -*- lexical-binding: t; -*-

;;; Code:
(add-hook 'elpaca-after-init-hook
          (lambda ()
            (message "Emacs loaded in %s with %d garbage collections."
                     (format "%.2f seconds"
                             (float-time
                              (time-subtract (current-time) before-init-time)))
                     gcs-done)))

;; Uncomment for profiling
;; (profiler-start 'cpu+mem)
;; (add-hook 'elpaca-after-init-hook (lambda () (profiler-stop) (profiler-report)))

;; (require 'elp)
;; (with-eval-after-load file
;;   (elp-instrument-package file))
;; (add-hook 'elpaca-after-init-hook
;;           (lambda () (elp-results) (elp-restore-package (intern file))))

(setq initial-buffer-choice t) ;;*scratch*

(setq-default tab-width 2
              c-basic-offset 2
              kill-whole-line t
              indent-tabs-mode nil
              fill-column 119
              require-final-newline t)

;;; Lockfiles unfortunately cause more pain than benefit
(setq create-lockfiles nil)

(save-place-mode t)                       ; Open file on the last visited position
(fset 'yes-or-no-p 'y-or-n-p)             ; y-or-n-p makes answering questions faster
(global-hl-line-mode t)                   ; Enable cursor line highlighting
(delete-selection-mode 1)                 ; Selected text will be overwritten when you start typing
(electric-pair-mode 1)                    ; auto parens in pairs
(global-auto-revert-mode t)               ; Auto-update buffer if file has changed on disk
(savehist-mode t)                         ; Persist history over Emacs restarts. Vertico sorts by history position.

(add-hook 'prog-mode-hook                 ; Show line numbers in programming modes
          (if (and (fboundp 'display-line-numbers-mode) (display-graphic-p))
              #'display-line-numbers-mode
            #'linum-mode))

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
(set-keyboard-coding-system 'utf-8)

;; start the initial frame maximized
(add-to-list 'initial-frame-alist '(fullscreen . maximized))

;; start every frame maximized
(add-to-list 'default-frame-alist '(fullscreen . maximized))

(defvar elpaca-installer-version 0.1)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil
                              :files (:defaults (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(when-let ((repo  (expand-file-name "repos/elpaca/" elpaca-directory))
           (build (expand-file-name "elpaca/" elpaca-builds-directory))
           (order (cdr elpaca-order))
           ((add-to-list 'load-path (if (file-exists-p build) build repo)))
           ((not (file-exists-p repo))))
  (condition-case-unless-debug err
      (if-let ((buffer (pop-to-buffer-same-window "*elpaca-installer*"))
               ((zerop (call-process "git" nil buffer t "clone"
                                     (plist-get order :repo) repo)))
               (default-directory repo)
               ((zerop (call-process "git" nil buffer t "checkout"
                                     (or (plist-get order :ref) "--"))))
               (emacs (concat invocation-directory invocation-name))
               ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                     "--eval" "(byte-recompile-directory \".\" 0 'force)"))))
          (progn (require 'elpaca)
                 (elpaca-generate-autoloads "elpaca" repo)
                 (kill-buffer buffer))
        (error "%s" (with-current-buffer buffer (buffer-string))))
    ((error) (warn "%s" err) (delete-directory repo 'recursive))))
(require 'elpaca-autoloads)
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

(defmacro use-feature (name &rest args)
  "Like `use-package' but accounting for asynchronous installation.
NAME and ARGS are in `use-package'."
  (declare (indent defun))
  `(elpaca nil (use-package ,name
                 :ensure nil
                 ,@args)))

;; Install use-package support
(elpaca elpaca-use-package
  ;; Enable :elpaca use-package keyword.
  (elpaca-use-package-mode)
  ;; Assume :elpaca t unless otherwise specified.
  (setq elpaca-use-package-by-default t))

;; Block until current queue processed.
(elpaca-wait)

(if debug-on-error
    (setq use-package-verbose t
          use-package-expand-minimally nil
          use-package-compute-statistics t)
  (setq use-package-verbose nil
        use-package-expand-minimally t))

(defun +terminal ()
  "Set the terimnal coding system."
  (unless (display-graphic-p)
    (set-terminal-coding-system 'utf-8)))

(add-hook 'server-after-make-frame-hook #'+terminal)

;; A few more useful configurations...
(use-feature emacs
  :elpaca nil
  :init
  ;; Add prompt indicator to `completing-read-multiple'.
  ;; We display [CRM<separator>], e.g., [CRM,] if the separator is a comma.
  (defun crm-indicator (args)
    (cons (format "[CRM%s] %s"
                  (replace-regexp-in-string
                   "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
                   crm-separator)
                  (car args))
          (cdr args)))
  (advice-add #'completing-read-multiple :filter-args #'crm-indicator)

  ;; Do not allow the cursor in the minibuffer prompt
  (setq minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

  ;; Emacs 28: Hide commands in M-x which do not work in the current mode.
  ;; Vertico commands are hidden in normal buffers.
  ;; (setq read-extended-command-predicate
  ;;       #'command-completion-default-include-p)

  ;; Enable recursive minibuffers
  (setq enable-recursive-minibuffers t))

(use-package doom-themes
  :demand t
  :config
  (load-theme 'doom-one t))

(use-package tree-sitter
  :config
  ;; activate tree-sitter on any buffer containing code for which it has a parser available
  (global-tree-sitter-mode)
  ;; you can easily see the difference tree-sitter-hl-mode makes for python, ts or tsx
  ;; by switching on and off
  (add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode))

(use-package tree-sitter-langs
  :after tree-sitter)

(use-package all-the-icons
  :demand t)

(use-package which-key
  :demand t
  :init
  (setq which-key-enable-extended-define-key t)
  :config
  (which-key-mode)
  :custom
  (which-key-side-window-location 'bottom)
  (which-key-sort-order 'which-key-key-order-alpha)
  (which-key-side-window-max-width 0.33)
  (which-key-idle-delay 0.5)
  :diminish which-key-mode)

(use-package doom-modeline
  :defer 2
  :config
  (column-number-mode 1)
  (doom-modeline-mode)
  :custom
  (doom-modeline-icon t "Show icons in the modeline"))

(use-package lsp-mode
  :init
  ;; set prefix for lsp-command-keymap (few alternatives - "C-l", "C-c l")
  (setq lsp-keymap-prefix "C-c l")
  :hook (;; replace XXX-mode with concrete major-mode(e. g. python-mode)
         (c-mode . lsp-deferred)
         ;; if you want which-key integration
         (lsp-mode . lsp-enable-which-key-integration))
  :commands (lsp lsp-deferred))

(use-package yaml-mode
  :defer t
  :hook (yaml-mode . lsp-deferred))

(use-package exec-path-from-shell
  :if (memq window-system '(mac ns))
  :init
  (setq exec-path-from-shell-arguments '("-l"))
  :config
  (exec-path-from-shell-initialize))

(use-package flycheck
  :init (global-flycheck-mode))

(use-package rg
  :defer t)

;; Git related packages
(use-package git-gutter
  :defer t
  :custom (git-gutter:update-interval 0.25)
  :bind ("C-x g =" . git-gutter:popup-hunk)
  ("C-x g p" . git-gutter:previous-hunk)
  ("C-x g n" . git-gutter:next-hunk)
  :init (global-git-gutter-mode t)
  (setq git-gutter:modified-sign "~"
	git-gutter:added-sign "+"
	git-gutter:deleted-sign "-"))

;; Enable vertico
(use-package vertico
  :init
  (vertico-mode)

  ;; Different scroll margin
  ;; (setq vertico-scroll-margin 0)

  ;; Show more candidates
  ;; (setq vertico-count 20)

  ;; Grow and shrink the Vertico minibuffer
  ;; (setq vertico-resize t)

  ;; Optionally enable cycling for `vertico-next' and `vertico-previous'.
  ;; (setq vertico-cycle t)
  )

;; Optionally use the `orderless' completion style.
(use-package orderless
  :init
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (setq orderless-style-dispatchers '(+orderless-consult-dispatch orderless-affix-dispatch)
  ;;       orderless-component-separator #'orderless-escapable-split-on-space)
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

;; Organizing
(use-package projectile
  ;; Convenient organization and commands
  :demand t
  :config (projectile-mode 1)
  :bind (:map projectile-mode-map
              ("C-c p" . projectile-command-map)))

(use-package perspective
  :bind
  (("C-x C-b" . persp-list-buffers) ; or use a nicer switcher, see below
   ("C-x b" . persp-switch-to-buffer*)
   ("C-x k" . persp-kill-buffer*))
  :custom
  (persp-mode-prefix-key (kbd "C-c TAB"))  ; pick your own prefix key here
  :init
  (persp-mode))

(defun lsp-install-save-hooks ()
  "Setup lsp-related hooks."
  (add-hook 'before-save-hook #'lsp-format-buffer t t))
(add-hook 'c-mode-hook #'lsp-install-save-hooks)

(provide 'init)
;;; init.el ends here
