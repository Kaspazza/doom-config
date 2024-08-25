;;; ~/.doom.d/+bindings.el -*- lexical-binding: t; -*-

(define-key evil-normal-state-map (kbd "<tab>") 'evil-jump-item)
(define-key evil-motion-state-map (kbd "] e") #'flycheck-next-error)
(define-key evil-motion-state-map (kbd "[ e") #'flycheck-previous-error)

;;evil-multiedit feature - to be learned
(map! :nvi "s-r" #'evil-multiedit-match-all
      :nvi "s-d" #'evil-multiedit-match-and-next
      :nvi "s-D" #'evil-multiedit-match-and-prev
      :nvi "s-n" #'evil-multiedit-next
      :nvi "s-p" #'evil-multiedit-prev
      :nvi "s-m" #'evil-multiedit-toggle-or-restrict-region)

;; paredit barf/slurp - to be learned
(after! paredit
  (define-key paredit-mode-map (kbd "C-<left>") nil)
  (define-key paredit-mode-map (kbd "C-<right>") nil)
  (define-key paredit-mode-map (kbd "M-S") nil)
  (define-key paredit-mode-map (kbd "M-s") nil)
  (map! :nvi
        :desc "Fowrad word"
        "C-<right>" #'forward-word

        :desc "Backward word"
        "C-<left>" #'backward-word

        :desc "Forward barf"
        "M-<left>" #'paredit-forward-barf-sexp

        :desc "Forward slurp"
        "M-<right>" #'paredit-forward-slurp-sexp

        :desc "Backward slurp"
        "M-s <left>" #'paredit-backward-slurp-sexp

        :desc "Backward barf"
        "M-s <right>" #'paredit-backward-barf-sexp

        :desc "Split sexp"
        "M-s s" #'paredit-split-sexp

        :desc "Backward"
        "C-c <left>" #'paredit-backward

        :desc "Forward"
        "C-c <right>" #'paredit-forward))


;; Presentation
(defun org-present-bindings-start ()
  (map! :map org-present-mode-keymap

        :desc "Show cursor"
        "C-<up>" #'org-present-show-cursor

        :desc "Hide cursor"
        "C-<down>" #'org-present-hide-cursor

        :desc "Next slide"
        "C-<right>" #'org-present-next

        :desc "Previous slide"
        "C-<left>" #'org-present-prev))

(defun org-present-bindings-end ()
  (define-key org-present-mode-keymap (kbd "C-<up>") nil)
  (define-key org-present-mode-keymap (kbd "C-<down>") nil)
  (define-key org-present-mode-keymap (kbd "C-<right>") nil)
  (define-key org-present-mode-keymap (kbd "C-<left>") nil))


;; LSP doc additional features
(defun lsp-ui-doc-enable (enable)
  "Enable/disable ‘lsp-ui-doc-mode’.
  It is supposed to be called from `lsp-ui--toggle'"
  (lsp-ui-doc-mode (if enable 1 -1)))

(defun lsp-ui-doc-show ()
  "Trigger display hover information popup."
  (interactive)
  (let ((lsp-ui-doc-show-with-cursor t)
        (lsp-ui-doc-delay 0))
    (lsp-ui-doc--make-request)))

(defun lsp-ui-doc-hide ()
  "Hide hover information popup."
  (interactive)
  (lsp-ui-doc-unfocus-frame) ;; In case focus is in doc frame
  (lsp-ui-doc--hide-frame))

(defun lsp-ui-doc-toggle ()
  "Toggle hover information popup."
  (interactive)
  (if (lsp-ui-doc--visible-p)
      (lsp-ui-doc-hide)
    (lsp-ui-doc-show)))

(defun lsp-ui-doc-glance ()
  "Trigger display hover information popup and hide it on next typing."
  (interactive)
  (let ((lsp-ui-doc--hide-on-next-command t))
    (lsp-ui-doc-show)))

(when '(help-at-pt-timer-delay 0.1))
'(help-at-pt-display-when-idle '(lsp-ui-doc-show))

;; Switch buffers with SPC + arrow
;; :n is required for evil mode to overrite its key. Something to do with evil state being higher priority
(map! :n  "SPC <up>" #'evil-window-up)
(map! :n  "SPC <down>" #'evil-window-down)
(map! :n  "SPC <right>" #'evil-window-right)
(map! :n  "SPC <left>" #'evil-window-left)
