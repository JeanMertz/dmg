Description
===========

Lightweight resource and provider to install OS X applications (.app) from dmg files.

Requirements
============

## Platform:

* Mac OS X

Resources and Providers
=======================

dmg\_package
------------

This resource will install a DMG "Package". It will retrieve the DMG from a remote URL, mount it using OS X's `hdid`, copy the application/file to the specified destination (/Applications), and detach the image using `hdiutil`. The dmg file will be stored in the `Chef::Config[:file_cache_path]`. If you want to install an application or file that has already been downloaded (not using the `source` parameter), copy it to the appropriate location. You can find out what directory this is with the following command on the node to run chef:

    knife exec -E 'p Chef::Config[:file_cache_path]' -c /etc/chef/client.rb

Optionally, the LWRP can install an "mpkg" package using `sudo installer`.

# Actions:

* :install - Installs the application (default action).

# Parameter attributes:

* `app` - This is the name of the application used by default for the /Volumes directory and the .app directory copied to /Applications.
* `source` - remote URL for the dmg to download if specified. Default is nil.
* `destination` - directory to copy the .app into. Default is /Applications.
* `checksum` - sha256 checksum of the dmg to download. Default is nil.
* `extension` - extension of file, `String` or `false`. Default is "app". When using "mpkg", the destination must be /Applications.
* `volumes_dir` - Directory under /Volumes where the dmg is mounted. If not specified, the script will try to find the correct directory.
* `dmg_name` - Specify the name of the dmg if it is not the same as `app`, or if the name has spaces.

Usage Examples
==============

Install `/Applications/Tunnelblick.app` from the primary download site.

    dmg_package "Tunnelblick" do
      source "http://tunnelblick.googlecode.com/files/Tunnelblick_3.1.2.dmg"
      checksum "a3fae60b6833175f32df20c90cd3a3603a"
    end

Install Google Chrome. Uses the `dmg_name` because the application name has spaces. Installs in `/Applications/Google Chrome.app`.

    dmg_package "Google Chrome" do
      dmg_name "googlechrome"
      source "https://dl-ssl.google.com/chrome/mac/stable/GGRM/googlechrome.dmg"
      checksum "7daa2dc5c46d9bfb14f1d7ff4b33884325e5e63e694810adc58f14795165c91a"
    end

Install Dropbox. Optionally you can use `volumes_dir` to specify the mounted directory, but the script should automatically detect this for you. Installs in `/Applications/Dropbox.app`.

    dmg_package "Dropbox" do
      volumes_dir "Dropbox Installer"
      source "http://www.dropbox.com/download?plat=mac"
      checksum "b4ea620ca22b0517b75753283ceb82326aca8bc3c86212fbf725de6446a96a13"
    end

Install MacIrssi to `~/Applications` from the local file downloaded to the cache path into an Applications directory in the current user's home directory. Chef should run as a non-root user for this.

    directory "#{ENV['HOME']}/Applications"

    dmg_package "MacIrssi" do
      destination "#{ENV['HOME']}/Applications"
    end

Install Virtualbox to `/Applications` from the .mpkg:

    dmg_package "Virtualbox" do
      source "http://dlc.sun.com.edgesuite.net/virtualbox/4.0.8/VirtualBox-4.0.8-71778-OSX.dmg"
      extension "mpkg"
    end

Install PastebotSync.prefPane to `~/Library/PreferencePanes`. When setting the `extension` to `prefPane` the default `destination` becomes `~/Library/PreferencePanes`. You can also specify a custom destination like `/Library/PreferencePanes` to install the prefPane for all users.

  dmg_package 'PastebotSync' do
    source 'http://tapbots.net/pastebot/PastebotSync.dmg'
    extension 'prefPane'
  end


To do
=====

A few things remain outstanding to make this cookbook "1.0" quality.

* support downloading a .dmg.zip and unzipping it
* specify a local .dmg already downloaded in another location (like ~/Downloads)

Some things that would be nice to have at some point.

* be able to automatically accept license agreements

License and Author
==================

* Copyright 2011, Joshua Timberman <cookbooks@housepub.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
