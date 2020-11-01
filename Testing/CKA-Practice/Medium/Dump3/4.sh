k -n dump3 create deployment nginx --image=nginx --dry-run -o yaml > 4.yaml
k -n dump3 create -f 4.yaml --record
k -n dump3 scale deployment nginx --replicas=4 --record
k -n dump3 get all
k -n dump3 scale deployment nginx --replicas=2 --record
k -n dump3 get all
k -n dump3 set image deployment/nginx nginx=nginx:1.13.8 --record
k -n dump3 rollout status deployment nginx
k -n dump3 rollout history deployment nginx
k -n dump3 rollout undo deployment nginx
k -n dump3 rollout status deployment nginx
k -n dump3 rollout history deployment nginx
