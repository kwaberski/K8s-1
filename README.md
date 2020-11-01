# K8s
# Alias & Bash completion 

echo 'source <(kubectl completion bash)' >>~/.bashrc

echo 'alias k=kubectl' >>~/.bashrc

echo 'complete -F __start_kubectl k' >>~/.bashrc

# Vim YAML editing

echo “autocmd FileType yaml setlocal nu ic expandtab sw=2 ts=2 sts=2” >> ~/.vimrc
