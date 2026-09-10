;;; brewpage.el --- Publish buffers/regions to brewpage.app -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Maksim Kochetkov

;; Author: Maksim Kochetkov <maksim.kochetkov@finagra.com>
;; Assisted-by: Claude Code:claude-opus-5
;; Maintainer: Maksim Kochetkov <maksim.kochetkov@finagra.com>
;; Version: 0.1.1
;; URL: https://github.com/kochetkov-ma/brewpage-emacs
;; Package-Requires: ((emacs "27.1"))
;; Keywords: tools, convenience
;; SPDX-License-Identifier: MIT

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;; THE SOFTWARE.

;;; Commentary:

;; Publish Emacs buffers or regions to brewpage.app, a simple pastebin service.
;; After publishing, the generated URL is copied to the kill ring and displayed
;; in the minibuffer for easy sharing.
;;
;; Usage:
;;   M-x brewpage-publish-region    - Publish selected region
;;   M-x brewpage-publish-buffer    - Publish entire buffer
;;
;; Configuration:
;;   (setq brewpage-api-endpoint "https://brewpage.app/api/html")
;;   (setq brewpage-namespace "public")  ; can be customized per publish

;;; Code:

(require 'json)
(require 'url)

(defgroup brewpage nil
  "Publish buffers and regions to brewpage.app."
  :group 'tools
  :prefix "brewpage-")

(defcustom brewpage-api-endpoint "https://brewpage.app/api/html"
  "The brewpage.app API endpoint for publishing HTML."
  :type 'string
  :group 'brewpage)

(defcustom brewpage-namespace "public"
  "The default namespace to publish to."
  :type 'string
  :group 'brewpage)

(defcustom brewpage-copy-to-clipboard t
  "If non-nil, copy the published URL to the `kill-ring'."
  :type 'boolean
  :group 'brewpage)

;;;###autoload
(defun brewpage-publish-region (start end)
  "Publish the region between START and END to brewpage.app.
The generated URL is copied to the `kill-ring' and displayed in
the minibuffer."
  (interactive "r")
  (let* ((content (buffer-substring-no-properties start end))
         ;; `url-request-data' must be unibyte: url.el refuses to send a
         ;; multibyte request body.
         (json-payload (encode-coding-string
                        (json-encode `(("content" . ,content)
                                       ("ns" . ,brewpage-namespace)))
                        'utf-8))
         (url-request-method "POST")
         (url-request-extra-headers
          '(("Content-Type" . "application/json; charset=utf-8")))
         (url-request-data json-payload)
         (buffer (progn (message "Publishing to brewpage.app...")
                        (url-retrieve-synchronously brewpage-api-endpoint t t)))
         response-data)
    (unless buffer
      (error "No response from %s" brewpage-api-endpoint))
    (unwind-protect
        (with-current-buffer buffer
          (goto-char (point-min))
          (search-forward "\n\n" nil t)
          ;; The response body is raw bytes; decode before parsing.
          (setq response-data
                (json-read-from-string
                 (decode-coding-string
                  (buffer-substring-no-properties (point) (point-max))
                  'utf-8))))
      (kill-buffer buffer))
    (let ((link (cdr (assq 'link response-data))))
      (if link
          (progn
            (when brewpage-copy-to-clipboard
              (kill-new link))
            (message "Published to: %s" link))
        (message "Failed to parse response: %s" response-data)))))

;;;###autoload
(defun brewpage-publish-buffer ()
  "Publish the entire buffer to brewpage.app."
  (interactive)
  (brewpage-publish-region (point-min) (point-max)))

(provide 'brewpage)
;;; brewpage.el ends here
