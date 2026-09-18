;;; init.el --- Shared personal defaults -*- lexical-binding: t; -*-

;; The Nix wrapper supplies load-path; load lazy commands/mode associations
;; explicitly because package.el startup activation is disabled.
(require 'magit-autoloads)
(require 'markdown-mode-autoloads)
(require 'nix-mode-autoloads)
(require 'unfill-autoloads)

;; Editing and display preferences retained from the original dotemacs.
(setq create-lockfiles nil
      auto-save-timeout 2000
      make-backup-files nil
      select-enable-clipboard t
      inhibit-startup-screen t
      mark-even-if-inactive t
      frame-background-mode 'dark)
(setq-default truncate-lines t
              indent-tabs-mode nil
              c-basic-offset 4)
(global-auto-revert-mode 1)
(column-number-mode 1)
(transient-mark-mode 1)
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(menu-bar-mode -1)
(when (fboundp 'set-scroll-bar-mode) (set-scroll-bar-mode 'right))

;; Frame defaults also apply to frames created later with emacsclient.
(dolist (setting '((background-color . "black")
                   (foreground-color . "gray85")
                   (cursor-color . "red3")
                   (mouse-color . "white")))
  (add-to-list 'default-frame-alist setting))
(custom-set-faces
 '(default ((t (:background "black" :foreground "gray85"))))
 '(cursor ((t (:background "red3"))))
 '(font-lock-builtin-face ((t (:foreground "cyan" :weight bold))))
 '(font-lock-comment-face ((t (:foreground "LightPink"))))
 '(font-lock-constant-face ((t (:foreground "SpringGreen"))))
 '(font-lock-doc-face ((t (:foreground "SpringGreen"))))
 '(font-lock-function-name-face ((t (:foreground "wheat3"))))
 '(font-lock-keyword-face ((t (:foreground "SkyBlue" :weight bold))))
 '(font-lock-preprocessor-face ((t (:foreground "SkyBlue"))))
 '(font-lock-string-face ((t (:foreground "SpringGreen"))))
 '(font-lock-type-face ((t (:foreground "orange1"))))
 '(font-lock-variable-name-face ((t (:foreground "yellow"))))
 '(font-lock-warning-face ((t (:foreground "DarkOrange")))))

;; Standard Emacs completion with a vertical UI and richer navigation.
(require 'vertico)
(require 'orderless)
(require 'marginalia)
(require 'consult)
(setq completion-styles '(orderless basic)
      completion-category-defaults nil
      completion-category-overrides '((file (styles basic partial-completion)))
      recentf-max-saved-items 200)
(vertico-mode 1)
(marginalia-mode 1)
(savehist-mode 1)
(recentf-mode 1)
(global-set-key (kbd "C-x C-f") #'find-file)
(global-set-key (kbd "C-x b") #'consult-buffer)
(global-set-key (kbd "C-x C-r") #'consult-recent-file)
(global-set-key (kbd "C-c f") #'consult-find)
(global-set-key (kbd "C-c g") #'consult-ripgrep)
;; Built-in project.el supplies C-x p f (project files) and C-x p p (projects).
(require 'project)

(global-set-key (kbd "RET") #'newline-and-indent)
(global-set-key (kbd "C-c h") #'windmove-left)
(global-set-key (kbd "C-c l") #'windmove-right)
(global-set-key (kbd "C-c k") #'windmove-up)
(global-set-key (kbd "C-c j") #'windmove-down)
(global-set-key (kbd "C-c b") #'browse-url-at-point)
(global-set-key (kbd "C-x g") #'magit-status)

(defun bmillare-insert-date ()
  "Insert the current date and time."
  (interactive)
  (insert (current-time-string)))
(global-set-key (kbd "C-c T") #'bmillare-insert-date)

(defun bmillare-symbol-at-point ()
  "Copy the symbol at point to the kill ring."
  (interactive)
  (if-let* ((symbol (thing-at-point 'symbol t)))
      (kill-new symbol)
    (user-error "No symbol at point")))
(global-set-key (kbd "C-c s") #'bmillare-symbol-at-point)

(defun insert-xml-tag-pair (tag-name)
  "Insert an XML opening and closing tag pair for TAG-NAME at point."
  (interactive "sTag name: ")
  (insert (format "<%s>\n</%s>" tag-name tag-name))
  (forward-line -1)
  (end-of-line))

(global-set-key (kbd "C-c x") #'insert-xml-tag-pair)

(setq markdown-command "pandoc")
(put 'downcase-region 'disabled nil)

;; Keep Custom and experiments writable, outside the Nix store.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(load custom-file t t)
(load (expand-file-name "local.el" user-emacs-directory) t t)

(unless noninteractive
  (require 'server)
  (unless (server-running-p) (server-start)))

;;; init.el ends here
