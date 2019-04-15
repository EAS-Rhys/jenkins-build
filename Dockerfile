FROM jenkins/jenkins:2.92

USER root

RUN echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get install -y libltdl7 curl git-core unzip && rm -rf /var/lib/apt/lists/*

# copy config
COPY config/*.xml  /usr/share/jenkins/ref/

# copy secrets
COPY config/*.key /usr/share/jenkins/ref/
COPY config/secrets/ /usr/share/jenkins/ref/secrets
RUN ls /usr/share/jenkins/ref/secrets

# copy plugins
COPY config/plugins.txt /usr/share/jenkins/ref/

# add security
COPY config/security.groovy /usr/share/jenkins/ref/init.groovy.d/security.groovy

# disable csrf
COPY config/csrf.groovy /usr/share/jenkins/ref/init.groovy.
d/csrf.groovy

# import jobs loop
COPY config/jobs/* /tmp_jobs/
RUN for job in /tmp_jobs/*.xml; do job_no_ext=${job%%.*} && just_job=${job_no_ext##*/} && mkdir -p "/usr/share/jenkins/ref/jobs/${just_job}" && cp $job "/usr/share/jenkins/ref/jobs/${just_job}/config.xml"; done

# fix permissions
RUN chown -R jenkins:jenkins /usr/share/jenkins/ref

# drop back to jenkins user
USER jenkins

# install plugins
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.txt

# disable initial setup wizard
ENV JAVA_OPTS "-Djenkins.install.runSetupWizard=false"