#!/bin/bash
regexp="aws-.*"
regexpId="aws-.*\..*\..*\..*\..*\..*\..*"
portNumber=22
bashCommand="bash"
mapFile="$HOME/.ssh/ec2Map.txt"
logfile="/tmp/sshssm.log"

log() {
    echo "$(date) > $1" >> $logfile
}
log "Input from VSCODE remote SSH plugin : $*"

log "Running in $(pwd)"
log "map>>> $(cat $mapFile)"

# handle vscode remote ssh plugin probe of ssh client
if [[ $1 = "-V" ]]; then
    ssh -V
    exit 0
fi

# handle connection for aws-* like hostnames
if [[ $# == 3 && $1 == "cnx" ]]; then
    log "connection with AWS SSM..."
    target=$2
    portNumber=$3
    instanceId=$(echo $target | awk -F '.' '{print $1}')
    profile=$(echo $target | awk -F '.' '{print $2}')
    region=$(echo $target | awk -F '.' '{print $3}')

    log "instanceId: $instanceId"
    log "profile: $profile"
    log "region: $region"
    log "portNumber: $portNumber"

    aws ssm start-session --target $instanceId \
        --document-name AWS-StartSSHSession --parameter portNumber="$portNumber" \
        --region $region
    exit $?
fi

# handle adding/modifying host in config file
if [[ $# == 2 && ($1 == "newhost" || $1 == "edithost") ]]; then
    hostProfile=$2
    mkdir -p $HOME/.ssh
    touch $mapFile
    if ! [[ "$hostProfile" =~ aws-.* ]]; then
        echo "Host profile name should start with 'aws-'"
        exit 1
    fi
    echo "Instance name tag ? " ; read instanceName
    echo "Connect via AWS SSO y/n ? " ; read loginType
    echo "AWS credential profile to use ? " ; read profile
    echo "Forward local AWS credential into EC2 session y/n ? " ; read forwardCred
    echo "Instance region ? " ; read region
    echo "SSH user ? " ; read user
    echo "SSH key file ? " ; read key
    if [[ $loginType == "y" ]]; then
        loginType="sso"
    fi
    confLine="$hostProfile $instanceName $loginType:$profile:$forwardCred $region $user $key"
    escapedConfLine=$(echo "$confLine" | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/\&/\\\&/g')
    # edit or add conf line
    if [[ $(cat $mapFile | grep -w $hostProfile) != "" ]]; then
        sed -i "/^$hostProfile/ s/.*/$escapedConfLine/" $mapFile
        rm -rf $HOME/.aws/sshssm/$profile.json
    else
        echo $confLine >> $mapFile
    fi
    exit 0
fi

if [[ $# == 2 && $1 == "rmhost" ]]; then
    hostProfile=$2
    mkdir -p $HOME/.ssh
    touch $mapFile
    sed -i "/^$hostProfile\s.*$/d" $mapFile
    exit 0
fi

target=$4
log "Target: $target"

login() {
    mkdir -p ".aws/sshssm/"
    tmpCredFile="$HOME/.aws/sshssm/$profile.json"
    touch $tmpCredFile
    chmod 600 $tmpCredFile

    currentDate=$(date --utc +%FT%TZ | cut -c 1-19)
    expiration=$(cat $tmpCredFile | jq -r '.Expiration' | cut -c 1-19)
    if [[ $expiration != "" && $expiration > $currentDate ]]; then
        log "cred existing"
    else
        log "cred non existing or expired"
        firstLaunch="true"
        if [[ $loginType = "sso" ]]; then
            aws sso login --profile $profile >> $logfile 2>/tmp/err </dev/null
        fi
        aws configure export-credentials --profile $profile > $tmpCredFile
    fi
    awskey=$(cat $tmpCredFile | jq -r '.AccessKeyId')
    awssecret=$(cat $tmpCredFile | jq -r '.SecretAccessKey')
    export AWS_ACCESS_KEY_ID=$awskey
    export AWS_SECRET_ACCESS_KEY=$awssecret
    if [[ $loginType = "sso" ]]; then
        awstoken=$(cat $tmpCredFile | jq -r '.SessionToken')
        export AWS_SESSION_TOKEN=$awstoken
    fi
}

show_var() {
    log "login: $loginType"
    log "profile: $profile"
    log "forwardCred: $forwardCred"
    log "region: $region"
    log "instanceName: $instanceName"
    log "instanceId: $instanceId"
    log "key: $key"
    log "user: $user"
}

forwardCredInBash() {
    # to forward the current AWS SSO/regular credential into the remote session
    # we need to kill first the vscode server, as env var are propagated only at
    # first init of the vscode server and then remains the same for all subsequent
    # new session. Also to cleanup sessions as many vscode-server binary remains.
    # NB: do this only at first launch in the credential validity window
    if [[ $firstLaunch == "true" ]]; then
        killVscodeCmd="ps uxa | grep .vscode-server | awk '{print \$2}' | xargs kill"
        command="ssh -i $key $user@$instanceId.$profile.$region $killVscodeCmd"
        log "Reset vscode-server command : $command"
        $command < /dev/null > /dev/null 2> /dev/null
    fi
    if [[ $forwardCred == "y" ]]; then        
        bashCommand="AWS_ACCESS_KEY_ID=$awskey AWS_SECRET_ACCESS_KEY=$awssecret AWS_SESSION_TOKEN=$awstoken $bashCommand"
    fi
}

# if host conf in conf file
if [[ "$target" =~ $regexp ]]; then
    log "using map file"
    instanceName=$(cat $mapFile | grep -w $target | awk  '{print $2}')
    loginConf=$(cat $mapFile | grep -w $target | awk '{print $3}')
        loginType=$(echo $loginConf | awk -F ':' '{print $1}')
        profile=$(echo $loginConf | awk -F ':' '{print $2}')
        forwardCred=$(echo $loginConf | awk -F ':' '{print $3}')
    region=$(cat $mapFile | grep -w $target | awk '{print $4}')
    user=$(cat $mapFile | grep -w $target | awk '{print $5}')
    key=$(cat $mapFile | grep -w $target | awk '{print $6}')
    show_var
    login
    instanceId=$(aws ec2 describe-instances --output text --query "Reservations[*].Instances[*].InstanceId" --filters "Name=tag:Name,Values=$instanceName" --region $region)
    forwardCredInBash
    command="ssh $1 $2 $3 -i $key $user@$instanceId.$profile.$region $bashCommand"
    log "$command"
    $command
# if using directly (no conf file)
elif [[ "$target" =~ $regexpId ]]; then
    instanceName=$(echo $target | awk -F '.' '{print $1}')
    loginType=$(echo $target | awk -F '.' '{print $2}')
    profile=$(echo $target | awk -F '.' '{print $3}')
    forwardCred=$(echo $target | awk -F '.' '{print $4}')
    region=$(echo $target | awk -F '.' '{print $5}')
    user=$(echo $target | awk -F '.' '{print $6}')
    key=$(echo $target | awk -F '.' '{print $7}')
    show_var
    login
    if [[ "$target" =~ "m?i-.*" ]]; then
        instanceId=$instanceName
    else
        instanceId=$(aws ec2 describe-instances --output text --query "Reservations[*].Instances[*].InstanceId" --filters "Name=tag:Name,Values=$instanceName" --region $region)
    fi
    forwardCredInBash
    command="ssh $1 $2 $3 -i $key $user@$instanceId.$profile.$region $bashCommand"
    log "$command"
    $command
else
    # if not an AWS instance, use regular SSH directly
    ssh $*
fi
