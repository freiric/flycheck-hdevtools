;;; flycheck-hdevtools.el --- A flycheck checker for Haskell using hdevtools

;; Copyright (C) 2013  Steve Purcell

;; Author: Steve Purcell <steve@sanityinc.com>
;; URL: https://github.com/flycheck/flycheck-hdevtools
;; Keywords: convenience languages tools
;; Package-Requires: ((flycheck "0.15"))
;; Version: DEV

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Adds a Flycheck syntax checker for Haskell based on hdevtools.

;;;; Setup

;; (eval-after-load 'flycheck '(require 'flycheck-hdevtools))

;;; Code:

(require 'flycheck)
(require 'haskell-cabal)

;;;###autoload
(defun flycheck-hdevtools-setup ()
  "Setup Cabal/GHC integration for Flycheck.

If the current file is part of a Cabal project and there is a .ghc-options file,
as denoted by the existence of a Cabal and .ghc-options file in the file's
directory or any ancestor thereof, change to cabal directory and pass the
options in .ghc-options to hdevtools.

Set `flycheck-haskell-options-finder' accordingly."
  (setq flycheck-haskell-options-finder
	(eval '(ghc-options-finder)))
)

(defun ghc-options-finder ()
  "Change to cabal directory and return the options list found in .ghc-options.

Find a Cabal and a .ghc-options file in some superdirectory, change to the
directory of the Cabal file and read the ghc options into a list.
Returns this options list."
(when (buffer-file-name)
    (-when-let* ((file (haskell-cabal-find-file))
		 (cabal-dir (when file (file-name-directory file)))
		 (root-dir (locate-dominating-file (buffer-file-name) ".ghc-options"))
		 (ghc-options-file (concat root-dir ".ghc-options"))
		 (options-buffer (find-file-noselect ghc-options-file))
		 (ghc-options (with-current-buffer options-buffer
				(split-string (buffer-string))))
                 ;; (hdevtools-options
                 ;;  (mapcar (lambda (s) (concat "-g" s))  ghc-options))
		 )
      (cd cabal-dir)
      ;; (message "ghc options found: %S" ghc-options)
      ;; (message "hdevtools options found: %S" hdevtools-options)
      ghc-options
      )))


(flycheck-def-option-var flycheck-haskell-options-finder nil haskell-hdevtools
  "Function retrieving ghc options to use for hdevtools.

The value of this option is a function returning list of options to be passed to hdevtools."
  :type '(function :tag "haskell options")
  :safe #'stringp
  :package-version '(flycheck . "0.15"))


(flycheck-define-checker haskell-hdevtools
  "A Haskell syntax and type checker using hdevtools.

See URL `https://github.com/bitc/hdevtools'."
  :command ("hdevtools" "check"
            (eval (flycheck-prepend-with-option "-g" flycheck-haskell-options-finder))
	    "-g" "-Wall" source-inplace)
  :error-patterns
  ((warning line-start (file-name) ":" line ":" column ":"
            (or " " "\n    ") "Warning:" (optional "\n")
            (one-or-more " ")
            (message (one-or-more not-newline)
                     (zero-or-more "\n"
                                   (one-or-more " ")
                                   (one-or-more not-newline)))
            line-end)
   (error line-start (file-name) ":" line ":" column ":"
          (or (message (one-or-more not-newline))
              (and "\n" (one-or-more " ")
                   (message (one-or-more not-newline)
                            (zero-or-more "\n"
                                          (one-or-more " ")
                                          (one-or-more not-newline)))))
          line-end))
  :modes haskell-mode
  :next-checkers ((warnings-only . haskell-hlint)))


(add-to-list 'flycheck-checkers 'haskell-hdevtools)


(provide 'flycheck-hdevtools)
;;; flycheck-hdevtools.el ends here
