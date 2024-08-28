# volume-nfs
An updated version of the widely used NFS Server image <i>k8s.gcr.io/volume-nfs:0.8</i> which was based on the old and deprecated CentOS 7 image.

### Usage
The image can only be used with [NFS CSI Driver](https://github.com/kubernetes-csi/csi-driver-nfs)

Once deployed into a KxS cluster it will enable the ReadWriteMany feature for Persistent Volumes created with the `StorageClass nfs-csi`.

### Notes
- Tested in production environments
- For existing K8S Deployments, the related PVC must be recreated
- Make sure to expose these ports:
  ```yaml
  ports:
  - name: nfs
    containerPort: 2049
    protocol: TCP
  - name: mountd
    containerPort: 20048
    protocol: TCP
  - name: rpcbind
    containerPort: 111
    protocol: TCP
  ```