FROM mattdm/fedora:f19
MAINTAINER Zenoss <ian@zenoss.com>

RUN yum -y install python-devel python-pip gcc make
RUN pip install --upgrade pip wheel virtualenv

# Dependencies to build the packages
RUN yum -y install mysql-devel
