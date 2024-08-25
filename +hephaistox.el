;;; hephaistox.el -*- lexical-binding: t; -*-

(defgroup hephaistox nil
  "Hephaistox Interface"
  :group 'external)

(defcustom hephaistox-async-shell-command #'async-shell-command
  "Emacs function to run shell commands."
  :group 'hephaistox
  :type 'function
  :safe #'functionp)

(defun hephaistox--locate-subproject
    (&optional dir)
  "Recursively search upwards from DIR for build_config.edn file."
  (if-let (found (locate-dominating-file (or dir default-directory) "build_config.edn"))
      found
    (progn
      (message "Can't format the project as `build_config.edn' has not been found in the directory hierarchy")
      nil)))

(defun success
    ()
  (minibuffer-message "This buffer complies hephaistox rules"))

(defun error-found
    (&optional msg)
  (minibuffer-message "This buffer doesn't comply to hephaistox rules")
  (when msg
    (let ((buff-name (make-temp-name "hephaistox"))
          (default-directory (clojure-project-dir)))
      (switch-to-buffer buff-name)
      (process-file "bb"
                    nil
                    buff-name
                    nil
                    "ide"))))

(defun hephaistox--run-shell-command-in-directory (directory command)
  "Run a shell COMMAND in a DIRECTORY and display output in OUTPUT-BUFFER."
  (let ((default-directory directory))
    (funcall hephaistox-async-shell-command command)))

(defun hephaistox--run-ide-task-as-sync
    ()
  "Execute the bb ide in an async mode"
  (when-let ((dir (hephaistox--locate-subproject)))
    (let ((res (process-file "bb"
                             nil
                             nil
                             nil
                             "ide")))
      (revert-buffer :ignore-auto :noconfirm)
      (if (= 0 res)
          (success)
        (error-found res)))))

(defun hephaistox--run-ide-task-as-async
    ()
  "Execute the bb ide in an async mode"
  (when-let ((dir (hephaistox--locate-subproject)))
    (hephaistox--run-shell-command-in-directory (clojure-project-dir)
                                                "bb ide")))

(defun call-hephaistox
    ()
  (interactive)
  (unwind-protect
      (hephaistox--run-ide-task-as-async)))

(map! "C-M-;" #'babashka-project-tasks)
