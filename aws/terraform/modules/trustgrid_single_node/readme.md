# Trustgrid Single Node Module
This module deploys a single Trustgrid module on an EC2 instance in AWS. It handles the creation of the following AWS resources:
- EIP to be used for the EC2 instance outside/public interface
- Outside/public interface with EIP attached
- Inside/private interface
- Security group attached to the outside interface. Optionally, it will include open ports for Trustgrid gateway services.
- EC2 instance attached to both interfaces. It will use a Trustgrid AMI and run the latest Trustgrid software on boot from the userdata script.

After deployment, the module will use the Trustgrid terraform provider to verify that the node has successfully registered with the Trustgrid control plane. 

