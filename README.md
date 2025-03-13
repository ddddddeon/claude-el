# claude.el

Claude-assisted editing in emacs

## Installation

Clone the repo and add the path to your init script, and set keybindings if you like:
```elisp
(add-to-list 'load-path "~/path/to/claude-el")
(require 'claude)

(global-set-key (kbd "C-c ]") 'claude-prompt-new-pane)
(global-set-key (kbd "C-c \\") 'claude-prompt-inline)
(global-set-key (kbd "C-c '") 'claude-autocomplete)
```

## Usage
There are three main ways to interact with claude.el:
1. `claude-prompt-inline`: Input a prompt and insert the response into the current buffer. Good for "editing" a selected region. If no region is selected, the contents of the entire file are sent to Claude as context, and the response is inserted at the cursor.
2. `claude-prompt-new-pane`: Display the response to a prompt in a new pane. If a region is selected, it is sent as context, otherwise the entire file is sent.
3. `claude-autocomplete`: Copilot-style autocomplete. Takes the current line and the preceding 10 lines and sends them as context. 
