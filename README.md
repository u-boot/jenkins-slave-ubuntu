Jenkins Slave Docker container
==============================

Based on https://github.com/shufo/jenkins-slave-ubuntu

A Jenkins Slave for [Jenkins Docker Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Docker+Plugin) using Ubuntu 16.04 Xenial.

## Usage

- Build this image on your docker host.

```
docker build -t your-namespace:your-tag .
```

- Setting up jenkins.

  1. Install `Jenkins Docker Plugin`.
  2. Add `Docker` template to Cloud provider from `System Setting`.
  3. Limit target job's execution node to `Label` of above template.
