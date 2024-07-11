# Security concerns

## Used SSH Key
The SSH key used to connect to the EC2 instances is not the main element that ensures the authentication at the remote host. While this offers the same level of security as does the key in traditional SSH connection, in this flow, the key is mainly used to ensure SSH client compatibility. Indeed, as long as the SSH port is closed and/or the instance in a private network, the main element that ensures the authentication is the AWS IAM credentials used to open the session via AWS SSM.

Considering that, it makes simpler to handle SSH private keys in your company : you could create a few private keys only (like one for prod, one for other environment and one for shared/internal services), install it on all EC2 instances of a group/env and distribute it to all the employees of a kind, as long as you connect to all your instances via SSM. Even once distributed connection can be locked by modifying the AWS role of each user or user group.

A leak of an SSH private key is thus not a critical security incident, as long as you keep the SSH port of the EC2 instance closed. In case of exposure of the key, I would still recommend to rotate the SSH key, if for some reason or incident, you need to re-open port 22 on any host (for example, an issue with the SSM agent that runs in the instance).

## Forwarding credentials
This feature allows users to continue to centrally manage authorization through AWS Identity Center or IAM users, even when an operator is logged into the EC2 instances. Indeed, by default, once logged in an EC2 instance, the credentials used are the one of the EC2 instance profile roles. This might be annoying if, for example, the user must upload/download a file only from a particular directory it owns in S3 (or if the use of any other AWS service is restricted per user).

If you define minimal permission to the EC2 instance profile role (basically only the rights that let the SSM agent to interact with the SSM service, allowing to start SSH sessions), then the logged in operator will have to use it’s own credential (forwarded by the tool) to perform additional operation like accessing S3 objects, invoking lambda functions and so on.

Nothing will prevent the operator to use the EC2 instance profile role to perform the AWS operation (using curl and the EC2 instance metadata endpoint) instead of its own credential, but that EC2 instance role will not allow him to perform much.

The drawback of this approach is that, if your AWS SSM session has log enabled, the credentials used might appear in the session logs in CloudWatch, as the command used to initiate the remote bash session exports locally gained credentials. This should not be a problem if you close down access to those logs to only admins, but those last could perform action as their colleague if intercepting the key within the hour.

I would not use this feature while connecting to sensitive or prod instances. Indeed, this feature has been designated for testing and development workflows where team members need to connect to the instance and interact from it with AWS services using the AWS CLI/SDK to run investigations, experimentation, tests or to process / transform data.

## Credential caching
The SSH-SSM proxy tool cache the credential gained locally via SSO in order to avoid the browser constantly popping out when mounting a directory. Those temporary credentials are valid for 1h and stored in an unencrypted file with permissions 400 in the user directory.

This should not be a concern if the work stations are properly secured (hard drive encrypted, screen locked, firewall…). This is anyway still much more secure than having long term access keys in the standard AWS credential file ~/.aws/credentials.