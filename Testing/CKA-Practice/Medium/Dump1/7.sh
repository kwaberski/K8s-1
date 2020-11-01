# 1st choice
k -n dump1 get pod redis-77bfcc8df9-5hfw8 -o yaml
# and copy the spec section
cat <<EOF > podversion
spec:
  containers:
  - image: redis:6.0.7-alpine
    imagePullPolicy: IfNotPresent
    name: redis
    ports:
    - containerPort: 6379
      protocol: TCP
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:

    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: default-token-dfzxx
      readOnly: true
  dnsPolicy: ClusterFirst
  enableServiceLinks: true
  nodeName: node2u
  preemptionPolicy: PreemptLowerPriority
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: default-token-dfzxx
    secret:
      defaultMode: 420
      secretName: default-token-dfzxx
EOF

# 2nd choice
k -n dump1 get pod redis-77bfcc8df9-5hfw8 -o jsonpath='{.spec}{"\n"}' > podversion

# 3rd choice
k -n dump1 get pod redis-77bfcc8df9-5hfw8 -o json | jq -r ".spec"
