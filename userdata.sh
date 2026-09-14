#!/bin/bash

# Update system
apt-get update -y
apt-get upgrade -y

# Install prerequisites
apt-get install -y git wget curl ca-certificates gnupg

# Install Java 17
apt-get install -y fontconfig openjdk-17-jre

# Install Jenkins
wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list

apt-get update -y
apt-get install -y jenkins

systemctl enable jenkins
systemctl start jenkins

# Install Docker
apt-get install -y docker.io

systemctl enable docker
systemctl start docker

# Give users Docker access
usermod -aG docker ${admin_username}
usermod -aG docker jenkins

# Install Trivy
wget -O /tmp/trivy.deb \
  https://github.com/aquasecurity/trivy/releases/latest/download/trivy_0.66.0_Linux-64bit.deb

dpkg -i /tmp/trivy.deb || apt-get install -f -y

# Run SonarQube
docker pull sonarqube:lts-community
docker run -d \
  --name sonar \
  --restart unless-stopped \
  -p 9000:9000 \
  sonarqube:lts-community