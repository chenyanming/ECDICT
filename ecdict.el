;;; ecdict/ecdict.el -*- lexical-binding: t; -*-


(defvar ecdict-running-process nil)

;;;###autoload
(defun ecdict-stop-process ()
  (interactive)
  (when (process-live-p ecdict-running-process )
    (stop-process ecdict-running-process)
    (setq ecdict-running-process nil)))



(defun ecdict-process-filter (proc string)
  "Accumulates the strings received from the ECDICT process."
  (with-current-buffer (process-buffer proc)
    (insert string)))

(defun ecdict-process-sentinel (proc _event)
  "Handles the ecdict process termination event."
  (when (eq (process-status proc) 'exit)
    (let* ((json-object-type 'plist)
           (json-array-type 'list)
           (buffer-content (with-current-buffer (process-buffer proc)
                             (buffer-string)))
           (json-responses (json-read-from-string buffer-content)))
      (dolist (resp json-responses)
        (let* ((id (plist-get resp :id))
               (word (plist-get resp :word))
               (sw (plist-get resp :sw))
               (phonetic (plist-get resp :phonetic))
               (definition (plist-get resp :definition))
               (translation (plist-get resp :translation))
               (pos (plist-get resp :pos))
               (collins (plist-get resp :collins))
               (oxford (plist-get resp :oxford))
               (tag (plist-get resp :tag))
               (bnc (plist-get resp :bnc))
               (frq (plist-get resp :frq))
               (exchange (plist-get resp :exchange))
               (detail (plist-get resp :detail))
               (audio (plist-get resp :audio)))
          (message "id: %s, word: %s, sw: %s, phonetic: %s, definition: %s, translation: %s, pos: %s, collins: %s, oxford: %s, tag: %s, bnc: %s, frq: %s, detail: %s, audio: %s"
                   id word sw phonetic definition translation pos collins oxford tag bnc frq detail audio)))
      ;; (let ((segmented-text (mapconcat
      ;;                        (lambda (resp) (plist-get resp :surface))
      ;;                        json-responses
      ;;                        " ")))
      ;;   (message "Segmented text: %s" segmented-text))
      ;; (pp buffer-content)
      ;; (pp json-responses)

      )))

(defun ecdict-command (string &optional sentinel)
  "Segments a STRING of Japanese text using ECDICT and logs the result asynchronously."
  (ecdict-stop-process)
  (let* ((original-output-buffer (get-buffer "*ecdict-output*"))
         (output-buffer (if (buffer-live-p original-output-buffer)
                            (progn (kill-buffer original-output-buffer)
                                   (get-buffer-create "*ecdict-output*") )
                          (get-buffer-create "*ecdict-output*") ))
         (ecdict-process (make-process
                          :name "ECDICT"
                          :buffer output-buffer
                          :command `("python" ,(expand-file-name "modules/ECDICT/stardict.py" doom-private-dir) ,string)
                          :filter 'ecdict-process-filter
                          :sentinel (if sentinel sentinel 'ecdict-process-sentinel))))
    (setq ecdict-running-process ecdict-process)
    (with-current-buffer output-buffer
      (setq-local original-string string))
    (process-send-eof ecdict-process)))

(provide 'ecdict)
