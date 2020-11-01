k -n hpa autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10
k -n hpa top pod php-apache-6d74c7d6b-dnvhh
k -n hpa get hpa
k -n hpa get rs php-apache-6d74c7d6b 
