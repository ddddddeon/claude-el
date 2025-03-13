;;; claude.el --- Claude-assisted editing in emacs  -*- lexical-binding: t; -*-

;; Author: Chris d'Eon 
;; Version: 0.1
;; Package-Requires: ((emacs "24.1"))
;; Keywords: claude, llm, copilot
;; URL: https://github.com/ddddddeon/claude-el

;;; Commentary:
;; Claude-assisted editing in emacs

(defvar claude-inline-prompt "you are a code editor. you receive blocks of code followed by a prompt. you are ONLY to output the code changes requested. you are not to speak any human language EVER, nor are you to EVER wrap the code in any kind of quotations, backticks, delimiters or commentary whatsoever. your system will completely crash and the building you are in will catch fire if you EVER emit anything other than just the code.")

(defvar claude-new-pane-prompt "you are a senior software engineer coding assistant, and you are given whole files of code, and you answer questions about the code and/or offer suggestions for code changes when asked. give good answers but don't be too chatty. just give relevant information concisely. if needed the user will ask follow-up questions. the following is the code file, followed by a question about it:")

(defvar claude-autocomplete-prompt "you are a senior software engineer who is tasked with pair programming with the user. please complete the code you are shown, so that it accomplishes what seems to be the goal given the context you have. ONLY display the code completion, and do NOT under any circumstances speak human language, or wrap the code in any kind of quotations or delimiters. ONLY complete the immediate task at hand-- do NOT try to complete the entire file. If you speak human language or go beyond the task at hand, you will crash and your hardware will catch fire, injuring dozens.")


(defun claude-split-pane ()
    (interactive)
    (if (> (/ (window-width) 2) (window-height))
        (split-window-right)
        (split-window-below))
    (other-window 1))


(defun claude-post-http (url data)
  (let* ((url-request-method "POST")
         (url-request-extra-headers
          `(("x-api-key" . ,(getenv "ANTHROPIC_API_KEY"))
             ("anthropic-version" . "2023-06-01")
             ("content-type" . "application/json")))
         (url-request-data (json-encode data)))
    (let ((response-buffer (url-retrieve-synchronously url)))
      (with-current-buffer response-buffer
        (goto-char (point-min))
        (re-search-forward "\n\n")
        (let ((content (buffer-substring-no-properties (point) (point-max))))
          (kill-buffer response-buffer)
          content)))))

(defun claude-make-request (message)
   (claude-post-http
    "https://api.anthropic.com/v1/messages"
    `((model . "claude-3-7-sonnet-20250219")
      (max_tokens . 4096)
      (messages . [((role . "user")
                    (content . ,message))]))))

(defun claude-parse-response (response)
  (let* ((json-data (json-parse-string response :object-type 'alist))
         (content (cdr (assoc 'content json-data)))
         (text-object (seq-find (lambda (obj)
                                  (string= (cdr (assoc 'type obj)) "text"))
                                content))
         (text (cdr (assoc 'text text-object))))
  text))

(defun claude-prompt (prompt replace-p inline-p)
  (let* ((system (if inline-p
                     claude-inline-prompt
                   claude-new-pane-prompt))
         (code
          (if (use-region-p)
              (buffer-substring (region-beginning) (region-end))
            (buffer-string)))
         (prompt-with-code (concat system "\n" code "\n" prompt))
         (response (claude-parse-response (claude-make-request prompt-with-code))))
    (progn
      (when replace-p
        (if (use-region-p)
            (delete-region (region-beginning) (region-end))
          (delete-region (point-min) (point-max))))
      (when (not inline-p)
        (get-buffer-create "claude")
        (claude-split-pane)
        (switch-to-buffer "claude"))
      (insert (concat response "\n")))))

;;;###autoload
(defun claude-prompt-inline (prompt)
  (interactive "s> ")
  (claude-prompt prompt t t))

;;;###autoload
(defun claude-prompt-new-pane (prompt)
  (interactive "s> ")
  (claude-prompt prompt nil nil))

;;;###autoload
(defun claude-autocomplete ()
  (interactive)
  (let* ((current-line (line-number-at-pos))
         (current-pos (point))
         (start-pos (save-excursion
                     (goto-char (point-at-bol))
                     (point)))
         (context-start (save-excursion
                         (goto-char (point))
                         (forward-line -9)
                         (if (< (point) (point-min))
                             (point-min)
                           (point))))
         (end-point nil))
    (save-excursion
      (let ((region-text (buffer-substring context-start start-pos))
            (current-text (buffer-substring start-pos current-pos)))
        (goto-char start-pos)
        (delete-region start-pos current-pos)
        (claude-prompt 
         (concat 
          claude-autocomplete-prompt
          region-text 
          current-text) 
         nil t)
        (setq end-point (point))))
    (when end-point
      (goto-char end-point))))

(provide 'claude)

;;; claude.el ends here
