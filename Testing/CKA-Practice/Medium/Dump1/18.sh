# describe the service webservice to see what selector is used
k -n dump1 describe service webservice
Name:              webservice
Namespace:         dump1
Labels:            ques=prob2
Annotations:       kubernetes.io/change-cause:
                     kubectl create --kubeconfig=/Users/kwaberski/.kube/config-local --namespace=dump1 --fil
ename=2.yaml --record=true
Selector:          ques=prob1
Type:              ClusterIP
IP:                10.101.254.251
Port:              httpo  80/TCP
TargetPort:        80/TCP
Endpoints:         172.16.98.8:80
Port:              https  443/TCP
TargetPort:        443/TCP
Endpoints:         172.16.98.8:443
Session Affinity:  None
Events:            <none>

# now that we know it is ques=prob1
# get all pods with with label
k -n dump1 get pods -l ques=prob1
NAME   READY   STATUS    RESTARTS   AGE
web    1/1     Running   1          3d
