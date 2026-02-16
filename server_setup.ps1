# 1. Define the commands as a simple string
$cmds = @'
sudo id -u deploy_user &>/dev/null || sudo adduser --disabled-password --gecos "" deploy_user
sudo usermod -aG sudo, deploy_user
sudo mkdir -p /home/deploy_user/.ssh 
sudo cp /root/.ssh/authorized_keys /home/deploy_user/.ssh/ 2>/dev/null
sudo chown -R deploy_user:deploy_user /home/deploy_user/.ssh 
sudo chmod 700 /home/deploy_user/.ssh
echo "deploy_user ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/deploy-perms
'@

# 2. Push the string directly to the server
$IP = Read-Host "Enter Server IP"
$User = Read-Host "Enter Server user"
echo $cmds | ssh -t "${User}@${IP}" "bash"