# ynpact-ssh-ssm-proxy
SSH-SSM-Proxy-script allow to use VS Code remote SSH plugin through a AWS SSM Session Manager SSH session to connect to and manage remote hosts in a painlessly manner.

While you'll find on most blog solutions that allow to connect to remote EC2 instance using SSM, none of these are generic enough to allows a convenient daily use. With this proxy script, you can administrate at scale a wide variety of EC2 instances, located onto different AWS account and region, using different SSH key/user, AWS authentication methods and AWS credentials profiles.

It also provide a unique feature that forward and inject locally AWS credential (gained via AWS SSO/IdentityCenter or static key) into the remote EC2 instance, so that you still can manage the authorization per user even in the EC2 instance, where by default, the EC2 instance role  apply (more on that below).

Features:
- Enhanced Security and logging for EC2 instances SSH session with AWS SSM Session Manager.
  **Connect to EC2 instances located in private subnet with inbound SSH port closed**
- Enhanced remote file system integration in VS Code when using AWS credentials gained by SSO **It will not popout the broswer for SSO login multiple time**
- Connect to host using friendly name instead of ID that may change over time **You can forget about looking for instanceIDs**
- Use AWS credential locally gained by SSO within the EC2 instances **Once connected into the C2 instances, users act as themselve, with their own set of authorization, not as the EC2 instance profile role**
- for each host, allow to configure credential profile, region, user and SSH key to use and activate or not current credential fowarding into the EC2 instance **If you have a huge list of EC2 instance to conenct to, locatad in different account, region and using different credential profile, this tool is for you, a you won't have to insert all that EC2 host specific conf into your ssh config file with a ProxyCommand line you can not refactor**
- allow auto install specified public key in the autorized_key file of the remote EC2 instance on first setup

## Setting Up Ynpact's VS Code Remote SSH Extension
You can install it on any operating system, but on windows you must perform those step in your default WSL distribution with its default user (appart from step 4 and 5 that must be done in the Windows host).
1) Install AWS CLI and SSM Plugin into your Mac/Linux/WSL. Instruction available in AWS documentation.
2) Download the [SSH Proxy Script](src/sshProxy.sh) and save it into your default user .ssh directory in your Mac/Linux/WSL.
3) Update your SSH config file (~/.ssh/config) into your default user directory in your Mac/Linux/WSL by adding the following lines :
```
host i-* mi-*
  StrictHostKeyChecking no
  ProxyCommand bash -ci "/home/apalepex/.ssh/sshProxy.sh cnx %h %p"
```

1) [Windows only] Create a Windows .bat Script
Write a .bat script for launching and using the SSH proxy script from step 2. Save this script in your home directory in Windows under the .ssh folder. Do not use "~" in the script path but the full home directory of your WSL default user.
```
C:\Windows\system32\wsl.exe bash -ic '<home-directory-in-wsl>/.ssh/sshProxy.sh %*'
```

1) Update Remote SSH Plugin Path
Update the path parameter of the Remote SSH plugin in VS Code to use
- Windows: the .bat script you created in step 4.
- Linux/Mac: ~/.ssh/sshProxy.sh
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
'''
Host aws-host
    HostName aws-host
'''
![How to connect to a bookmarked host](doc/bookmarking.png)


