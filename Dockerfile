FROM centos:centos7 AS baseimage

#### Locale support ###
RUN localedef -i en_US -f UTF-8 en_US.UTF-8
RUN echo "LANG=\"en_US.UTF-8\"" > /etc/locale.conf
RUN ln -s -f /usr/share/zoneinfo/GMT /etc/localtime
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8
### Locale Support END ###

### Build cache for all repos, install updates and a few packages, clean up.
RUN \
  yum -y makecache && \
  yum -y install deltarpm initscripts locales && \
  yum update -y && \
  yum upgrade -y && \
  yum -y install kernel-devel && \
  yum clean all && \
  rm -rf /var/cache/yum

# Take updated baseimage and use as base for next stage
# to build packetfence
FROM baseimage AS packetfence
MAINTAINER Daren Darrow <ddarrow@salesforce.com>
LABEL Remarks="Packetfence test image"
#### Locale support ###
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8
### Locale Support END ###


RUN \
  rpm -import https://www.packetfence.org/downloads/RPM-GPG-KEY-PACKETFENCE-CENTOS && \
  yum update -y && \
  yum upgrade -y && \
  yum -y localinstall http://packetfence.org/downloads/PacketFence/CentOS7/packetfence-release-7.stable.noarch.rpm && \
  yum -y install --enablerepo=packetfence packetfence && \
  yum clean all && \
  rm -rf /var/cache/yum

#Enable systemd
ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*; \
rm -f /etc/systemd/system/*.wants/*; \
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup"]
CMD ["/usr/sbin/init"]