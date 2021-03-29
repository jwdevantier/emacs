;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Jesper Devantier"
      user-mail-address "jesper.devantier@protonmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;(setq doom-theme 'doom-one)
(setq doom-theme 'doom-solarized-light)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
;; (setq display-line-numbers-type t)
;; vim-style relative line numbers
(setq display-line-numbers 'relative)

;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(defun cljfmt ()
  (interactive)
  (when (or (eq major-mode 'clojure-mode)
            (eq major-mode 'clojurescript-mode))
    (shell-command-to-string (format "clojure -A:cljfmt %s" buffer-file-name))
    (revert-buffer :ignore-auto :noconfirm)))

; increase font size, found example via 'describe variable'
(setq doom-font (font-spec :family "Ubuntu Mono" :size 20))

(defun on-cider-mode ()
        (setq cider-default-cljs-repl 'shadow)
        (setq cider-repl-pop-to-buffer-on-connect nil)
        (setq cider-repl-display-in-current-window t)
        (map! :leader
              :desc "format buffer"
              "b f" #'cider-format-buffer))

(add-hook 'cider-mode-hook 'on-cider-mode)

(defun parent-dir (path)
  ; returns parent directory of the given path
  ; NOTE: given "/" it returns "/"
  (file-name-directory (directory-file-name path)))

(defun path-join (a b &rest rest)
  ; joins paths together
  (cl-labels ((recur (a lst)
                     (if (eq nil lst)
                         a
                       (recur
                        (concat (file-name-as-directory a) (car lst))
                        (cdr lst)))))
    (recur a (cons b rest))))

(defun file-search-bottom-up (root-dir start-dir fname)
  (let ((root-dir (directory-file-name root-dir))
        (start-dir (directory-file-name start-dir)))
    (cl-labels ((recur (curr-dir)
                       (message "file-search-bottom-up::recur")
                       (message (format "lookup dir: %s (root: %s)" curr-dir root-dir))
                       (let ((path (path-join curr-dir fname)))
                         (message (format "exists? %s" path))
                         (if (file-exists-p path)
                             path
                           (when (not (string= root-dir curr-dir))
                             (recur (directory-file-name (parent-dir curr-dir))))))))
      (recur start-dir))))


(defun fmt-astyle ()
  (interactive)
  ; TODO: could enable support for all the modes astyle itself supports
  (if (not (eq major-mode 'c-mode))
      (error "not in c-mode -- command is only intended to fmt c-files")
    (let ((bname (buffer-file-name)))
      (if (not bname)
          (error "buffer has no associated file - maybe try saving first?")
        (let ((astylerc-path (file-search-bottom-up (projectile-project-root)
                                                    (parent-dir bname)
                                                    "astylerc")))
          (if (not astylerc-path)
              (error "could not find any asyncrc file in path from file to project root")
            (progn
              (save-buffer)
              (shell-command-to-string (format "astyle --options=\"%s\" %s"
                                               astylerc-path
                                               bname))
              (revert-buffer :ignore-auto :noconfirm))))))))


(defun -c-mode-fmt-old ()
  ; TODO: should pick other formatters if project is configured differently
  ; format C-code with `astyle'
  (interactive)
  (when (or (eq major-mode 'c-mode))
    (shell-command-to-string (format "astyle %s" buffer-file-name))
    (revert-buffer :ignore-auto :noconfirm)))

(defun on-c-mode ()
  (map! :leader
        :desc "format buffer"
        "b f" #'fmt-astyle))

(add-hook 'c-mode-hook 'on-c-mode)
