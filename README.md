Project landing zone and gke - kuik
this is the repo with all the stuff we did in the friday lab to make the pipeline work.

What is in the folders:
host: here are the terraform files for the network and the shared vpc that the sysadmins send.

dev: here is the gke-kuik-dev-002 cluster and the config for the development project.

yaml: the kubernetes files (deployment, service and the ingress).

functions: the python code for gemini to read logs when something fails in the cluster.

.github: the workflows so when you push it uploads the image to google cloud by itself.

How to make it work:
first you have to do terraform apply in host and then in dev (takes about 15 min).

connect the kubectl with the gcloud command they gave us.

push the changes to github to activate the action.

check the ingress ip to see the web (mine is 136.110.169.2 but it can change if you delete the ingress).

Notes:
if a pod stays in pending is because google has no more e2-medium cpus in belgium (europe-west1-b), you have to lower the replicas to 1.
the dockerfile uses nginx to serve the index.html that is in the root.
