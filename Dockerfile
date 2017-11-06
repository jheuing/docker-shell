# shell image
#
# VERSION: see `TAG`
FROM ubuntu:latest
MAINTAINER Jan-Hendrik Heuing "jh@heuing.io"


# install system dependencies
RUN apt-get -y -qq --force-yes update 
RUN apt-get -y -qq --force-yes install \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    build-essential \
    make \
    silversearcher-ag \
    bzip2 \
    sudo \
    locales \
    openssl \
    vim \
    tmux \
    git \
    curl \
    ruby-dev \
    zsh


# prepare locales
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen --purge --lang en_US && locale-gen
ENV LANG en_US.utf8


# create docker group, user, home
ENV HOME /home/doc

RUN groupadd -g 999 docker
RUN useradd -G sudo,docker -d ${HOME} -m -p $(openssl passwd dockerpassword) -s $(which zsh) doc
USER doc

ENV HOME /home/doc
ENV HOMESRC ${HOME}/local/src
ENV HOMEBIN ${HOME}/local/bin

RUN mkdir -p $HOME && mkdir -p $HOMESRC && mkdir -p $HOMEBIN


# clone dotfiles
ENV DOTFILE ${HOMESRC}/dotfiles
RUN git clone https://github.com/jheuing/dotfiles.git ${DOTFILE} 
RUN cd ${DOTFILE} && git submodule update --init --recursive


# link to home
RUN ln -s ${DOTFILE}/.tmux.conf ${HOME} \
    && ln -s ${DOTFILE}/.vim ${HOME} \
    && ln -s ${DOTFILE}/.vimrc ${HOME} \
    && ln -s ${DOTFILE}/.zshrc ${HOME} \
    && ln -s ${DOTFILE}/.gitignore-global ${HOME} \
    && cp ${DOTFILE}/.gitconfig ${HOME}/


# install vim bundles
RUN mkdir ${HOME}/.vim/swaps \
    && mkdir ${HOME}/.vim/backups 

RUN printf 'y' | vim +BundleInstall +qall 


# install oh-my-zsh
RUN git clone https://github.com/robbyrussell/oh-my-zsh.git ${HOME}/.oh-my-zsh \
    && ln -s ${DOTFILE}/.oh-my-zsh/themes/jh.zsh-theme ${HOME}/.oh-my-zsh/themes/jh.zsh-theme


# install docker-compose
ENV COMPOSE_VERSION 1.6.0
ENV COMPOSE_URL https://github.com/docker/compose/releases/download
RUN curl \
        -L ${COMPOSE_URL}/${COMPOSE_VERSION}/docker-compose-Linux-x86_64 \
        -o ${HOMEBIN}/docker-compose \
    && chmod 750 ${HOMEBIN}/docker-compose \
    && chown doc:doc ${HOMEBIN}/docker-compose


# install rbenv and ruby
ENV RUBY_VERSION 2.4.2

RUN git clone https://github.com/rbenv/rbenv.git ${HOME}/.rbenv \
    && echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ${HOME}/.zshrc 

ENV PATH ${HOME}/.rbenv/shims:${HOME}/.rbenv/bin:$PATH

RUN mkdir -p ${HOME}/.rbenv/plugins \
    && git clone https://github.com/rbenv/ruby-build.git ${HOME}/.rbenv/plugins/ruby-build \
    && rbenv install ${RUBY_VERSION} \
    && rbenv global ${RUBY_VERSION}


# conf container
ENV WORK /data
ENV TERM xterm-256color
VOLUME [${WORK}]
WORKDIR ${WORK}
CMD ["/usr/bin/zsh"]

