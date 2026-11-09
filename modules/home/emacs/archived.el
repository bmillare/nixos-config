;;; archived.el --- Legacy Mac configuration, reference only
;; Snapshot of ~/clj/git/worklog/config/.emacs before unification, 2026-11-09.
;; NOT loaded or installed by Home Manager. Do not load this entire file:
;; it initializes Helm, changes bindings, requires old packages, and starts
;; the server. Copy/evaluate individual definitions when revisiting a helper.
;; Preserves process-send helpers, CIDER/terminal setup, temporary-file
;; exchange, UUID/kill-buffer helpers, markdown renderer, and old settings.
;; Historical code is kept unchanged below (including known rough edges).

;;;;---------------------------------------------------------------------------
;; .emacs configuration file
;; author: Brent Millare
;;;;---------------------------------------------------------------------------

(setq create-lockfiles nil)

;; Load common defaults
;(require 'cl)
(require 'site-gentoo nil t)
(global-auto-revert-mode t)
(package-initialize)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)
(require 'helm)
;;(require 'helm-config)
(setq helm-split-window-in-side-p t)
;; better than defaults
(global-set-key (kbd "M-x") 'helm-M-x)            ; has hotkeys next to the side
(global-set-key (kbd "C-x b") 'switch-to-buffer)         ; has recent files
(global-set-key (kbd "C-x C-f") 'helm-find-files) ; has binding to helm-find
(defun volatile-kill-buffer ()
   "Kill current buffer unconditionally."
   (interactive)
   (let ((buffer-modified-p nil))
     (kill-buffer (current-buffer))))

(global-set-key (kbd "C-x K") 'volatile-kill-buffer)
(helm-mode 1)

;; Interface Color Scheme
(when window-system
  ;; (add-to-list 'default-frame-alist '(background-color . "gray0"))
  (add-to-list 'default-frame-alist '(background-color . "black"))
  (add-to-list 'default-frame-alist '(foreground-color . "gray85"))
  (add-to-list 'default-frame-alist '(cursor-color . "red3"))
  (add-to-list 'default-frame-alist '(mouse-color . "white")))

;; General Options
(setq mac-command-modifier 'meta)
(setq auto-save-timeout 2000)
(setq make-backup-files nil)
(set-scroll-bar-mode 'right)
(setq x-select-enable-clipboard t)
(column-number-mode 1)
(tool-bar-mode 0)
(menu-bar-mode 0)
(setq inhibit-startup-screen t) 
(setq default-truncate-lines t)                         ;;Do not word wrap, act like nano -w
(define-key global-map (kbd "RET") 'newline-and-indent) ;;After newline, auto indent
(setq c-basic-offset 4)                                 ;;Spacing for indentation
(setq transient-mark-mode t)                            ;;Color selected regions
(setq mark-even-if-inactive t)                          ;;tradi style but still use color
;; trying out helm, disabling
;(require 'uniquify)
;(setq uniquify-buffer-name-style 'post-forward)
(global-set-key (kbd "C-c h") 'windmove-left)
(global-set-key (kbd "C-c l") 'windmove-right)
(global-set-key (kbd "C-c k") 'windmove-up)
(global-set-key (kbd "C-c j") 'windmove-down)
;; trying out helm, disabling
; (require 'ibuffer)
; (global-set-key (kbd "C-x C-b") 'ibuffer)
; (setq ibuffer-default-sorting-mode 'major-mode)
(setq-default indent-tabs-mode nil)

(defconst my/wsl (not (null (string-match "Linux.*Microsoft" (shell-command-to-string "uname -a")))))

(if my/wsl
    (progn
      (setq browse-url-browser-function 'browse-url-generic browse-url-generic-program "wslview")))
(global-set-key (kbd "C-c b") 'browse-url-at-point)

(defun bmillare-set-target-buffer ()
  (interactive)
  (setq bmillare-target-buffer (buffer-name)))

(defun bmillare-send-region (beg end)
  (interactive "r")
  (process-send-region bmillare-target-buffer beg end)
  (process-send-string bmillare-target-buffer "\n"))

(defun bmillare-send-defun ()
  (interactive)
  (save-excursion
    (end-of-defun)
    (let ((end (point))
          (case-fold-search t)
          (ignore (beginning-of-defun))
          (beg (point)))
      (process-send-region bmillare-target-buffer beg end)
      (process-send-string bmillare-target-buffer "\n"))))

(defun bmillare-send-line ()
  (interactive)
  (save-excursion
    (end-of-line)
    (let ((end (point))
          (case-fold-search t)
          (ignore (beginning-of-line))
          (beg (point)))
      (process-send-region bmillare-target-buffer beg end)
      (process-send-string bmillare-target-buffer "\n"))))
(global-set-key (kbd "C-c d") 'bmillare-send-defun)
(global-set-key (kbd "C-c e") 'bmillare-send-line)
(global-set-key (kbd "C-c r") 'bmillare-send-region)
(global-set-key (kbd "C-c t") 'bmillare-set-target-buffer)

(defun bmillare-insert-uuid ()
  (interactive)
  (shell-command "uuidgen" t))
(global-set-key (kbd "C-c u") 'bmillare-insert-uuid)

(defun bmillare-insert-date ()
  (interactive)
  (insert (current-time-string)))
(global-set-key (kbd "C-c T") 'bmillare-insert-date)

(defun bmillare-symbol-at-point () (interactive) (kill-new (thing-at-point 'symbol)))
(global-set-key (kbd "C-c s") 'bmillare-symbol-at-point)

(defun bmillare-send-string ()
  (interactive)
  (process-send-string "clj_term" (concat "(emacs/echo "
                                          (read-string "send clj:")
                                          ")\n")))
(global-set-key (kbd "C-c c") 'bmillare-send-string)

(defun bmillare-insert-scratch ()
  (interactive)
 (insert-file-contents "/tmp/bmillare-emacs-out.txt"))
(global-set-key (kbd "C-c y") 'bmillare-insert-scratch)

;; convenience for quickly getting buffer content into clojure form, like via a string or via code (you need to slurp /tmp/bmillare-emacs-tmp-out.txt)
(defun bmillare-buffer-to-tmp ()
  (write-region (point-min) (point-max) "/tmp/bmillare-emacs-tmp-out.txt"))

(defun bmillare-region-to-tmp (beg end)
  (interactive "r")
  (write-region beg end "/tmp/bmillare-emacs-tmp-out.txt"))

(defun bmillare-stringify-tmp-to-buffer ()
  (interactive)
  (cider-interactive-eval "(slurp \"/tmp/bmillare-emacs-tmp-out.txt\")"
                          (cider-eval-print-handler)))

(defun bmillare-add-backslash-before-newlines ()
  "Add a backslash before each newline in the selected region."
  (interactive)
  (let ((start (region-beginning))
        (end (region-end)))
    ;; If no region is selected, use the entire buffer.
    (if (use-region-p)
        (progn
          (narrow-to-region start end)
          (goto-char start))
      (unless (bolp) (forward-line 1)))
    ;; Loop over each line in the region and add a backslash before each newline.
    (while (not (eobp))
      (end-of-line)
      (insert "\\")
      (forward-line 1))))

(defun insert-xml-tag-pair (tag-name)
  "Insert an XML opening and closing tag pair for TAG-NAME at point."
  (interactive "sTag name: ")
  (insert (format "<%s>\n</%s>" tag-name tag-name))
  (forward-line -1)
  (end-of-line))

(global-set-key (kbd "C-c x") #'insert-xml-tag-pair)
;; ----------------------------------------------------------------------

(fset 'bmillare-make-term
   (lambda (&optional arg) "Keyboard macro." (interactive "p") (kmacro-exec-ring-item (quote ([134217848 97 110 115 105 45 116 101 114 109 return return 3 10 134217848 114 101 110 97 109 101 45 98 117 102 102 101 114] 0 "%d")) arg)))

;; (defun bmillare-setup-cljs (&optional arg)
;;   (interactive "p")
;;   (process-send-string "gen_term1"
;;                        "cd ~/clj/src
;; sudo -S echo 'setting password' < ~/.sudopassword
;; sudo mount --bind ~/clj/git/clojurescript/src/main/clojure ./clojure
;; sudo mount --bind ~/clj/git/clojurescript/src/main/cljs ./cljs
;; "))

(fset 'bmillare-setup
      (lambda (&optional arg)
        "Keyboard macro."
        (interactive "p")
        (ansi-term "/bin/bash" "gen_term")
        (rename-buffer "gen_term1")
        (process-send-string "gen_term1"
                             "cd ~/clj/src
")
        (ansi-term "/bin/bash" "clj_term")
        (rename-buffer "clj_term")
        ;;(process-send-string "clj_term" "which nix-shell && nix-shell -p jdk24
;;")
        (process-send-string "clj_term" "~/clj/bin/clojure
")
        (sit-for 2)
        (process-send-string "clj_term"
                             "(require 'dj.dependencies2)
(dj.dependencies2/add-dependencies
 '[[cider/cider-nrepl \"0.56.0\" :exclusions [org.clojure/clojure]]])
(require 'nrepl.server
         'cider.nrepl)
(doc nrepl.server/start-server)
(def server (nrepl.server/start-server :port 7999
                                       :handler cider.nrepl/cider-nrepl-handler))
(load \"scratch/emacs\")
(in-ns 'emacs)
")
        (sit-for 5)
        (cider-connect '(:host "localhost" :port 7999 :project-dir "~/clj/src"))
        ;; (set-window-buffer nil "*cider-repl Software/data:localhost:7999(clj)*")
))

(require 'clojure-mode)
(add-hook 'clojure-mode-hook (lambda ()
                               (paredit-mode +1)))

(setq frame-background-mode 'dark)
(setq while-no-input-ignore-events '())

(defcustom my-markdown-renderer-path "/Users/bmillare/projects/mdr/mdr"
  "The absolute path to your custom markdown rendering command line program."
  :type 'string
  :group 'markdown)

(defun my-render-markdown-async ()
  "Send the current buffer's contents to a custom markdown renderer via stdin asynchronously."
  (interactive)
  (unless (file-executable-p my-markdown-renderer-path)
    (error "Renderer not found or not executable at: %s" my-markdown-renderer-path))
  
  (let ((proc (make-process
               :name "markdown-renderer-process"
               ;; Any stdout/stderr from the program will go to this buffer
               :buffer "*markdown-renderer-output*"
               :command (list my-markdown-renderer-path "-b" "webview")
               ;; 'pipe ensures we can stream data into its stdin
               :connection-type 'pipe)))
    
    ;; Send the entire buffer to the process's stdin
    (process-send-region proc (point-min) (point-max))
    
    ;; Send EOF (End Of File) so the program knows we are done sending input
    ;; This is required if your program waits for stdin to close before acting
    (process-send-eof proc)
    
    (message "Sent buffer to %s in the background!" my-markdown-renderer-path)))

;; Bind it to C-c p globally:
(global-set-key (kbd "C-c p") 'my-render-markdown-async)

;; Colors for code
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(font-lock-builtin-face ((t (:foreground "cyan" :weight bold))))
 '(font-lock-comment-face ((t (:foreground "LightPink"))))
 '(font-lock-constant-face ((t (:foreground "SpringGreen"))))
 '(font-lock-doc-string-face ((t (:foreground "SpringGreen"))))
 '(font-lock-function-name-face ((t (:foreground "wheat3"))))
 '(font-lock-keyword-face ((t (:foreground "SkyBlue" :bold t))))
 '(font-lock-preprocessor-face ((t (:foreground "SkyBlue"))))
 '(font-lock-reference-face ((t (:foreground "yellow"))))
 '(font-lock-string-face ((t (:foreground "SpringGreen"))))
 '(font-lock-type-face ((t (:foreground "orange1"))))
 '(font-lock-variable-name-face ((t (:foreground "yellow"))))
 '(font-lock-warning-name-face ((t (:foreground "DarkOrange")))))

(server-start)

(put 'downcase-region 'disabled nil)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(markdown-command "pandoc")
 '(package-selected-packages
   '(cider clojure-mode gnu-elpa-keyring-update helm helm-cider
           inf-clojure magit markdown-mode nix-mode paredit unfill
           vterm)))
