# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.


require 'rake/gempackagetask'


package = Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end

desc "Install Buildr from source"
task :install=>["#{package.package_dir}/#{package.gem_file}"] do |task|
  print "Installing #{spec.name} ... "
  args = Config::CONFIG['ruby_install_name'], '-S', 'gem', 'install', "#{package.package_dir}/#{package.gem_file}"
  args.unshift('sudo') if sudo_needed?
  sh *args
  puts "[x] Installed Buildr #{spec.version}"
end

desc "Uninstall previous rake install"
task :uninstall do |task|
  puts "Uninstalling #{spec.name} ... "
  args = Config::CONFIG['ruby_install_name'], '-S', 'gem', 'uninstall', spec.name, '--version', spec.version.to_s
  args.unshift('sudo') if sudo_needed?
  sh *args
  puts "[x] Uninstalled Buildr #{spec.version}"
end


desc "Compile Java libraries used by Buildr"
task :compile do
  puts "Compiling Java libraries ..."
  args = Config::CONFIG['ruby_install_name'], File.expand_path(RUBY_PLATFORM[/java/] ? '_jbuildr' : '_buildr'), '--buildfile', 'buildr.buildfile', 'compile'
  args << '--trace' if Rake.application.options.trace
  sh *args
end
file Rake::GemPackageTask.new(spec).package_dir=>:compile
file Rake::GemPackageTask.new(spec).package_dir_path=>:compile

# We also need the other packages (JRuby if building on Ruby, and vice versa)
# Must call new with block, even if block does nothing, otherwise bad things happen.
@specs.values.each do |s|
  Rake::GemPackageTask.new(s) { |task| }
end


desc "Upload snapshot packages over to people.apache.org"
task :snapshot=>[:package] do
  rm_rf '_snapshot' # Always start with empty directory
  puts "Copying existing gems from Apache"
  sh 'rsync', '--progress', '--recursive', 'people.apache.org:public_html/buildr/snapshot/', '_snapshot/'
  puts "Copying new gems over"
  cp FileList['pkg/{*.gem,*.tgz,*.zip}'], '_snapshot/gems'
  puts "Generating gem index ..."
  sh 'gem', 'generate_index', '--directory', '_snapshot'
  puts "Copying gem and index back to Apache"
  sh 'rsync', '--progress', '--recursive', '_snapshot/', 'people.apache.org:public_html/buildr/snapshot/'
end
task(:clobber) { rm_rf '_snapshot' }
