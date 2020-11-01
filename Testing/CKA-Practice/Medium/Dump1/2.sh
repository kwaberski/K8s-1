# just run
k -n dump1 expose pod web --port=80,443 --name=webservice --labels ques=prob2
# if you want to get the YAML spec
k -n dump1 expose pod web --port=80,443 --name=webservice --labels ques=prob2 --dry-run -o yaml

apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    ques: prob2
  name: webservice
spec:
  ports:
  - name: port-1
    port: 80
    protocol: TCP
    targetPort: 80
  - name: port-2
    port: 443
    protocol: TCP
    targetPort: 443
  selector:
    ques: prob1
status:
  loadBalancer: {}
