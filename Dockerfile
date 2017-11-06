# shell image
#
# VERSION: see `TAG`
FROM ubuntu:latest
MAINTAINER Jan-Hendrik Heuing "jh@heuing.io"

ENV WORK /data
ENV HOME /home/doc

ENV RUBY_VERSION 2.4.2
ENV COMPOSE_VERSION 1.6.0


# install system dependencies
RUN apt-get -y -qq --force-yes update \
    && apt-get -y -qq --force-yes install \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    build-essential \
    make \
    less \
    gnupg \
    gnupg-agent \
    silversearcher-ag \
    bzip2 \
    sudo \
    locales \
    tzdata \
    openssl \
    vim \
    tmux \
    git \
    curl \
    ruby-dev \
    libpq-dev \
    libsqlite3-dev \
    zsh \
    wget \
    docker \
    docker-compose


# prepare locales
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen --purge --lang en_US && locale-gen
ENV LANG en_US.utf8


# create docker group, user, home
RUN useradd -G sudo,docker -d ${HOME} -m -p $(openssl passwd doc) -s $(which zsh) doc
USER doc

ENV HOMELOCAL ${HOME}/local
ENV HOMESRC ${HOME}/local/src
ENV HOMEBIN ${HOME}/local/bin

RUN mkdir -p $HOMELOCAL \
    && mkdir -p $HOMESRC \
    && mkdir -p $HOMEBIN \
    && mkdir -p ${HOME}/.ssh


# clone dotfiles
ENV DOTFILE ${HOMESRC}/dotfiles
RUN git clone https://github.com/jheuing/dotfiles.git ${DOTFILE} \
    && cd ${DOTFILE} \
    && git submodule update --init --recursive


# link to home
RUN ln -s ${DOTFILE}/.tmux.conf ${HOME} \
    && ln -s ${DOTFILE}/.vim ${HOME} \
    && ln -s ${DOTFILE}/.vimrc ${HOME} \
    && ln -s ${DOTFILE}/.zshrc ${HOME} \
    && ln -s ${DOTFILE}/.gitignore-global ${HOME} \
    && cp ${DOTFILE}/.gitconfig ${HOME} \
    && gpg-agent --daemon


# install vim bundles
RUN mkdir ${HOME}/.vim/swaps \
    && mkdir ${HOME}/.vim/backups \
    && printf 'y' | vim +BundleInstall +qall 


# install oh-my-zsh
RUN git clone https://github.com/robbyrussell/oh-my-zsh.git ${HOME}/.oh-my-zsh \
    && ln -s ${DOTFILE}/.oh-my-zsh/themes/jh.zsh-theme ${HOME}/.oh-my-zsh/themes/jh.zsh-theme


# install docker-compose
ENV COMPOSE_URL https://github.com/docker/compose/releases/download
RUN curl \
        -L ${COMPOSE_URL}/${COMPOSE_VERSION}/docker-compose-Linux-x86_64 \
        -o ${HOMEBIN}/docker-compose \
    && chmod 750 ${HOMEBIN}/docker-compose \
    && chown doc:doc ${HOMEBIN}/docker-compose


# install rbenv and ruby
RUN git clone https://github.com/rbenv/rbenv.git ${HOME}/.rbenv \
    && echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ${HOME}/.zshrc 

ENV PATH ${HOME}/.rbenv/shims:${HOME}/.rbenv/bin:$PATH

RUN mkdir -p ${HOME}/.rbenv/plugins \
    && git clone https://github.com/rbenv/ruby-build.git ${HOME}/.rbenv/plugins/ruby-build \
    && rbenv install ${RUBY_VERSION} \
    && rbenv global ${RUBY_VERSION}

RUN gem install bundle


# conf container
ENV TERM xterm-256color
VOLUME [${WORK}]
WORKDIR ${WORK}
CMD ["/usr/bin/zsh"]

