;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;; To install a package with Doom you must declare them here and run 'doom sync'
;; on the command line, then restart Emacs for the changes to take effect -- or
;; use 'M-x doom/reload'.


;; To install SOME-PACKAGE from MELPA, ELPA or emacsmirror:
                                        ;(package! some-package)

;; To install a package directly from a remote git repo, you must specify a
;; `:recipe'. You'll find documentation on what `:recipe' accepts here:
;; https://github.com/radian-software/straight.el#the-recipe-format
                                        ;(package! another-package
                                        ;  :recipe (:host github :repo "username/repo"))

;; If the package you are trying to install does not contain a PACKAGENAME.el
;; file, or is located in a subdirectory of the repo, you'll need to specify
;; `:files' in the `:recipe':
                                        ;(package! this-package
                                        ;  :recipe (:host github :repo "username/repo"
                                        ;           :files ("some-file.el" "src/lisp/*.el")))

;; If you'd like to disable a package included with Doom, you can do so here
;; with the `:disable' property:
                                        ;(package! builtin-package :disable t)

;; You can override the recipe of a built in package without having to specify
;; all the properties for `:recipe'. These will inherit the rest of its recipe
;; from Doom or MELPA/ELPA/Emacsmirror:
                                        ;(package! builtin-package :recipe (:nonrecursive t))
                                        ;(package! builtin-package-2 :recipe (:repo "myfork/package"))

;; Specify a `:branch' to install a package from a particular branch or tag.
;; This is required for some packages whose default branch isn't 'master' (which
;; our package manager can't deal with; see radian-software/straight.el#279)
                                        ;(package! builtin-package :recipe (:branch "develop"))

;; Use `:pin' to specify a particular commit to install.
                                        ;(package! builtin-package :pin "1a2b3c4d5e")


;; Doom's packages are pinned to a specific commit and updated from release to
;; release. The `unpin!' macro allows you to unpin single packages...
                                        ;(unpin! pinned-package)
;; ...or multiple packages
                                        ;(unpin! pinned-package another-pinned-package)
;; ...Or *all* packages (NOT RECOMMENDED; will likely break things)
                                        ;(unpin! t)
;; Hephaistox start
(package! babashka)
(package! zprint-mode)
(add-load-path! "~/.config/doom/hephaistox.el")
;; Hephaistox end

;;for viewing scss files
(package! scss-mode)

;;for popping up buffers to separate frames
(package! posframe)

;; for editing yaml files
(package! yaml-mode)

;; documentation popups
(package! company-quickhelp)

;; presentation tool
(package! org-present)

;; better displayed columns https://codeberg.org/joostkremers/visual-fill-column
(package! visual-fill-column)

;; paredit mode - structural editing to lisps
(package! paredit)

;; grammarly
;; (package! lsp-grammarly)

;;mermaid
(package! mermaid-mode)

;;eca
(package! eca)

;;tailwindcss
(package! lsp-tailwindcss :recipe (:host github :repo "merrickluo/lsp-tailwindcss"))


;;UNPINS
;; (unpin! hover)
;; (unpin! treemacs)
;; (unpin! lsp-treemacs)
;; (unpin! lsp-mode)
;; (unpin! lsp-ui)
;; (unpin! lsp-dart)

;; Temporary
;; (package! map :pin "bb50dba")
;; (unpin! iedit)
;; (unpin! evil-multiedit)
;; (unpin! evil)
;; (unpin! cider)


;;C++
;; (use-package ccls
;;   :after projectile
;;   :ensure-system-package ccls
;;   :custom
;;   (ccls-args nil)
;;   (ccls-executable (executable-find "ccls"))
;;   (projectile-project-root-files-top-down-recurring
;;    (append '("compile_commands.json" ".ccls")
;;            projectile-project-root-files-top-down-recurring))
;;   :config (push ".ccls-cache" projectile-globally-ignored-directories))

;; (after! ccls
;;   (setq ccls-initialization-options '(:index (:comments 2) :completion (:detailedLabel t)))
;;   (set-lsp-priority! 'ccls 1))

;; (use-package cmake-mode
;;   :mode ("CMakeLists\\.txt\\'" "\\.cmake\\'"))

;; (use-package cmake-font-lock
;;   :after (cmake-mode)
;;   :hook (cmake-mode . cmake-font-lock-activate))

;; (use-package cmake-ide
;;   :after projectile
;;   :hook (c++-mode . my/cmake-ide-find-project)
;;   :preface
;;   (defun my/cmake-ide-find-project ()
;;     "Finds the directory of the project for cmake-ide."
;;     (with-eval-after-load 'projectile
;;       (setq cmake-ide-project-dir (projectile-project-root))
;;       (setq cmake-ide-build-dir (concat cmake-ide-project-dir "build")))
;;     (setq cmake-ide-compile-command
;;           (concat "cd " cmake-ide-build-dir " && cmake .. && make"))
;;     (cmake-ide-load-db))

;;   (defun my/switch-to-compilation-window ()
;;     "Switches to the *compilation* buffer after compilation."
;;     (other-window 1))
;;   :bind ([remap comment-region] . cmake-ide-compile)
;;   :init (cmake-ide-setup)
;;   :config (advice-add 'cmake-ide-compile :after #'my/switch-to-compilation-window))

;; (use-package google-c-style
;;   :hook ((c-mode c++-mode) . google-set-c-style)
;;   (c-mode-common . google-make-newline-indent))
