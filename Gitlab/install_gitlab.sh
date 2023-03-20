echo ==== Installing Requirements ==============================================
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl openssh-server ca-certificates postfix

echo ==== Installing GitLab CE =================================================
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
sudo apt-get install -y gitlab-ce
sudo gitlab-ctl reconfigure
sudo gitlab-ctl status

# echo ==== Installing GitLab Multi Runner =======================================
# curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-ci-multi-runner/script.deb.sh | sudo bash
# sudo apt-get install -y gitlab-ci-multi-runner

echo ==== Installing GitLab Agent =======================================
# Download the binary for your system
sudo curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64

# Give it permission to execute
sudo chmod +x /usr/local/bin/gitlab-runner

# Create a GitLab Runner user
sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash

# Install and run as a service
sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
sudo gitlab-runner start

echo comando registrazione runner sudo gitlab-runner register --url http://gitlab.local.com/ --registration-token tokendaprendersugitlab

echo username: root
cat vim /etc/gitlab/initial_root_password



