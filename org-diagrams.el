;;; org-diagrams.el --- Easily insert diagrams into your Org files -*- lexical-binding: t; -*-

(defvar org-diagrams-source-dir "./svg"
  "Source directory to watch for diagrams. NIL uses the default value (./svg), while a non-nil string sets the source directory to that path relative to the parent directory of the current file")

(defvar org-diagrams-dest-dir "./images"
  "Destination directory to export images. NIL uses the default value (./images), while a non-nil string sets the destination directory to that path relative to the parent directory of the current file")

(defvar org-diagrams-on-update nil ;"drawio -x -f png -o ${OUT} ${IN}"
  "Command to run when a diagram is created/changed. NIL uses the default command, which uses inkscape to export an svg to a png")

(defvar org-diagrams-editor "inkscape" ;"drawio"
  "Command to edit a diagram")

(defvar org-diagrams-watcher "diagon"
  "Command to start watcher")

(defvar org-diagrams-diagram-template nil
  "Path to template for new diagrams. If nil, opens a new blank diagram")

(defvar org-diagrams-insert-template "[[file:%s]]"
  "Template string used for inserting diagram")

(defvar org-diagrams-watched-dirs (make-hash-table :test 'equal)
  "Hash table of directories that are being watched currently and the number of files open for that directory, used to close watchers that are not in use")

(defun org-diagrams-build-watcher-args()
  (let ((args (list)))
    (setq args (push "-s" args))
    (setq args (push org-diagrams-source-dir args))
    (setq args (push "-d" args))
    (setq args (push org-diagrams-dest-dir args))
    (when org-diagrams-on-update
      (setq args (push "-u" args)
            args (push org-diagrams-on-update args)))
    (setq args (push "-f" args))
    (nreverse args)))

(defun org-diagrams-init ()
  (let ((root-path default-directory))
    (if (not (gethash root-path org-diagrams-watched-dirs))
        (progn
          (apply 'start-process (format "*org-diagrams watcher %d*" (hash-table-count org-diagrams-watched-dirs)) (format "*org-diagrams watcher %d*" (hash-table-count org-diagrams-watched-dirs)) org-diagrams-watcher (org-diagrams-build-watcher-args))
          (set-process-query-on-exit-flag (get-process (format "*org-diagrams watcher %d*" (hash-table-count org-diagrams-watched-dirs))) nil)
          (puthash root-path `(,(hash-table-count org-diagrams-watched-dirs) . 1) org-diagrams-watched-dirs))
      (puthash root-path `(,(car (gethash root-path org-diagrams-watched-dirs)) . ,(+ (cdr (gethash root-path org-diagrams-watched-dirs)) 1)) org-diagrams-watched-dirs))))

(defun org-diagrams-kill-buffer-hook ()
  (when (and buffer-file-name (equal (file-name-extension buffer-file-name) "org"))
    (let ((root-path default-directory))
      (puthash root-path `(,(car (gethash root-path org-diagrams-watched-dirs)) . ,(- (cdr (gethash root-path org-diagrams-watched-dirs)) 1)) org-diagrams-watched-dirs)
      (when (equal (cdr (gethash root-path org-diagrams-watched-dirs)) 0)
        (progn
          (kill-buffer (format "*org-diagrams watcher %d*" (car (gethash root-path org-diagrams-watched-dirs))))
          (remhash root-path org-diagrams-watched-dirs))))))

(add-hook 'kill-buffer-hook 'org-diagrams-kill-buffer-hook)

(defun org-diagrams-create (source-path)
  (when (and org-diagrams-diagram-template (not (file-exists-p source-path)))
    (copy-file org-diagrams-diagram-template source-path)))

(defun org-diagrams-edit (source-path)
  (progn
    (princ source-path)
    (start-process "" nil org-diagrams-editor source-path)))

(defun org-diagrams-insert (diagram-name)
  (let* ((diagram-path (concat (file-name-as-directory org-diagrams-dest-dir) diagram-name ".png")))
    (insert (format org-diagrams-insert-template diagram-path))))

(defun org-diagrams-insert-at-point-and-edit ()
  (interactive)
  (let* ((diagram-name (if (thing-at-point 'symbol)
                           (substring-no-properties (thing-at-point 'symbol))
                         nil))
         (bounds (bounds-of-thing-at-point 'symbol))
         (source-path (concat (expand-file-name (file-name-as-directory org-diagrams-source-dir)) diagram-name ".svg")))
    (if (not diagram-name)
        (message "Place point on name of diagram")
      (progn
        (when (file-exists-p source-path)
          (if (y-or-n-p "Diagram already exists. Create new?")
              (setq
               diagram-name (make-temp-name diagram-name)
               source-path (concat (expand-file-name (file-name-as-directory org-diagrams-source-dir)) diagram-name ".svg"))))
        (org-diagrams-create source-path)
        (delete-region (car bounds) (cdr bounds))
        (org-diagrams-insert diagram-name)
        (princ source-path)
        (org-diagrams-edit source-path)))))

(defun org-diagrams-edit-at-point ()
  (interactive)
  (let* ((diagram-path (if (thing-at-point 'filename)
                           (substring-no-properties (thing-at-point 'filename))
                         nil))
         source-path diagram-name)
    (if (not diagram-path)
        (message "Place point on link to diagram")
      (progn
        (setq
         diagram-name (file-name-base diagram-path)
         source-path (concat (expand-file-name (file-name-as-directory org-diagrams-source-dir)) diagram-name ".svg"))
        (if (not (file-exists-p source-path))
            (message "Diagram does not exist")
          (org-diagrams-edit source-path))))))

(provide 'org-diagrams)
;;; org-diagrams.el ends here
