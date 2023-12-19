# Trustgrid Single Node Manual Registration Module
This module deploys a single Trustgrid module on an EC2 instance in AWS based on the Trustgrid AMI image but **does not** attempt to register the device with the Trustgrd control plane. After deployment, the node will need to be registered via the [remote console registration](https://docs.trustgrid.io/tutorials/local-console-utility/remote-registration/) process

The module handles the creation of the following AWS resources :
- EIP to be used for the EC2 instance outside/public interface
- Outside/public interface with EIP attached
- Inside/private interface
- Security group attached to the outside interface. Optionally, it will include open ports for Trustgrid gateway services.
- EC2 instance attached to both interfaces built off the Trustgrid AMI image running the latest Trustgrid software


