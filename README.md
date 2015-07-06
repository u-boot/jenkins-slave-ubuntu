Jenkins Slave Docker container
==============================

Based on https://github.com/thaeli/docker-images

A Jenkins Slave for [Jenkins Docker Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Docker+Plugin) using Ubuntu 14.04 Trusty.

## Usage

- Pull this image on target slave of jenkins.

```
docker pull shayashibara/jenkins-slave-ubuntu
```

- Setting jenkins.

  1. Install `Jenkins Docker Plugin`.
  2. Add `Docker` template to Cloud provider from `System Setting`.
  3. Limit target job's execution node to `Label` of above template.

##  tags

`latest`: basic ubuntu trusty image.  
`php`: based on official `php:5.6` image and including composer. 
`nodejs`: based on ubuntu trusty image with node and npm.
