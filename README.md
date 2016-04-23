# osx-vagrant-virtualbox-rails
Notes on Setting up OSX, Vagrant, Virtual Box and Rails


## Based on the following 

* [Using Vagrant for Rails Development](https://gorails.com/guides/using-vagrant-for-rails-development)
* [Vlad Igleba](http://vladigleba.com/blog/2014/07/28/provisioning-a-rails-server-using-chef-part-1-introduction-to-chef-solo/)
* [Learn Chef](https://learn.chef.io/manage-a-web-app/ubuntu/configure-the-database/)
* [Debugging Chef Runs with Ruby](https://mlafeldt.github.io/blog/debugging-chef-runs-with-chef-log/)
* [Rails Server IP Binding](http://stackoverflow.com/questions/25951969/rails-4-2-and-vagrant-get-a-blank-page-and-nothing-in-the-logs#27829889)

#Start Downloads

* Start Download Vagrant for MAC OS X - [here](https://www.vagrantup.com/downloads.html) 84MB Installer

* Start Download Virtual Box v5.0.18-10 for OSX amd64 - [here](https://www.virtualbox.org/wiki/Downloads) 86MB Installer

#Install Virtual Box (Requires 180MB disk space)

* Run VirtualBox.pkg
* Run VirtualBox as an OSX application
* Should bring up ``Oracle VM VirtualBox Manager`` window


#Install Vagrant (Requires 235MB disk space)

* Run Vagrant.pkg

```
$ vagrant -v
Vagrant 1.8.1
```

#Install Vagrant Plugins

```
$ vagrant plugin install vagrant-vbguest
Installing the 'vagrant-vbguest' plugin. This can take a few minutes...
Installed the plugin 'vagrant-vbguest (0.11.0)'!
```

Took a minute or so (as promised)

```
$ vagrant plugin install vagrant-librarian-chef-nochef
Installing the 'vagrant-librarian-chef-nochef' plugin. This can take a few minutes...
Installed the plugin 'vagrant-librarian-chef-nochef (0.2.0)'!
```

Took a minute or so (as promised)

*Update:* Try this to download and install the box first (may save the wait later on)
```
$ vagrant box add ubuntu/trusty64
```
*Note:* No need to wait for this to complete at this point, but it is needed by the time you use ``vagrant up``


# Make a demo PizzaStore Rails App

```
$ rails new pizzastore --skip-spring --skip-test-unit --database=postgresql
Using -d=postgresql -T -B --skip-spring from /Users/stuart/.railsrc
      create  
      create  README.rdoc
      create  Rakefile
      create  config.ru
      create  .gitignore
      create  Gemfile
      create  app
      create  app/assets/javascripts/application.js
      create  app/assets/stylesheets/application.css
      create  app/controllers/application_controller.rb
      create  app/helpers/application_helper.rb
      create  app/views/layouts/application.html.erb
      create  app/assets/images/.keep
      create  app/mailers/.keep
      create  app/models/.keep
      create  app/controllers/concerns/.keep
      create  app/models/concerns/.keep
      create  bin
      create  bin/bundle
      create  bin/rails
      create  bin/rake
      create  bin/setup
      create  config
      create  config/routes.rb
      create  config/application.rb
      create  config/environment.rb
      create  config/secrets.yml
      create  config/environments
      create  config/environments/development.rb
      create  config/environments/production.rb
      create  config/environments/test.rb
      create  config/initializers
      create  config/initializers/assets.rb
      create  config/initializers/backtrace_silencers.rb
      create  config/initializers/cookies_serializer.rb
      create  config/initializers/filter_parameter_logging.rb
      create  config/initializers/inflections.rb
      create  config/initializers/mime_types.rb
      create  config/initializers/session_store.rb
      create  config/initializers/wrap_parameters.rb
      create  config/locales
      create  config/locales/en.yml
      create  config/boot.rb
      create  config/database.yml
      create  db
      create  db/seeds.rb
      create  lib
      create  lib/tasks
      create  lib/tasks/.keep
      create  lib/assets
      create  lib/assets/.keep
      create  log
      create  log/.keep
      create  public
      create  public/404.html
      create  public/422.html
      create  public/500.html
      create  public/favicon.ico
      create  public/robots.txt
      create  tmp/cache
      create  tmp/cache/assets
      create  vendor/assets/javascripts
      create  vendor/assets/javascripts/.keep
      create  vendor/assets/stylesheets
      create  vendor/assets/stylesheets/.keep
$ cd pizzastore/
$ git init
$ git add .
$ git commit -m'Intial Commit'
```

# Setup Vagrant in the App

```
$ vagrant init
A `Vagrantfile` has been placed in this directory. You are now
ready to `vagrant up` your first virtual environment! Please read
the comments in the Vagrantfile as well as documentation on
`vagrantup.com` for more information on using Vagrant.
```
Put this content in the ``Vagrantfile``
```
# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Use Ubuntu 14.04 Trusty Tahr 64-bit as our operating system
  config.vm.box = "ubuntu/trusty64"

  # Configurate the virtual machine to use 2GB of RAM
  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "2048"]
  end

  # Forward the Rails server default port to the host
  config.vm.network :forwarded_port, guest: 3000, host: 3001
  config.vm.network "private_network", type: "dhcp"

  # Use Chef Solo to provision our virtual machine
  config.vm.provision :chef_solo do |chef|
    
    chef.log_level = ENV.fetch("CHEF_LOG", "info").downcase.to_sym

    chef.cookbooks_path = ["cookbooks", "site-cookbooks"]

    chef.add_recipe "apt"
    chef.add_recipe "ruby_build"
    chef.add_recipe "rbenv::user"
    chef.add_recipe "rbenv::vagrant"
    chef.add_recipe "vim"
    chef.add_recipe "postgresql::server"
    chef.add_recipe "postgresql::ruby"
    chef.add_recipe "pizzastore::database"

    # Install Ruby 2.2.1 and Bundler
    # Set an empty root password for MySQL to make things simple
    chef.json = {
      rbenv: {
        user_installs: [{
          user: 'vagrant',
          rubies: ["2.2.1"],
          global: "2.2.1",
          gems: {
            "2.2.1" => [
              { name: "bundler" }
            ]
          }
        }]
      },
      postgresql: {
        password: {
          postgres: "postgres"
        }
      }
    }
  end
end
```

```
$ git add .
$ git commit -m'Add Vagrantfile'
```

## What does this ``Vagrantfile`` do?

* ``vi: set ft=ruby :`` - 'magical modeline' Tells vi to support ruby syntax for this file
* ``config.vm.provision :chef_solo do |chef|`` - Chef Solo is a simple provisioner which uses [``solo-mode``](https://docs.chef.io/chef_solo.html) and doesn't need a lot of configuration
* ``chef.add_recipe "xxx"`` - Tells chef to install [``xxx`` recipe](https://docs.chef.io/recipes.html)
* ``chef.json = {`` - Place to provide configuration for the recipies 


# Setup Chef in the App

```
$ touch Cheffile
```

Add this content to the file
```
site "http://community.opscode.com/api/v1"

cookbook 'apt'
cookbook 'build-essential'
cookbook 'database', '~> 5.1.2'
cookbook 'postgres', '~> 2.17.3'
cookbook 'ruby_build'
cookbook 'rbenv', git: 'https://github.com/aminin/chef-rbenv'
cookbook 'vim'
```

```
$ git add .
$ git commit -m'Add Cheffile'
```

# Add Custom Recipe to Setup Database

* Review the files in the [site-cookbooks](./site-cookbooks) folder

# Start Vagrant and Download Image

*Note:* It could take several hours to download this image, in this case ``ubuntu/trusty64``

```
$ vagrant up
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Box 'ubuntu/trusty64' could not be found. Attempting to find and install...
    default: Box Provider: virtualbox
    default: Box Version: >= 0
==> default: Loading metadata for box 'ubuntu/trusty64'
    default: URL: https://atlas.hashicorp.com/ubuntu/trusty64
==> default: Adding box 'ubuntu/trusty64' (v20160406.0.0) for provider: virtualbox
    default: Downloading: https://atlas.hashicorp.com/ubuntu/boxes/trusty64/versions/20160406.0.0/providers/virtualbox.box
    default: Progress: 3% (Rate: 239k/s, Estimated time remaining: 1:03:30)
```

# Debugging Vagrant and Chef

If you experience problems with ``vagrant up`` and need to debug you have a few choices

* ``$ vagrant destroy`` - will completely destroy in the box and let you try again
* ``$ vagrant provision`` - will just run the chef part again
* ``$ CHEF_LOG=debug vagrant provision`` - will run the chef part will full logging

# ssh into the virtual machine

You can get in via
```
$ ssh vagrant@127.0.0.1 -p 2222
```
The default password for ``vagrant`` is ``vagrant``

But I think the official way is 
```
$ vagrant ssh
```

# Setting up the rails app in the VM

*Note:* You should be in an ssh shell on the vm at this point

```
$ cd /vagrant
$ bin/bundle install
$ bin/rake db:migrate
$ bin/rails s -b 0.0.0.0
```


Open the forwarded port on the host OSX [http://localhost:3001/](http://localhost:3001/)


