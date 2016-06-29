include_recipe "git"

package "zsh" do
  action :install
end

directory "/var/lib/ohmyzsh" do
  mode 0755
  recursive true
end

git "/var/lib/ohmyzsh" do
  repository "https://github.com/robbyrussell/oh-my-zsh.git"
  # update this from time to time, but avoid a sync during every chef-run
  reference "8ac1859f377b5292597f11f5973bae1ebc8e2dce"
  action :sync
  # if github is down, don't fail the chef runs everywhere
  ignore_failure true
end


# easily said.. we're at least usually on vagrant, when running in chef-solo
if Chef::Config[:solo]
  users = [{'id' => "vagrant"}]
else
  # if we are testing with test-kitchen, we are not always running chef-solo ;-)
  begin
    users = search(:users, 'groups:sysadmin AND NOT action:remove')
  rescue Net::HTTPServerException => http_error
    if http_error.response.code == "404"
      Chef::Log.warn "No users, no work"
      users = []
    end
  end
end

users.reject{|u| ! File.directory?("/home/#{u['id']}")}.each do |u|
  template "/home/#{u['id']}/.zshrc" do
    source "zshrc.erb"
    owner u['id']
    group u['id']
    action :create
  end

  file "/home/#{u['id']}/.zshrc_userconfig" do
    owner u['id']
    group u['id']
    mode "0600"
    content u['ohmyzsh-commands']
    action :create
  end
end

user "root" do
  shell "/bin/zsh"
end

template "/root/.zshrc" do
  source "zshrc.erb"
  owner "root"
  group "root"
  action :create
end
