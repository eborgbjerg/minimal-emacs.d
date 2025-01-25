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




;; TODO
;; below some ideas to try out
;;
;; https://protesilaos.com/codelog/2024-12-11-emacs-diff-save-some-buffers/
;;
;; https://themkat.net/2024/12/17/twenty_four_emacs_packages.html
