# 1st choice just run this
k -n dump1 run redis --image=redis:6.0.6-alpine --port=6379 --labels="app=redis,ques=prob4"
k -n dump1 expose deployment redis --port=6379 --target-port=6379


# 2nd choice
# crete configMap
k -n dump1 create configmap redis-config --from-file=redis.conf
# and apply the 4.yaml
