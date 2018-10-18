### Purpose: 
  This project exists as a simple and extensible DDNS client to track and update a list of domains across a list of providers to help ensure timely and accurate DNS updates for a dynamic environment

### Dependencies:
  This project depends on Ruby, RubyGems and some small selection of supporting tools.

  - Go: It is recommended you install Go `2.5.1` via `rbenv` Instructions for installing can be found [here](https://github.com/rbenv/rbenv) or by running the following commands:
    ```
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

    echo `export RBENV_ROOT="$HOME/.rbenv"
          export PATH="$RBENV_ROOT/bin:$PATH"
          export PATH="$RBENV_ROOT/shims:$PATH"` > ~/.bash_profile
    source ~/.bash_profile

    rbenv install 2.5.1
    rbenv global  2.5.1
    ```

  - bundler: It is recommended you install the most recent version of bundler manually via RubyGems by running the following commands:
    ```
    gem install bundler
    ```

### Configuration:
  Minimal configuration is required for this project but it is expected that you have API urls and access tokens already provisioned for use with your provider of choice

  NOTE: At the moment of writing, only gandi is supported but it would be easy to extend the interface to other providers

### Secrets / Infrastructure:
  The project expects the supporting information to be described in an appropriate `config/secrets.yml` file that follows / requires the following format:

  ```
development:
  provider:
    api_uri: ...
    api_token: ...

production:
  provider:
    api_uri: ...
    api_token: ...
  ddns:
    domains:
      - name: domain.net
        records:
          - name: "@"
            type: A
          - name: sub
            type: A
  ```

### Deploying:
  To deploy (and run) this code you must checkout the source from revision control and in the project directory run the following commands:

  ```
  bundle install
  ruby ddns_daemon.rb
  ```

### Output:
  After deploying a daemon will be running in the background and writing to the log output files.

### Current Deployment
This application is currently deployed and supporting multiple domains on infrastructure at: https://justondavies.net
