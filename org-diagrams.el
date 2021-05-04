;;; org-diagrams.el --- Easily insert diagrams into your Org files -*- lexical-binding: t; -*-

(defvar org-diagrams-source-dir "./svg"
  "Source directory to watch for diagrams. NIL uses the default value (./svg), while a non-nil string sets the source directory to that path relative to the parent directory of the current file")

(defvar org-diagrams-dest-dir "./images"
  "Destination directory to export images. NIL uses the default value (./images), while a non-nil string sets the destination directory to that path relative to the parent directory of the current file")

(defvar org-diagrams-on-update nil
  "Command to run when a diagram is created/changed. NIL uses the default command")

(defvar org-diagrams-editor "inkscape"
  "Command to edit a diagram")

(defvar org-diagrams-diagram-template "./default_template.svg"
  "Path to template for new diagrams")

(defvar org-diagrams-insert-template "[[file:%s]]"
  "Template string used for inserting diagram")

(defun org-diagrams-create (source-path)
  (when (not (file-exists-p source-path))
    (copy-file org-diagrams-diagram-template source-path)))

(defun org-diagrams-edit (diagram-path)
  (start-process "" nil org-diagrams-editor diagram-path))

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
