#
# Cookbook Name:: dmg
# Provider:: package
#
# Copyright 2011, Joshua Timberman
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

def load_current_resource
  @dmgpkg = Chef::Resource::DmgPackage.new(new_resource.name)
  @dmgpkg.app(new_resource.app)
  extension = new_resource.type if new_resource.type
  extension = new_resource.extension ? ".#{new_resource.extension}" : ''
  Chef::Log.debug("Checking for application #{new_resource.app}")

  # Set extension
  new_resource.extension(new_resource.type) if new_resource.type
  new_resource.extension(new_resource.extension ? ".#{new_resource.extension}" : '')

  # Set correct destination based on extension
  case new_resource.extension
  when ".prefPane"
    new_resource.destination(::File.expand_path('~/Library/PreferencePanes')) if new_resource.destination == '/Applications'
  else
    new_resource.destination(::File.expand_path(new_resource.destination))
  end



  if new_resource.installed_resource
    installed = ::File.exist?(new_resource.installed_resource)
  else
    installed = ::File.exist?("#{::File.expand_path(new_resource.destination)}/#{new_resource.app}#{new_resource.extension}")
  end
  @dmgpkg.installed(installed)
end

action :install do
  unless @dmgpkg.installed
    puts 'parameter "type" is deprecated, please use "extension" instead' if new_resource.type

    new_resource.volumes_dir(new_resource.volumes_dir ? "/Volumes/#{new_resource.volumes_dir}" : nil)
    dmg_name = new_resource.dmg_name ? new_resource.dmg_name : new_resource.app
    dmg_file = "#{Chef::Config[:file_cache_path]}/#{dmg_name}.dmg"

    if new_resource.source =~ /^(https?|ftp|git):\/\/.+$/i
      remote_file dmg_file do
        source new_resource.source
        checksum new_resource.checksum if new_resource.checksum
      end
    elsif new_resource.source
      cookbook_file dmg_file do
        source new_resource.source
        checksum new_resource.checksum if new_resource.checksum
      end
    end

    ruby_block 'mount_install_unmount' do
      block do
        volumes_dir = new_resource.volumes_dir

        # Mount the image
        %x[hdiutil attach -noautoopen '#{dmg_file}'] unless %x[hdiutil info | grep -q 'image-path.*#{dmg_file}'].strip!

        # Get the volume name
        unless volumes_dir
          %x[hdiutil info -plist].gsub!(/(\t|\n)/, '')\
            .scan(/(?:<key>image-path<\/key>)<string>([^<]+)<\/string>(?:(?!<\/array>).)+(?:<key>mount-point<\/key>)<string>([^<]+)<\/string>/)\
            .each do |image_path, mount_point|
              volumes_dir = mount_point if image_path == dmg_file
            end
        end

        # Install application
        case new_resource.extension
        when ".mpkg", ".pkg"
          %x[sudo installer -pkg #{volumes_dir}/#{new_resource.app}#{new_resource.extension} -target /]
        else
          FileUtils.cp_r "#{volumes_dir}/#{new_resource.app}#{new_resource.extension}", new_resource.destination
        end

        # Unmount volume
        %x[hdiutil detach '#{volumes_dir}']
      end
    end

    if ::File.directory?("#{new_resource.destination}/#{new_resource.app}#{new_resource.extension}/Contents/MacOS/")
      file "#{new_resource.destination}/#{new_resource.app}#{new_resource.extension}/Contents/MacOS/#{new_resource.app}#{new_resource.extension}" do
        mode 0755
        ignore_failure true
      end
    end

  end
end
