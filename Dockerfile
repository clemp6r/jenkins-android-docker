# Inspired from https://github.com/cloudbees/jenkins-ci.org-docker
FROM java:openjdk-7u65-jdk

RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y wget git curl zip lib32z1 libstdc++6:i386 libsdl1.2debian:i386 && rm -rf /var/lib/apt/lists/*

ENV JENKINS_VERSION 1.565.3
RUN mkdir /usr/share/jenkins/
RUN useradd -d /home/jenkins -m -s /bin/bash jenkins

COPY init.groovy /tmp/WEB-INF/init.groovy.d/tcp-slave-angent-port.groovy
RUN curl -L http://mirrors.jenkins-ci.org/war-stable/$JENKINS_VERSION/jenkins.war -o /usr/share/jenkins/jenkins.war \
  && cd /tmp && zip -g /usr/share/jenkins/jenkins.war WEB-INF/init.groovy.d/tcp-slave-angent-port.groovy && rm -rf /tmp/WEB-INF

ENV JENKINS_HOME /var/jenkins_home
RUN usermod -m -d "$JENKINS_HOME" jenkins && chown -R jenkins "$JENKINS_HOME"

# define url prefix for running jenkins behind Apache (https://wiki.jenkins-ci.org/display/JENKINS/Running+Jenkins+behind+Apache)
ENV JENKINS_PREFIX /

# for main web interface:
EXPOSE 8080

# will be used by attached slave agents:
EXPOSE 50000

USER jenkins

COPY jenkins.sh /usr/local/bin/jenkins.sh
ENTRYPOINT ["/usr/local/bin/jenkins.sh"]

USER root
  
# Install Android SDK
RUN cd /usr/local/ && wget -nv http://dl.google.com/android/android-sdk_r23.0.2-linux.tgz && tar xfo android-sdk_r23.0.2-linux.tgz --no-same-permissions

# Install Android tools
RUN echo y | /usr/local/android-sdk-linux/tools/android update sdk --filter tools --no-ui --force -a
RUN echo y | /usr/local/android-sdk-linux/tools/android update sdk --filter platform-tools --no-ui --force -a
RUN echo y | /usr/local/android-sdk-linux/tools/android update sdk --filter platform --no-ui --force -a
RUN echo y | /usr/local/android-sdk-linux/tools/android update sdk --filter build-tools-21.0.1 --no-ui

# Install Maven
RUN cd /usr/local/ && wget -nv http://ftp.tsukuba.wide.ad.jp/software/apache/maven/maven-3/3.1.1/binaries/apache-maven-3.1.1-bin.tar.gz && tar xf apache-maven-3.1.1-bin.tar.gz

# Install Gradle
RUN cd /usr/local/ && wget -nv http://services.gradle.org/distributions/gradle-1.9-all.zip && unzip -oq gradle-1.9-all.zip

# Environment variables
ENV ANDROID_HOME /usr/local/android-sdk-linux
ENV MAVEN_HOME /usr/local/apache-maven-3.1.1
ENV GRADLE_HOME /usr/local/gradle-1.9
ENV PATH $PATH:$ANDROID_HOME/tools
ENV PATH $PATH:$ANDROID_HOME/platform-tools
ENV PATH $PATH:$MAVEN_HOME/bin
ENV PATH $PATH:$GRADLE_HOME/bin

# Clean up
RUN rm -rf /usr/local/android-sdk_r23.0.2-linux.tgz
RUN rm -rf /usr/local/apache-maven-3.1.1-bin.tar.gz
RUN rm -rf /usr/local/gradle-1.9-all.zip

# Fix permissions
RUN chmod -R a+rX /usr/local/android-sdk-linux

USER jenkins

# Install some useful Jenkins plugins (Git, Android Emulator)
RUN cd $JENKINS_HOME && mkdir plugins && cd plugins && \
  wget -nv https://updates.jenkins-ci.org/latest/android-emulator.hpi && \
  wget -nv https://updates.jenkins-ci.org/latest/port-allocator.hpi && \
  wget -nv https://updates.jenkins-ci.org/latest/git.hpi &&\
  wget -nv https://updates.jenkins-ci.org/latest/git-client.hpi &&\
  wget -nv https://updates.jenkins-ci.org/latest/scm-api.hpi &&\
  wget -nv https://updates.jenkins-ci.org/latest/credentials.hpi &&\
  wget -nv https://updates.jenkins-ci.org/latest/ssh-credentials.hpi

# Copy default configuration for Maven  
COPY hudson.tasks.Maven.xml $JENKINS_HOME/hudson.tasks.Maven.xml