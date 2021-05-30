#!/bin/bash
# check 4.1
echo "######################################################"
echo "=== 4.1 - Dsiplay AWS to K8s user/role mappings. VERFIY who is part of SYSTEM:MASTERS"
kubectl -n kube-system describe cm aws-auth
echo "These subjects are part of system:masters"
eksctl get iamidentitymapping --cluster $(aws eks list-clusters --query clusters --output text) | grep "system:masters"
echo "------------------------------------------------------------------------------- END"
echo
echo "=== 4.1.1 - Ensure that the cluster-admin role is only used where required"
echo "--- Cluster Role bindings that use cluster-admin role:"
kubectl get clusterrolebindings.rbac.authorization.k8s.io -o jsonpath="{range .items[?(@.roleRef.name=='cluster-admin')]}CRB={.metadata.name},SUBJECT={.subjects[*].name}{'\n'}{end}"
echo "--- Role bindings that use cluster-admin role:"
kubectl get rolebindings.rbac.authorization.k8s.io --all-namespaces -o jsonpath="{range .items[?(@.roleRef.name=='cluster-admin')]}NS={.metadata.namespace},RB={.metadata.name}{'\n'}{end}"
echo "------------------------------------------------------------------------------- END"
echo
echo "=== 4.1.2 - Who has access to secrets"
echo "Those who have *.* and get:"
# first clusterroles with API_GROUP=* and RESOURCE=* with VERB=get
crs_all=$(kubectl get clusterroles -o json | jq -r '.items[] | select( any(.rules[]; .resources[]?=="*" and .apiGroups[]=="*" and .verbs[]=="get" )) | .metadata.name')
# what subjects use clusterrolebindings bound to any of these cluster roles
for cr_all in ${crs_all}; do kubectl get clusterrolebindings.rbac.authorization.k8s.io -o jsonpath="{range .items[?(@.roleRef.name==\"${cr_all}\")]}CR={.roleRef.name},CRB={.metadata.name},SUBJECT={.subjects[*].name}{'\n'}{end}"; done
# what subjects use rolebindings that use the above clusterroles
for cr_all in ${crs_all}; do kubectl get rolebindings.rbac.authorization.k8s.io --all-namespaces -o jsonpath="{range .items[?(@.roleRef.name==\"${cr_all}\")]}NS={.metadata.namespace},CR={.roleRef.name},CRB={.metadata.name},SUBJECT={.subjects[*].name}{'\n'}{end}"; done
echo "Those who have get verb on secrets"
# second roles with API_GROUP=* and RESOURCE=* with VERB=get and who uses role bindings that bind to them
rs_all=$(kubectl get roles --all-namespaces -o json | jq -r '.items[] | select( any(.rules[]; .resources[]?=="*" and .apiGroups[]=="*" and .verbs[]=="get" )) | .metadata.name')
for r_all in ${rs_all}; do kubectl get rolebindings.rbac.authorization.k8s.io --all-namespaces -o jsonpath="{range .items[?(@.roleRef.name==\"${r_all}\")]}NS={.metadata.namespace},CR={.roleRef.name},CRB={.metadata.name},SUBJECT={.subjects[*].name}{'\n'}{end}"; done
# lets clusterroles that can get secrets
crs=$(kubectl get clusterroles -o json | jq -r '.items[] | select( any(.rules[]; .resources[]?=="secrets" and .verbs[]=="get" )) | .metadata.name')
# what subjects have clusterrolebinding bound to any of these roles
for cr in ${crs}; do kubectl get clusterrolebindings.rbac.authorization.k8s.io -o jsonpath="{range .items[?(@.roleRef.name==\"${cr}\")]}CR={.roleRef.name},CRB={.metadata.name},SUBJECT={.subjects[*].name}{'\n'}{end}"; done
# same for rolebindings that use the above clusterroles
for cr in ${crs}; do kubectl get rolebindings.rbac.authorization.k8s.io --all-namespaces -o jsonpath="{range .items[?(@.roleRef.name==\"${cr}\")]}NS={.metadata.namespace},CR={.roleRef.name},CRB={.metadata.name},SUBJECT={.subjects[*].name}{'\n'}{end}"; done
# lets look for roles that can get secrets and who uses role bindings that bind to them
rs=$(kubectl get roles --all-namespaces -o json | jq -r '.items[] | select( any(.rules[]; .resources[]?=="secrets" and .verbs[]=="get" )) | .metadata.name')
for r in ${rs}; do kubectl get rolebindings.rbac.authorization.k8s.io --all-namespaces -o jsonpath="{range .items[?(@.roleRef.name==\"${r}\")]}NS={.metadata.namespace},CR={.roleRef.name},CRB={.metadata.name},SUBJECT={.subjects[*].name}{'\n'}{end}"; done
echo "Those who can escalate their permissions"
# k describe clusterrole system:controller:clusterrole-aggregation-controller
# k describe clusterrolebindings system:controller:clusterrole-aggregation-controller
crs_esc=$(kubectl get clusterroles -o json | jq -r '.items[] | select( any(.rules[]; .verbs[]=="escalate" )) | .metadata.name')
for cr_esc in ${crs_esc}; do kubectl get clusterrolebindings.rbac.authorization.k8s.io -o jsonpath="{range .items[?(@.roleRef.name==\"${cr_esc}\")]}CR={.roleRef.name},CRB={.metadata.name},SUBJECT={.subjects[*].name}{'\n'}{end}"; done
for cr_esc in ${crs_esc}; do kubectl get rolebindings.rbac.authorization.k8s.io --all-namespaces -o jsonpath="{range .items[?(@.roleRef.name==\"${cr_esc}\")]}NS={.metadata.namespace},CR={.roleRef.name},CRB={.metadata.name},SUBJECT={.subjects[*].name}{'\n'}{end}"; done
echo "------------------------------------------------------------------------------- END"
echo





echo
echo "################## EXTRA RBAC ######################"
echo "=== Display clusterroles that have RESOURCE=* and API_GROUP=* and VERBS=*"
kubectl get clusterroles -o json | jq -r '.items[] | select( any(.rules[]; .resources[]?=="*" and .apiGroups[]=="*" and .verbs[]=="*" )) | .metadata.name'
echo "------------------------------------------------------------------------------- END"
echo
echo "=== Display roles that have RESOURCE=* and API_GROUP=* and VERBS=*"
kubectl get roles --all-namespaces -o json | jq -r '.items[] | select( any(.rules[]; .resources[]?=="*" and .apiGroups[]=="*" and .verbs[]=="*" )) | .metadata.name'
echo "------------------------------------------------------------------------------- END"
echo
echo "=== Display clusterroles that have RESOURCE=*"
kubectl get clusterroles -o json | jq -r '.items[] | select( any(.rules[]; .resources[]?=="*")) | .metadata.name'
echo "------------------------------------------------------------------------------- END"
echo
echo "=== Dsiplay roles that have RESOURCE=*"
kubectl get roles --all-namespaces -o json | jq -r '.items[] | select( any(.rules[]; .resources[]?=="*")) | .metadata.name'
echo "------------------------------------------------------------------------------- END"
echo
echo "=== Display clusterroles that have VERB=*"
kubectl get clusterroles -o json | jq -r '.items[] | select( any(.rules[]; .verbs[]=="*" )) | .metadata.name'
echo "------------------------------------------------------------------------------- END"
echo
echo "=== Dsiplay roles that have VERB=*"
kubectl get roles --all-namespaces -o json | jq -r '.items[] | select( any(.rules[]; .verbs[]=="*" )) | .metadata.name'
echo "------------------------------------------------------------------------------- END"
echo

