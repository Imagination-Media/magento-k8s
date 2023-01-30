export LANG='en_US.UTF-8'
export LANGUAGE='en_US:en'
export LC_ALL='en_US.UTF-8'
export TERM=xterm

##### Zsh/Oh-my-Zsh Configuration
export ZSH="/var/www/.oh-my-zsh"

ZSH_THEME="spaceship-prompt/spaceship"
plugins=(git zsh-autosuggestions zsh-completions )


SPACESHIP_PROMPT_ADD_NEWLINE="false"
SPACESHIP_PROMPT_SEPARATE_LINE="false"
source $ZSH/oh-my-zsh.sh