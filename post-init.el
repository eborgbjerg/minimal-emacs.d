;;; post-init.el --- Called from end of init.el -*- no-byte-compile: t; lexical-binding: t; -*-

;; As per the README in
;; https://github.com/jamescherti/minimal-emacs.d
(use-package vterm
  :ensure t
  :defer t
  :commands vterm
  :config
  ;; Speed up vterm
  (setq vterm-timer-delay 0.01))


;; Auto-revert in Emacs is a feature that automatically updates the
;; contents of a buffer to reflect changes made to the underlying file
;; on disk.
(add-hook 'after-init-hook #'global-auto-revert-mode)

;; recentf is an Emacs package that maintains a list of recently
;; accessed files, making it easier to reopen files you have worked on
;; recently.
(add-hook 'after-init-hook #'recentf-mode)

;; savehist is an Emacs feature that preserves the minibuffer history between
;; sessions. It saves the history of inputs in the minibuffer, such as commands,
;; search strings, and other prompts, to a file. This allows users to retain
;; their minibuffer history across Emacs restarts.
(add-hook 'after-init-hook #'savehist-mode)

;; save-place-mode enables Emacs to remember the last location within a file
;; upon reopening. This feature is particularly beneficial for resuming work at
;; the precise point where you previously left off.
(add-hook 'after-init-hook #'save-place-mode)


;;  NOTE
;;  that minimal-emacs.d has set custom-file previously...
;;  AND HAD IT NOT DONE SO, then
;;  Emacs would write customizations in ~/.emacs
;;  (which would override any other customization...)
;; https://emacs.stackexchange.com/questions/64614/emacs-custom-file-get-overwritten
(load-file custom-file)

;; https://github.com/jamescherti/minimal-emacs.d
;; (minimal-emacs-load-user-init custom-file)


;; https://github.com/abo-abo/ace-window
(global-set-key (kbd "M-o") 'ace-window)

;; also check this:
;;  https://emacs.dyerdwelling.family/emacs/20241209085935-emacs--emacs-core-window-jumping-visual-feedback/


;; https://github.com/jamescherti/buffer-terminator.el
(use-package buffer-terminator
  :ensure t
  :custom
  (buffer-terminator-verbose t)
  :config
  (buffer-terminator-mode 1))


;; turn on Eglot when in Python mode
;; https://www.gnu.org/software/emacs/manual/html_node/eglot/index.html
(add-hook 'python-mode-hook 'eglot-ensure)


;; https://github.com/emacsorphanage/git-messenger
;; see also vc-msg package
(use-package git-messenger
  :bind ("C-x v p" . git-messenger:popup-message))



;; Make Org links editable by default
(setq org-descriptive-links nil)




;; from https://github.com/jamescherti/minimal-emacs.d?tab=readme-ov-file#code-completion-with-corfu
(use-package corfu
  :ensure t
  :defer t
  :commands (corfu-mode global-corfu-mode)

  :hook ((prog-mode . corfu-mode)
         (shell-mode . corfu-mode)
         (eshell-mode . corfu-mode))

  :custom
  ;; Hide commands in M-x which do not apply to the current mode.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Disable Ispell completion function. As an alternative try `cape-dict'.
  (text-mode-ispell-word-completion nil)
  (tab-always-indent 'complete)

  ;; Enable Corfu
  :config
  (global-corfu-mode))

(use-package cape
  :ensure t
  :defer t
  :commands (cape-dabbrev cape-file cape-elisp-block)
  :bind ("C-c p" . cape-prefix-map)
  :init
  ;; Add to the global default value of `completion-at-point-functions' which is
  ;; used by `completion-at-point'.
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block))



;; My git repos
;; Run
;; M-x magit-list-repositories
;; to show them
(setq magit-repository-directories
      '(("~/git/" . 1)
        ("~/.emacs.d/" . 0)))

(add-hook 'emacs-startup-hook #'magit-list-repositories)



;; TODO
;; below some ideas to try out
;;
;; https://protesilaos.com/codelog/2024-12-11-emacs-diff-save-some-buffers/
;;
;; https://themkat.net/2024/12/17/twenty_four_emacs_packages.html

(with-eval-after-load 'eglot
  (setq-default eglot-workspace-configuration
                '((:pylsp . (:plugins (:mccabe (:enabled t :threshold 21))))))
)



;; 
;; 
;; ;; Note that later minimal-emacs added
;; ;; keybindings.el
;; (global-set-key (kbd "C-c v") #'my/vterm-session-start)



;; Replace default buffer list with ibuffer (focus automatically)
(global-set-key (kbd "C-x C-b") 'ibuffer)



;;;; vterm sessions — simple config + commands
(require 'cl-lib)

(defgroup my-vterm-sessions nil
  "Lightweight vterm session manager."
  :group 'term)

(defcustom my/vterm-sessions-file (expand-file-name "vterm-sessions.sexp" user-emacs-directory)
  "Path to the vterm sessions file."
  :type 'file)

(defvar my/vterm-sessions nil
  "List of session plists.
Each entry is a plist with keys:
  :name (string, required)
  :dir  (string, required, expanded as default-directory)
  :commands (list of strings, optional)
  :autostart (non-nil to start automatically on load)
  :buffer-name (string, optional; default \"*vterm-<name>*\")
  :query-on-exit (boolean, optional; default t — warn on Emacs quit).")

(defun my/vterm--require ()
  (unless (require 'vterm nil t)
    (user-error "Package 'vterm' not available")))

(defun my/vterm--read-file (file)
  (when (file-readable-p file)
    (with-temp-buffer
      (insert-file-contents file)
      (read (current-buffer)))))

(defun my/vterm--write-file (file data)
  (make-directory (file-name-directory file) t)
  (with-temp-file file
    (let ((print-level nil)
          (print-length nil))
      (pp data (current-buffer)))))

(defun my/vterm-load-sessions ()
  "Load sessions from `my/vterm-sessions-file' into `my/vterm-sessions'."
  (interactive)
  (setq my/vterm-sessions (or (my/vterm--read-file my/vterm-sessions-file) '()))
  (message "Loaded %d vterm sessions" (length my/vterm-sessions)))

(defun my/vterm-save-sessions ()
  "Persist `my/vterm-sessions' to `my/vterm-sessions-file'."
  (interactive)
  (my/vterm--write-file my/vterm-sessions-file my/vterm-sessions)
  (message "Saved %d vterm sessions to %s" (length my/vterm-sessions) my/vterm-sessions-file))

(defun my/vterm--session-by-name (name)
  (cl-find-if (lambda (pl) (string-equal (plist-get pl :name) name)) my/vterm-sessions))

(defun my/vterm--buffer-name (pl)
  (or (plist-get pl :buffer-name)
      (format "*vterm-%s*" (plist-get pl :name))))


;; --- Start/reuse a session and apply the policy -----------------------------
(defun my/vterm--start-one (pl &optional select)
  "Start (or reuse) a vterm for session PL. If SELECT is non-nil, switch to it."
  (let* ((name (plist-get pl :name))
         (dir  (expand-file-name (plist-get pl :dir)))
         (bufname (or (plist-get pl :buffer-name)
                      (format "*vterm-%s*" name)))
         (cmds (plist-get pl :commands))
         (buf (get-buffer bufname)))
    (unless (and buf (buffer-live-p buf))
      (let ((default-directory dir))
        (setq buf (vterm bufname))
        (dolist (c cmds)
          (vterm-send-string c)
          (vterm-send-return))))
    ;; Always (re)apply the exit policy; the process might be new.
    (my/vterm--apply-exit-query-flag buf pl)
    (when select (pop-to-buffer buf))
    buf))



;; --- Helper to apply per-session exit policy --------------------------------
(defun my/vterm--apply-exit-query-flag (buf pl)
  (when (buffer-live-p buf)
    (let ((proc (get-buffer-process buf)))
      (when (process-live-p proc)
        (set-process-query-on-exit-flag
         proc
         ;; default to t (warn) if key is missing
         (if (plist-member pl :query-on-exit)
             (plist-get pl :query-on-exit)
           t))))))


;;; ----- Interactives -----

(defun my/vterm-start-session (name &optional select)
  "Start a configured session by NAME. With prefix arg, SELECT it."
  (interactive
   (list (completing-read "Start vterm session: "
                          (mapcar (lambda (pl) (plist-get pl :name)) my/vterm-sessions)
                          nil t)
         current-prefix-arg))
  (let ((pl (my/vterm--session-by-name name)))
    (unless pl (user-error "No session named %s" name))
    (my/vterm--start-one pl select)))

(defun my/vterm-start-all (&optional only-autostart)
  "Start all sessions. With prefix arg, start only those with :autostart."
  (interactive "P")
  (let* ((xs (if only-autostart
                 (cl-remove-if-not (lambda (pl) (plist-get pl :autostart)) my/vterm-sessions)
               my/vterm-sessions))
         (n 0))
    (dolist (pl xs) (my/vterm--start-one pl) (cl-incf n))
    (message "Started %d vterm session(s)" n)))



;; --- Registrar includes :query-on-exit --------------------------------------
(defun my/vterm-register-session (name dir &optional commands autostart buffer-name query-on-exit)
  "Add or update a session. QUERY-ON-EXIT controls Emacs' quit warning for this vterm."
  (interactive
   (list
    (read-string "Name: ")
    (read-directory-name "Directory: " default-directory nil t)
    (let* ((raw (read-string "Commands (semicolon-separated, optional): ")))
      (unless (string-empty-p raw)
        (mapcar #'string-trim (split-string raw ";" t))))
    (y-or-n-p "Autostart? ")
    (let ((bn (read-string "Buffer name (optional): ")))
      (unless (string-empty-p bn) bn))
    (y-or-n-p "Warn on Emacs exit if running? ")))  ;; default behavior is warn
  (let ((pl (list :name name :dir dir
                  :query-on-exit (if (null query-on-exit) nil t))))
    (when commands   (setq pl (plist-put pl :commands commands)))
    (when autostart  (setq pl (plist-put pl :autostart t)))
    (when buffer-name (setq pl (plist-put pl :buffer-name buffer-name)))
    (let ((existing (my/vterm--session-by-name name)))
      (if existing
          (progn
            (setf (plist-get existing :dir) (plist-get pl :dir)
                  (plist-get existing :commands) (plist-get pl :commands)
                  (plist-get existing :autostart) (plist-get pl :autostart)
                  (plist-get existing :buffer-name) (plist-get pl :buffer-name)
                  (plist-get existing :query-on-exit) (plist-get pl :query-on-exit))
            (message "Updated session %s" name))
        (push pl my/vterm-sessions)
        (message "Added session %s" name)))
    (my/vterm-save-sessions)))



(defun my/vterm-register-session (name dir &optional commands autostart buffer-name)
  "Add or update a session.
COMMANDS is a list of strings sent to the shell after spawn."
  (interactive
   (list
    (read-string "Name: ")
    (read-directory-name "Directory: " default-directory nil t)
    (let* ((raw (read-string "Commands (semicolon-separated, optional): ")))
      (unless (string-empty-p raw)
        (mapcar #'string-trim (split-string raw ";" t))))
    (y-or-n-p "Autostart? ")
    (let ((bn (read-string "Buffer name (optional): ")))
      (unless (string-empty-p bn) bn))))
  (let ((pl (list :name name :dir dir)))
    (when commands (setq pl (plist-put pl :commands commands)))
    (when autostart (setq pl (plist-put pl :autostart t)))
    (when buffer-name (setq pl (plist-put pl :buffer-name buffer-name)))
    (let ((existing (my/vterm--session-by-name name)))
      (if existing
          (progn
            (setf (plist-get existing :dir) (plist-get pl :dir)
                  (plist-get existing :commands) (plist-get pl :commands)
                  (plist-get existing :autostart) (plist-get pl :autostart)
                  (plist-get existing :buffer-name) (plist-get pl :buffer-name))
            (message "Updated session %s" name))
        (push pl my/vterm-sessions)
        (message "Added session %s" name)))
    (my/vterm-save-sessions)))

(defun my/vterm-remove-session (name)
  "Remove a session by NAME."
  (interactive
   (list (completing-read "Remove vterm session: "
                          (mapcar (lambda (pl) (plist-get pl :name)) my/vterm-sessions)
                          nil t)))
  (setq my/vterm-sessions
        (cl-remove-if (lambda (pl) (string-equal (plist-get pl :name) name))
                      my/vterm-sessions))
  (my/vterm-save-sessions)
  (message "Removed session %s" name))

(defun my/vterm-rename-session (old-name new-name)
  "Rename a session."
  (interactive
   (let* ((old (completing-read "Rename session: "
                                (mapcar (lambda (pl) (plist-get pl :name)) my/vterm-sessions)
                                nil t))
          (new (read-string (format "New name for %s: " old) old)))
     (list old new)))
  (let ((pl (my/vterm--session-by-name old-name)))
    (unless pl (user-error "No session named %s" old-name))
    (setf (plist-get pl :name) new-name)
    (unless (plist-get pl :buffer-name)
      (setf (plist-get pl :buffer-name) (format "*vterm-%s*" new-name)))
    (my/vterm-save-sessions)
    (message "Renamed %s -> %s" old-name new-name)))

(defun my/vterm-edit-sessions-file ()
  "Open the sessions file for manual editing."
  (interactive)
  (find-file my/vterm-sessions-file)
  (emacs-lisp-mode))


;;; Re-apply per-session process-exit flags to open vterms
;; How to use
;;
;; M-x my/vterm-apply-flags-to-open-buffers → reapplies flags using the current in-memory sessions list.
;;
;; C-u M-x my/vterm-apply-flags-to-open-buffers → reloads vterm-sessions.sexp first, then reapplies.

(defun my/vterm--session-buffer (pl)
  "Return the buffer for session PL if it exists, else nil."
  (let* ((bufname (or (plist-get pl :buffer-name)
                      (format "*vterm-%s*" (plist-get pl :name)))))
    (get-buffer bufname)))

;;;###autoload
(defun my/vterm-apply-flags-to-open-buffers (&optional reload)
  "Reapply :query-on-exit flags from the sessions config to any open managed vterm buffers.
With prefix arg RELOAD (\\[universal-argument]), reload the sessions file first."
  (interactive "P")
  (when reload (my/vterm-load-sessions))
  (let ((applied 0)
        (skipped 0))
    (dolist (pl my/vterm-sessions)
      (let ((buf (my/vterm--session-buffer pl)))
        (if (and buf (buffer-live-p buf))
            (progn
              (my/vterm--apply-exit-query-flag buf pl)
              (cl-incf applied))
          (cl-incf skipped))))
    (message "Applied flags to %d buffer(s); %d session(s) not currently open"
             applied skipped)))


;;; ----- Convenience on startup -----

(defun my/vterm-session-startup ()
  "Load sessions file and autostart those marked :autostart."
  (my/vterm-load-sessions)
  (let ((to-start (cl-remove-if-not (lambda (pl) (plist-get pl :autostart))
                                    my/vterm-sessions)))
    (dolist (pl to-start) (my/vterm--start-one pl))))

;; Load at init; start autostarted sessions.
(add-hook 'emacs-startup-hook #'my/vterm-session-startup)

(provide 'my-vterm-sessions)




;; GPTEL ;;
;; --- gptel setup WITHOUT environment variables ---
(use-package gptel
  :ensure t
  :init
  ;; Tell Emacs to look in ~/.authinfo.gpg for credentials
  (setq auth-sources '("~/.authinfo.gpg"))
  ;; Make gptel pull the key from auth-source (host api.openai.com; user apikey)
  (setq gptel-use-auth-source t
        gptel-api-key nil        ;; ensure we don't override auth-source
        gptel-model "gpt-4o-mini")

  ;; Helper: add or update "machine api.openai.com login apikey password <KEY>" in ~/.authinfo.gpg
  (defun my/gptel-store-openai-key ()
    "Prompt for an OpenAI API key and store/update it in ~/.authinfo.gpg."
    (interactive)
    (require 'auth-source)
    (let* ((file (expand-file-name "~/.authinfo.gpg"))
           (host "api.openai.com")
           (user "apikey")
           (entry-rx (rx bol "machine " (literal host) " login " (literal user) " password " (+ nonl) eol))
           (key (read-passwd "Enter OpenAI API key (starts with sk-): ")))
      ;; Create file if missing so EasyPG can encrypt it on first save
      (unless (file-exists-p file)
        (with-temp-file file
          ;; empty; saving will trigger encryption prompt
          ))
      ;; Load, replace-or-append, then save (EasyPG will encrypt on write)
      (with-temp-buffer
        (insert-file-contents file)
        (goto-char (point-min))
        (if (re-search-forward entry-rx nil t)
            (replace-match (format "machine %s login %s password %s" host user key) t t)
          (goto-char (point-max))
          (unless (bolp) (insert "\n"))
          (insert (format "machine %s login %s password %s\n" host user key)))
        ;; Write back encrypted
        (write-region (point-min) (point-max) file))
      (message "Saved OpenAI API key to %s" file)))

  ;; Optional: run this once to bootstrap your key
  ;; M-x my/gptel-store-openai-key
  :config
  ;; Convenience keys
  (define-key global-map (kbd "C-c g") #'gptel)
  (define-key global-map (kbd "C-c G") #'gptel-send))



;; ;; Optional Org-mode block support
;; (use-package gptel-org
;;   :after gptel)



;;
;;
;;
;; Perl Navigator LSP

(defalias 'perl-mode 'cperl-mode)

;; Ensure eglot is loaded before modifying eglot variables
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((perl-mode cperl-mode) . ("perlnavigator" "--stdio"))))

(add-hook 'perl-mode-hook #'eglot-ensure)
(add-hook 'cperl-mode-hook #'eglot-ensure)


;;
;;
;;
;;




;; todo
;; mu4e setup
;; Error (use-package): Cannot load mu4e
;; see https://github.com/radian-software/straight.el/issues/491



;; Working on ejbo.dk
(dired "~/git/chess-games/ejbo-dk-3/hugo-org-per-file/")

;; Convenient
(dired "~/Hentet/")

;; EWW
;; (eww "ejbo.dk")

(server-start)
