# Inspired from https://github.com/cloudbees/jenkins-ci.org-docker
FROM java:openjdk-7u65-jdk

RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y wget git curl zip lib32z1 libstdc++6:i386 libsdl1.2debian:i386 libgl1-mesa-glx:i386 qemu-kvm kmod && rm -rf /var/lib/apt/lists/*

ENV JENKINS_VERSION stable-1.580
RUN mkdir /usr/share/jenkins/
RUN useradd -d /home/jenkins -m -s /bin/bash jenkins

COPY init.groovy /tmp/WEB-INF/init.groovy.d/tcp-slave-angent-port.groovy
RUN curl -L https://updates.jenkins-ci.org/$JENKINS_VERSION/latest/jenkins.war -o /usr/share/jenkins/jenkins.war \
  && cd /tmp && zip -g /usr/share/jenkins/jenkins.war WEB-INF/init.groovy.d/tcp-slave-angent-port.groovy && rm -rf /tmp/WEB-INF

ENV JENKINS_HOME /var/jenkins_home
RUN usermod -m -d "$JENKINS_HOME" jenkins && chown -R jenkins "$JENKINS_HOME"

# define url prefix for running jenkins behind Apache (https://wiki.jenkins-ci.org/display/JENKINS/Running+Jenkins+behind+Apache)
ENV JENKINS_PREFIX /

# for main web interface:
EXPOSE 8080

# will be used by attached slave agents:
EXPOSE 50000

# Install Maven
RUN cd /usr/local/ && wget -nv http://ftp.tsukuba.wide.ad.jp/software/apache/maven/maven-3/3.1.1/binaries/apache-maven-3.1.1-bin.tar.gz && tar xf apache-maven-3.1.1-bin.tar.gz

# Install Gradle
RUN cd /usr/local/ && wget -nv http://services.gradle.org/distributions/gradle-1.9-all.zip && unzip -oq gradle-1.9-all.zip

# Environment variables
ENV MAVEN_HOME /usr/local/apache-maven-3.1.1
ENV GRADLE_HOME /usr/local/gradle-1.9
ENV PATH $PATH:$ANDROID_HOME/tools
ENV PATH $PATH:$ANDROID_HOME/platform-tools
ENV PATH $PATH:$MAVEN_HOME/bin
ENV PATH $PATH:$GRADLE_HOME/bin

# Clean up

RUN rm -rf /usr/local/apache-maven-3.1.1-bin.tar.gz
RUN rm -rf /usr/local/gradle-1.9-all.zip

USER jenkins

# Install Android SDK
RUN cd $JENKINS_HOME && wget -nv http://dl.google.com/android/android-sdk_r23.0.2-linux.tgz && tar xfo android-sdk_r23.0.2-linux.tgz --no-same-permissions && chmod -R a+rX android-sdk-linux
RUN rm -rf $JENKINS_HOME/android-sdk_r23.0.2-linux.tgz

# Install Android tools
RUN echo y | $JENKINS_HOME/android-sdk-linux/tools/android update sdk --filter tools --no-ui --force -a
RUN echo y | $JENKINS_HOME/android-sdk-linux/tools/android update sdk --filter platform-tools --no-ui --force -a
RUN echo y | $JENKINS_HOME/android-sdk-linux/tools/android update sdk --filter platform --no-ui --force -a
RUN echo y | $JENKINS_HOME/android-sdk-linux/tools/android update sdk --filter build-tools-21.0.1 --no-ui -a
RUN echo y | $JENKINS_HOME/android-sdk-linux/tools/android update sdk --filter sys-img-x86-android-18 --no-ui -a
RUN echo y | $JENKINS_HOME/android-sdk-linux/tools/android update sdk --filter sys-img-x86-android-19 --no-ui -a
RUN echo y | $JENKINS_HOME/android-sdk-linux/tools/android update sdk --filter sys-img-x86-android-21 --no-ui -a

ENV ANDROID_HOME $JENKINS_HOME/android-sdk-linux

COPY jenkins.sh /usr/local/bin/jenkins.sh
ENTRYPOINT ["/usr/local/bin/jenkins.sh"]

# Install some useful Jenkins plugins (Git, Android Emulator)
RUN cd $JENKINS_HOME && mkdir plugins && cd plugins && \
  wget -nv https://updates.jenkins-ci.org/$JENKINS_VERSION/latest/android-emulator.hpi && \
  wget -nv https://updates.jenkins-ci.org/$JENKINS_VERSION/latest/port-allocator.hpi && \
  wget -nv https://updates.jenkins-ci.org/$JENKINS_VERSION/latest/git.hpi &&\
  wget -nv https://updates.jenkins-ci.org/$JENKINS_VERSION/latest/git-client.hpi &&\
  wget -nv https://updates.jenkins-ci.org/$JENKINS_VERSION/latest/scm-api.hpi &&\
  wget -nv https://updates.jenkins-ci.org/$JENKINS_VERSION/latest/credentials.hpi &&\
  wget -nv https://updates.jenkins-ci.org/$JENKINS_VERSION/latest/ssh-credentials.hpi

# Copy default configuration for Maven  
COPY hudson.tasks.Maven.xml $JENKINS_HOME/hudson.tasks.Maven.xml

USER root
RUN usermod -a -G kvm jenkins
ADD kvm-mknod.sh /root/kvm-mknod.sh
ADD entrypoint.sh /root/entrypoint.sh

ENTRYPOINT ["/root/entrypoint.sh"]

