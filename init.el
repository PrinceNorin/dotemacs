;;;
;;; User define variables
;;;

;; Custom user directory
(setq n-user-dir
      (file-name-directory
       (or load-file-name (buffer-file-name))))

;; Custom theme directory
(setq n-custom-theme-paths
      '("themes" "elpa/emacs-color-theme-solarized"))

;; Custom backup directory
(setq custom-backup-directory
      (file-name-concat n-user-dir "backup"))

(setq custom-auto-save-directory
      (file-name-concat n-user-dir "auto-save-list"))


;;;
;;; General settings
;;;

;; Remove toolbar, menu and scroll
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

;; Disable bell sound
(setq visible-bell 1)

;; Maximize on startup
(defun maximize-frame ()
  "Maximizes the active frame in Windows"
  (interactive)
  (when (eq system-type 'windows-nt)
	(w32-send-sys-command 61488)))
(add-hook 'window-setup-hook 'maximize-frame t)

;; Disable splash screen
(setq inhibit-startup-screen t)
(add-hook 'emacs-startup-hook
          (lambda ()
            (let* ((buffer-text (get-buffer-create "*Startup*")))
              (calendar)
              (goto-char 0)
              (toggle-truncate-lines)
              (delete-other-windows))))

;; Global tab setting
(setq-default c-basic-offset 4)
(setq-default tab-width 4)
(setq-default indent-tabs-mode nil)

;; Highlight current line
(global-hl-line-mode)

;; Disable byte compile warning on unescaped single quotes
(setq byte-compile-warnings '(not docstrings))

;; Change GUI font
(defun font-available-p (font-name)
  (find-font (font-spec :name font-name)))

(cond
 ((font-available-p "Iosevka NFM")
  (set-frame-font "Iosevka NFM 12" nil t))
 ((font-available-p "Inconsolata Nerd Font Mono")
  (set-frame-font "Inconsolata Nerd Font Mono 12" nil t))
 ((font-available-p "FiraMono Nerd Font")
  (set-frame-font "FiraMono Nerd Font 12" nil t)))

;; Move backup files to one location
(unless (file-exists-p custom-backup-directory)
  (make-directory custom-backup-directory t))
(setq backup-directory-alist `((".*" . ,custom-backup-directory)))

(unless (file-exists-p custom-auto-save-directory)
  (make-directory custom-auto-save-directory t))
(setq auto-save-file-name-transforms
      `((".*" ,custom-auto-save-directory t)))

(setq delete-old-version t
      kept-new-version 2
      kept-old-version 2
      version-control t)


;;;
;;; Setup package management
;;;

;; Enable emacs built-in
(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://stable.melpa.org/packages/"))

;; Initialize built-in package management
(package-initialize)

;; Update package list if we are on a new install
(unless package-archive-contents
 (package-refresh-contents))

;; A list of packages to install
;; ensure installed via package.el
(setq required-packages '(use-package))
(dolist (package required-packages)
  (unless (package-installed-p package)
    (package-install package)))

;; Enable use-package
(eval-when-compile
  (require 'use-package)
  (require 'use-package-ensure)
  (setq use-package-always-ensure t))

;; Load env variables from shell
(use-package exec-path-from-shell
  :when (memq window-system '(mac ns x))
  :config
  (exec-path-from-shell-initialize))

;;;
;;; Better completion
;;;

;; Setup vertico
(use-package vertico
  :init
  (vertico-mode))

;; Orderless cpmpletion style
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))


;; Load custom theme paths
(dolist (path n-custom-theme-paths)
  (add-to-list 'custom-theme-load-path (file-name-concat n-user-dir path)))

;; Load theme
;; (load-theme 'solarized t)
(load-theme 'doom-spacegrey t)


;;
;; Startup screen
;;

(use-package enlight
  :custom
  (enlight-content
   (concat
    (propertize "MENU" 'face 'highlight)
    "\n"
    (enlight-menu
     '(("Other"
        ("Projects" project-switch-project "p")))))))


;;;
;;; Syntax highlight
;;;

(setq treesit-language-source-alist
      '((bash "https://github.com/tree-sitter/tree-sitter-bash")
	(css "https://github.com/tree-sitter/tree-sitter-css")
	(elisp "https://github.com/Wilfred/tree-sitter-elisp")
	(go "https://github.com/tree-sitter/tree-sitter-go")
	(gomod "https://github.com/camdencheek/tree-sitter-go-mod")
	(json "https://github.com/tree-sitter/tree-sitter-json")
	(tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
	(typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
	(python "https://github.com/tree-sitter/tree-sitter-python")
	(ruby "https://github.com/tree-sitter/tree-sitter-ruby")
	(rust "https://github.com/tree-sitter/tree-sitter-rust")
	(c "https://github.com/tree-sitter/tree-sitter-c")
	(c++ "https://github.com/tree-sitter/tree-sitter-cpp")
	(html "https://github.com/tree-sitter/tree-sitter-html")
	(javascript "https://github.com/tree-sitter/tree-sitter-javascript")
	(make "https://github.com/alemuller/tree-sitter-make")
	(toml "https://github.com/tree-sitter/tree-sitter-toml")
	(yaml "https://github.com/ikatyang/tree-sitter-yaml")))

(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

;; Go settings
(defun eglot-go-imports()
  (interactive)
  (eglot-code-actions nil nil "source.organizeImports" t))

(defun eglot-go-format()
  (pcase (file-name-extension (buffer-file-name))
	("go" (eglot-format))))

(defun custom-go-settings()
  (eglot-ensure)
  (setq-default c-basic-offset 4
		tab-width 4
		indent-tabs-mode t
		go-ts-mode-indent-offset 4)
  (add-hook 'after-save-hook 'eglot-go-format)
  (add-hook 'before-save-hook 'eglot-go-imports nil t))

;; Go template file extension
(add-to-list 'auto-mode-alist '("\\.tmpl\\'" . go-ts-mode))

;; YAML settings
(defun custom-yaml-settings()
  (eglot-ensure)
  (setq tab-width 2
        c-basic-offset 2
        indent-tabs-mode nil
        yaml-ts-mode-indent-offset 2))

(use-package eglot
  :defer t
  :hook ((go-ts-mode . custom-go-settings)
         (yaml-ts-mode . custom-yaml-settings)))

(use-package company
  :after eglot
  :hook (eglot-managed-mode . company-mode))


;; Generated by emacs, do not edit

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("ae426fc51c58ade49774264c17e666ea7f681d8cae62570630539be3d06fd964" "e3daa8f18440301f3e54f2093fe15f4fe951986a8628e98dcd781efbec7a46f2" default))
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
