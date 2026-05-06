# brewpage-emacs

Publish Emacs buffers and regions to [brewpage.app](https://brewpage.app) directly from your editor.

## Installation

### Via MELPA

Once this package is accepted into MELPA, install via:

```elisp
(use-package brewpage
  :ensure t)
```

Or with `straight.el`:

```elisp
(use-package brewpage
  :straight (:host github :repo "kochetkov-ma/brewpage-emacs"))
```

### Manual

Clone this repository and add to your `load-path`:

```elisp
(add-to-list 'load-path "~/.emacs.d/lisp/brewpage-emacs")
(require 'brewpage)
```

## Usage

### Commands

- `M-x brewpage-publish-buffer` — Publish the entire buffer
- `M-x brewpage-publish-region` — Publish the selected region

After publishing, the generated URL is automatically copied to your kill-ring and displayed in the minibuffer.

### Configuration

```elisp
(use-package brewpage
  :custom
  (brewpage-api-endpoint "https://brewpage.app/api/html")
  (brewpage-namespace "public")
  (brewpage-copy-to-clipboard t))
```

- `brewpage-api-endpoint` — The API endpoint (default: `https://brewpage.app/api/html`)
- `brewpage-namespace` — Default namespace for publishing (default: `public`)
- `brewpage-copy-to-clipboard` — Copy URL to kill-ring after publishing (default: `t`)

## Requirements

- Emacs 27.1+
- No external dependencies (uses built-in `url.el`)

## License

MIT — See LICENSE file

## About brewpage.app

[brewpage.app](https://brewpage.app) is a simple, privacy-respecting pastebin service. Share code, notes, and text with short URLs and optional expiration.
