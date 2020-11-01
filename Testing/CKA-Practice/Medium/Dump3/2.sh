k create namespace dump3
k -n dump3 create -f 2.yaml
k -n dump3 get pods -o wide
