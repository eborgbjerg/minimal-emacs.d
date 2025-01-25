;;; post-early-init.el --- Called from end of early-init.el -*- no-byte-compile: t; lexical-binding: t; -*-


;; Initialize packages in here instead of init.el
(setq minimal-emacs-package-initialize-and-refresh nil)

(progn
  (package-initialize)
  (unless package-archive-contents
    (package-refresh-contents))
  (unless (package-installed-p 'use-package)
    (package-install 'use-package))
  (eval-when-compile
    (require 'use-package)))


(use-package tomorrow-night-deepblue-theme
  :ensure t
  :config
  ;; Disable all themes and load the Tomorrow Night Deep Blue theme
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme 'tomorrow-night-deepblue t))


;; NOTE toggling maximized frame should NOT be combined with
;; desktop restoring with desktop.el or the like!
;; Start maximized
;;(add-hook 'window-setup-hook 'toggle-frame-maximized t)


;; This is the best place to add new menus and items.
;; Snippet that shows how to create menus and menu items.
;;  http://ergoemacs.org/emacs/elisp_menu.html


;; Create Ejner menu right of “Tools” menu
(define-key-after
  global-map
  [menu-bar ejner]
  (cons "Ejner" (make-sparse-keymap "ejner"))
  'tools )

(define-key
  global-map
  [menu-bar ejner nl]
  '("Todo Mode" "Toggle Todo mode" . hl-todo-mode))

(define-key
  global-map
  [menu-bar ejner n2]
  '("Next Todo" "Go to next Todo item" . hl-todo-next))

(define-key
  global-map
  [menu-bar ejner n3]
  '("Prev Todo" "Go to previous Todo item" . hl-todo-previous))

(define-key
  global-map
  [menu-bar ejner n4]
  '("--" "--"))

(define-key
  global-map
  [menu-bar ejner pl]
  '("Documentation" "Fetch documentation" . eldoc-doc-buffer))


;; TODO
;; Trying out some interesting functions
;; e.g. add to menu Ejner
;; process-list
;; M-:  (eval-expression)
;; term
;; -- another different term(!)

;; TODO
;; look at some interesting packages to try
;;  company:
;;    https://company-mode.github.io/
;;  restclient.el





;; code to remove a whole menu
;; (global-unset-key [menu-bar ejner])

;; Add item to existing menu
;; (define-key
;;   global-map
;;   [menu-bar help-menu forward]
;;   '("Forward" . forward-word))
