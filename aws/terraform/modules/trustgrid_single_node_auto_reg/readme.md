# Trustgrid Single Node Module Auto Registration
This module deploys a single Trustgrid module on an EC2 instance in AWS and automatically register with the Trustgrid control plane. It handles the creation of the following AWS resources :
- EIP to be used for the EC2 instance outside/public interface
- Outside/public interface with EIP attached
- Inside/private interface
- Security group attached to the outside interface. Optionally, it will include open ports for Trustgrid gateway services.
- EC2 instance attached to both interfaces, built off the Trustgrid AMI image running the latest Trustgrid software
- On boot, the Trustgrid license is used to register the node with the Trustgrid control plane
- The module will then use the Trustgrid terraform provider to verify that the node has successfully registered with the Trustgrid control plane. 

