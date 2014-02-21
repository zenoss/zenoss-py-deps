FROM mattdm/fedora:f19
MAINTAINER Zenoss <ian@zenoss.com>

RUN yum -y install python-devel python-pip
RUN pip install --upgrade pip wheel
