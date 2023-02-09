# hammer
all the necessary tools to work with kubernetes

```
gateexist=$(docker inspect toolgate --format "{{.Name}}" 2> /dev/null || true)
if [[ -z "${gateexist}" ]]; then
  docker run -d --rm --name toolgate --network kind \
    -v /var/run/docker.sock:/var/run/docker.sock \
    alpine/socat tcp-listen:2375,fork,reuseaddr unix-connect:/var/run/docker.sock
fi
GATEIP=$(docker inspect toolgate -f '{{ .NetworkSettings.Networks.kind.IPAddress }}')
echo $GATEIP

docker run --rm --name k8stool --network kind \
   -e "DOCKER_HOST=tcp://${GATEIP}:2375" \
   -v /var/run/docker.sock:/var/run/docker.sock \
   -v /tmp/work:/home/work \
   -v /Users/tli/.kube:/home/.kube email4tong/hammer
```
