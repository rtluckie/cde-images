if [[ -d "/home/linuxbrew/.linuxbrew" ]] && [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
fi