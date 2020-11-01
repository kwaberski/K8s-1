# you can not specify multiple ports imperatively
# also that creates a deploymment and not pod only
# k run web --image=nginx:1.11.9-alpine --port=80 --labels='ques=prob1'

### now for the https 443
## CREATE CERT
# 1 scenario - we create a key and CSR and then submit it to k8s for signing
#openssl genrsa -out nginx.key 4096
#openssl req -new -key nginx.key -subj "/CN=webservice" -out nginx.csr
# 2 scenario - we create self signed one
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout privateKey.key -out certificate.crt

## STORE THE KEY & CERT IN ETCD as a secret
k -n dump1 create secret tls nginx-secret --key=nginx.key --cert=nginx.crt

# to view a cert form that secret
# you must use \ to escape the . in the tls.crt name
k -n dump1 get secrets nginx-secret -o jsonpath="{.data.tls\.crt}" | base64 --decode
k -n dump1 create configmap nginx-config --from-file=nginx.conf
