k -n dump1 create secret generic kw-secret --from-literal=user=kwaberski --from-literal=secret=kwsecret

k -n dump1 edit pod busybox
# under volumes:
- name: kw-secret
  secret:
    secretName: kw-secret
# under volumeMounts:
- mountPath: /opt/mysecretvolume
  name: kw-secret
# under containers
env:
- name: MYSECRET
  valueFrom:
    secretKeyRef:
      name: kw-secret
      key: secret
