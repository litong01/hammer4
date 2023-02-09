# hammer
all the necessary tools to work with kubernetes



docker run --rm --name k8stool --network kind -dit \
   --entrypoint /bin/bash \
   -v /var/run/docker.sock:/var/run/docker.sock \
   -v /tmp/work:/home/work \
   -v /Users/tli/.kube:/home/.kube email4tong/hammer