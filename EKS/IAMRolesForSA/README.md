# IAM Roles for Service Accounts

EKS comes with a public OIDC Discovery endpoint that is used by IAM to validate tokens issued by kubernetes to service accounts

### Create an Identity Provider in IAM pointing at the EKS OIDC endpoint
### Create a role that you want your service account to be able to assume  
The role should have AWS permission defined or a built-in policy attached  
The trust relationship on the role must look like this
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::359466956633:oidc-provider/oidc.eks.eu-central-1.amazonaws.com/id/9BB93BC3D6DE8359F81BF64CA319AC2F"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.eu-central-1.amazonaws.com/id/9BB93BC3D6DE8359F81BF64CA319AC2F:aud": "sts.amazonaws.com",
          "oidc.eks.eu-central-1.amazonaws.com/id/9BB93BC3D6DE8359F81BF64CA319AC2F:sub": "system:serviceaccount:default:my-iam-test"
        }
      }
    }
  ]
}
```
Here the Principal is federated and it is the OIDC endpoint  
And we add a conditions on the AssumeRoleWithWebIdentity to reference the SA in kubernetes that we allow to assume this role system:serviceaccount:namespace:sa  

### Create a service account 
Create a service account in the namespace and with the name that matches what you put above in the trust relations, here is a sample yaml file my-iam-test.yaml
```
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::359466956633:role/eksctl-staging-eks-imasarole-S3RO
  labels:
    app.kubernetes.io/managed-by: cli
  name: my-iam-test
  namespace: default
  ```
  and now run
  ```
  kubectl create -f my-iam-test.yaml
  ```


