# 1. Define the commands as a simple string
$cmds = @'
sudo id -u deploy_user &>/dev/null || sudo adduser --disabled-password --gecos "" deploy_user
sudo usermod -aG sudo deploy_user
sudo mkdir -p /home/deploy_user/.ssh 
sudo chmod 700 /home/deploy_user/.ssh
# echo "ssh-rsa AAA..." | sudo tee -a /home/deploy_user/.ssh/authorized_keys
sudo chmod 600 /home/deploy_user/.ssh/authorized_keys 2>/dev/null
sudo chown -R deploy_user:deploy_user /home/deploy_user/.ssh
'@

# 2. Push the string directly to the server
$IP = Read-Host "Enter Server IP"
$User = Read-Host "Enter Server user"
echo $cmds | ssh -t "${User}@${IP}" "bash"