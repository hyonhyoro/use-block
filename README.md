# use-block

The `use-block` merges all Emacs Lisp source code blocks in Org mode
into `use-package` expressions

## Motivation

When you write the Emacs configuration file in Org mode
with [use-package](https://github.com/jwiegley/use-package),

``` org
* Org mode configuration
#+begin_src emacs-lisp
(use-package org
  :defer t
  :config
  ;; Many comments about todo, capture, agenda, tag, column, clock etc.
  (setq ...)
  ...
  )
#+end_src
```

in spite of Literate Programming, it's unavoidable that comments are
embedded into the source code blocks because all the configurations
have to be packed into one `use-package` expression.  And it's tiring
to surround all blocks with `use-package` or `eval-after-load` if all
of them are divided into some extent.

## Usage

`use-block` adds two header arguments to the Emacs Lisp source code
blocks.

  - `:pre-init` *PACKAGE*

    the source code block is evaluated before *PACKAGE* is loaded.

  - `:post-init` *PACKAGE*

    the source code block is evaluated after *PACKAGE* is loaded.

If you write `config.org`

``` org
* config.org
** Org mode configuration
#+begin_src emacs-lisp
(use-package org
  :defer t
  :mode ("\\.\\(org\\|org_archive\\)\\'" . org-mode))

(use-package org-agenda :defer t)
#+end_src

org-mode startup layout
#+begin_src emacs-lisp :post-init org
(setq org-startup-folded 'content)

(setq org-startup-indented t)
#+end_src

org-agenda keybinds
#+begin_src emacs-lisp :pre-init org-agenda
(bind-key "C-c a" 'org-agenda)
#+end_src
```

and load by the function `use-block-load-file`,

``` emacs-lisp
(use-block-load-file "config.org")
```

Emacs Lisp file `config.el` is exported and loaded.

``` emacs-lisp
;; config.el
(use-package org
  :defer t
  :mode ("\\.\\(org\\|org_archive\\)\\' . org-mode)
  :init
  :config
  (setq org-startup-folded 'content)
  (setq org-startup-indented t))

(use-package org-agenda
  :defer t
  :init
  (bind-key "C-c a" 'org-agenda)
  :config)
```

Note that expressions other than use-package expressions in code
blocks without header arguments such as `:pre-init` and `:post-init`
are exported as is.
