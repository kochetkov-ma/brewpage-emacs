;;; brewpage.el --- Publish buffers/regions to brewpage.app -*- lexical-binding: t; -*-

;; Author: Maxim Kochetkov
;; Version: 0.1.0
;; URL: https://github.com/kochetkov-ma/brewpage-emacs
;; Package-Requires: ((emacs "27.1"))
;; Keywords: tools, convenience
;; License: MIT

;;; Commentary:

;; Publish Emacs buffers or regions to brewpage.app, a simple pastebin service.
;; After publishing, the generated URL is copied to the kill-ring and displayed
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
  "If non-nil, copy the published URL to the kill-ring."
  :type 'boolean
  :group 'brewpage)

(defun brewpage-publish-region (start end)
  "Publish the region between START and END to brewpage.app.
The generated URL is copied to the kill-ring and displayed in the minibuffer."
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
         response-data)
    (message "Publishing to brewpage.app...")
    (with-current-buffer
        (url-retrieve-synchronously brewpage-api-endpoint t t)
      (goto-char (point-min))
      (search-forward "\n\n" nil t)
      (let ((json-response (json-read)))
        (setq response-data
              (if (consp json-response) json-response
                (and (stringp json-response) (json-read-from-string json-response))))))
    (when response-data
      (let ((url (cdr (assq 'url response-data))))
        (if url
            (progn
              (when brewpage-copy-to-clipboard
                (kill-new url))
              (message "Published to: %s" url))
          (message "Failed to parse response: %s" response-data))))))

(defun brewpage-publish-buffer ()
  "Publish the entire buffer to brewpage.app."
  (interactive)
  (brewpage-publish-region (point-min) (point-max)))

(provide 'brewpage)
;;; brewpage.el ends here
