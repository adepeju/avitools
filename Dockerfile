FROM avinetworks/avitools-base:bionic

ARG tf_version="0.11.10"
ARG avi_sdk_version
ARG avi_version

RUN echo $HOME

RUN apt-get update && apt-get install -y \
    apache2-utils \
    apt-transport-https \
    curl \
    dnsutils \
    git \
    golang-1.9-go \
    httpie \
    inetutils-ping \
    iproute2 \
    jq \
    libffi-dev \
    libssl-dev \
    lua5.3 \
    make \
    netcat \
    nmap \
    python \
    python-cffi \
    python-dev \
    python-pip \
    python-virtualenv \
    slowhttptest \
    sshpass \
    tree \
    unzip \
    vim

RUN git config --global http.sslverify false

RUN pip install -U ansible==2.6.13 && pip install appdirs==1.4.3 \
    aws-google-auth \
    awscli \
    azure-cli \
    bigsuds \
    ConfigParser==3.5.0 \
    ecdsa==0.13 \
    f5-sdk \
    flask==0.12.2 \
    jinja2==2.10 \
    jsondiff \
    kubernetes \
    netaddr \
    networkx==2.0 \
    nose-html-reporting==0.2.3 \
    nose-testconfig==0.10 \
    openpyxl==2.4.9 \
    openshift \
    openstacksdk \
    pandas==0.21.0 \
    paramiko==2.4.1 \
    pexpect==4.3.0 \
    pycrypto==2.6.1 \
    pyOpenssl==17.5.0 \
    pyparsing==2.2.0 \
    pytest-cov==2.5.1 \
    pytest-xdist==1.22.0 \
    pytest==3.2.5 \
    pyvmomi \
    pyyaml==3.12 \
    requests-toolbelt==0.8.0 \
    requests==2.18.4 \
    unittest2==1.1.0 \
    vcrpy==1.11.1 \
    xlrd==1.1.0 \
    xlsxwriter

RUN pip install avisdk==${avi_sdk_version} avimigrationtools==${avi_sdk_version}
RUN pip install /tmp/avi_shell.tar.gz

RUN ansible-galaxy -c install avinetworks.aviconfig \
    avinetworks.avicontroller \
    avinetworks.avicontroller-azure \
    avinetworks.avicontroller_csp \
    avinetworks.avicontroller_vmware \
    avinetworks.avisdk \
    avinetworks.avise  \
    avinetworks.avise_csp \
    avinetworks.docker \
    avinetworks.network_interface \
    avinetworks.avimigrationtools \
    avinetworks.avise_vmware

RUN pip install git+https://github.com/openshift/openshift-restclient-python.git

RUN curl -L https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz -o openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz && \
    tar xzvf openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz && \
    chmod +x ./openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit/oc && \
    mv openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit/oc /usr/local/bin/oc && \
    rm -rf openshift-origin-client-tools*

RUN curl https://releases.hashicorp.com/terraform/${tf_version}/terraform_${tf_version}_linux_amd64.zip -o terraform_${tf_version}_linux_amd64.zip &&  \
    unzip terraform_${tf_version}_linux_amd64.zip -d /usr/local/bin && \
    rm -rf terraform_${tf_version}_linux_amd64.zip

RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN touch /etc/apt/sources.list.d/kubernetes.list && \
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update && apt-get install -y kubectl

RUN echo "export ANSIBLE_LIBRARY=$HOME/.ansible/roles/avinetworks.avisdk/library" >> /etc/bash.bashrc && \
    export GOROOT=/usr/lib/go-1.9 && \
    echo "export GOROOT=/usr/lib/go-1.9" >> /etc/bash.bashrc && \
    echo "export GOPATH=$HOME" >> /etc/bash.bashrc && \
    echo "export GOBIN=$HOME/bin" >> /etc/bash.bashrc && \
    export PATH=$PATH:/usr/lib/go-1.9/bin:$HOME/bin && \
    echo "export PATH=$PATH:/usr/lib/go-1.9/bin:$HOME/bin" >> /etc/bash.bashrc

RUN mkdir -p $HOME/src/github.com/hashicorp/terraform-provider-avi/vendor/github.com/avinetworks && \
    cd $HOME/src/github.com/hashicorp/terraform-provider-avi/vendor/github.com/avinetworks && \
    git clone https://github.com/avinetworks/terraform-provider-avi.git
RUN /usr/lib/go-1.9/bin/go get github.com/avinetworks/sdk/go/session
RUN export PATH=$PATH:/usr/lib/go-1.9/bin && \
    cd $HOME/src/github.com/hashicorp/terraform-provider-avi/vendor/github.com/avinetworks/terraform-provider-avi  && \
    export GOPATH=$HOME && \
    export GOBIN=$HOME/bin && \
    make build
RUN mkdir -p $HOME/.terraform.d/plugins/ && ln -s $HOME/bin/terraform-provider-avi ~/.terraform.d/plugins/
RUN mkdir -p /opt/terraform
RUN cp -r /usr/lib/go-1.9/bin/* /usr/local/bin/
RUN cp $HOME/bin/terraform-provider-avi /usr/local/bin/

RUN touch list && \
    echo "#!/bin/bash" >> avitools-list && \
    echo "echo "f5_converter.py"" >> avitools-list && \
    echo "echo "netscaler_converter.py"" >> avitools-list && \
    echo "echo "gss_convertor.py"" >> avitools-list && \
    echo "echo "f5_discovery.py"" >> avitools-list && \
    echo "echo "avi_config_to_ansible.py"" >> avitools-list && \
    echo "echo "ace_converter.py"" >> avitools-list && \
    echo "echo "virtualservice_examples_api.py"" >> avitools-list && \
    echo "echo "config_patch.py"" >> avitools-list && \
    echo "echo "vs_filter.py"" >> avitools-list && \
    echo "echo "terraform-provider-avi"" >> avitools-list && \
    chmod +x avitools-list && \
    cp avitools-list /bin/ && \
    cp avitools-list /usr/local/bin/ && \
    echo "alias avitools-list=/bin/avitools-list" >> ~/.bashrc

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* $HOME/.cache $HOME/go/src $HOME/src

ENV cmd cmd_to_run
CMD eval $cmd
