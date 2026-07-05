# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source ~/.local/share/omarchy/default/bash/rc

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'
alias c='opencode --port'

alias wg-open='sudo wg-quick down wg1 2>/dev/null; sudo wg-quick up wg0'
alias wg-full='sudo wg-quick down wg0 2>/dev/null; sudo wg-quick up wg1'
alias wg-off='sudo wg-quick down wg0 2>/dev/null; sudo wg-quick down wg1 2>/dev/null; echo "wg off"'
alias wg-status='sudo wg show'

