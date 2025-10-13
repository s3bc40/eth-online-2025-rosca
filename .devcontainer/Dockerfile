# Use the official Node.js 22 image
FROM ubuntu:24.04
ARG NODE_VERSION=22.20.0
ARG USERNAME=ubuntu

# Use bash for the shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install curl and Java
RUN apt update && apt install -y build-essential \
    curl \
    git \
    gradle \
    maven \
    openjdk-21-jdk \
    wget \
    sudo \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/nopasswd \
    && chmod 0440 /etc/sudoers.d/nopasswd 

# Add placeholder docker group
RUN groupadd docker \
    && usermod -aG docker $USERNAME

# Use ubuntu user (non-root)
USER $USERNAME
WORKDIR /home/$USERNAME

# Download and install nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash \
    && export NVM_DIR="$HOME/.nvm" \
    && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
    && echo node > "$HOME/.nvmrc" \
    && nvm install $NODE_VERSION \
    && nvm use $NODE_VERSION \
    && echo 'export NVM_DIR="$HOME/.nvm"' >> "$HOME/.bashrc" \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> .bashrc \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> .bashrc

# Install pnpm and turbo
ENV PNPM_HOME=/home/ubuntu/.local/share/pnpm
RUN curl -fsSL https://get.pnpm.io/install.sh | bash - \
    && export PATH="$PNPM_HOME:$PATH" \
    && pnpm add turbo --global \
    && echo 'export PNPM_HOME="$HOME/.local/share/pnpm"' >> .bashrc \
    && echo 'export PATH="$PNPM_HOME:$PATH"' >> .bashrc

# Download and install foundry
RUN curl -L https://foundry.paradigm.xyz | bash \
    && export PATH="$HOME/.foundry/bin:$PATH" \
    && foundryup \
    && echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> .bashrc