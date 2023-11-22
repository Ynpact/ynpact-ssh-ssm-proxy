# ynpact-ssh-ssm-proxy
SSH Proxy Command script to enable VS Code SSH remote session through AWS SSM

## Setting Up Ynpact's VS Code Remote SSH Extension
To set up this powerful extension and use into Windows, follow these basic steps:
(you can easily adjust it for Linux and Mac)
1) Install AWS CLI and SSM Plugin into WSL
Ensure that you have the AWS CLI and the SSM plugin installed within the Windows Subsystem for Linux (WSL) on your development machine. These tools are essential for connecting to EC2 instances via SSM.
2) Install the SSH Proxy Script src/sshProxy.sh
Download the provided SSH proxy script and save it into the .ssh directory of your home directory within WSL. This script is the key to connecting to EC2 instances securely and efficiently.
3) Update SSH Config File
Modify your SSH config file in WSL to use the script you saved in step 2 whenever a hostname starts with "aws-". This ensures that the extension will be invoked for your EC2 instance connections.
host aws-* i-* mi-*
  StrictHostKeyChecking no
  ProxyCommand bash -ci "/home/apalepex/.ssh/sshProxy.sh cnx %h %p"

```
host aws-* i-* mi-*
  StrictHostKeyChecking no
  ProxyCommand bash -ci "/home/apalepex/.ssh/sshProxy.sh cnx %h %p"
```

4) Create a Windows .bat Script
Write a .bat script for launching and using the SSH proxy script from step 2. Save this script in your home directory in Windows under the .ssh folder.
C:\Windows\system32\wsl.exe bash -ic '/home/apalepex/.ssh/sshProxy.sh %*'

```
C:\Windows\system32\wsl.exe bash -ic '/home/apalepex/.ssh/sshProxy.sh %*'
```

5) Update Remote SSH Plugin Path
Update the path for the Remote SSH plugin in VS Code to use the .bat script you created in step 4. This step connects the extension to your EC2 instances.
![Updating remote SSH extension path parameter](doc/setting-remote-ext.png)

## Configuration and Connection
To configure and connect to your EC2 instances, use the following steps:
### Add, edit or remove a Host:
Run the command ~/.ssh/sshSsmProxy.sh newhost|edithost|rmhost <profileName> within WSL, and follow the script's prompts. This command allows you to create, edit or delete a host configuration, identified by its profile name.
### Connect to a Pre-configured Host:
In VS Code's command palette, select "Connect to Remote Host," and enter the host's profile name, as configured in the previous step.
### Connect to a Non-configured Host:
If you need to connect to a host that hasn't been previously configured, use the command palette in VS Code to select "Connect to Remote Host." Enter the host information in the format <hostname>.<sso|static>.<profile>.<forward-cred-y-n>.<region>.<ssh-user>.<ssh-key-file>.
### Bookmarking hosts
Into your SSH config file of your windows host C:\Users\<username>\.ssh\config, you can add the host you connect to frequently so it appears in VS Code when you use the command palette : 

Host aws-host
    HostName aws-host





