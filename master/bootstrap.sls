pkg_openssh-client:
  pkg.installed:
    - pkgs:
      - openssh-client

pkg_salt-master:
  pkg.installed:
    - pkgs:
      - salt-master

pkg_salt-minion:
  pkg.installed:
    - pkgs:
      - salt-minion

pkg_salt_pip_pygit2:
  pip.installed:
    - bin_env: /opt/saltstack/salt/bin/pip3
    - pkgs:
      - pygit2
    - require:
      - pkg: pkg_salt-master

pkg_age:
  pkg.installed:
    - pkgs:
      - age

pkg_cosign:
  pkg.installed:
    - pkgs:
      - cosign

pkg_curl:
  pkg.installed:
    - pkgs:
      - curl

install_sops:
  cmd.script:
    - source: salt://files/install-sops.sh
    - creates: /usr/local/bin/sops
    - require:
      - pkg: pkg_cosign
      - pkg: pkg_curl

manage_master_config:
  file.managed:
    - name: /etc/salt/master.d/bootstrap.conf
    - source: salt://files/minimal-master.conf
    - makedirs: True
    - require:
      - pkg: pkg_salt-master

master_pki_age_dir:
  file.directory:
    - name: /etc/salt/pki/master/age
    - makedirs: True
    - require:
      - pkg: pkg_salt-master

generate_age_key:
  cmd.run:
    - name: |
        age-keygen -o /etc/salt/pki/master/age/key.txt
        chmod 0600 /etc/salt/pki/master/age/key.txt
    - creates: /etc/salt/pki/master/age/key.txt
    - require:
      - pkg: pkg_age
      - pkg: pkg_salt-master
      - file: master_pki_age_dir

master_pki_ssh_dir:
  file.directory:
    - name: /etc/salt/pki/master/ssh
    - makedirs: True
    - require:
      - pkg: pkg_salt-master

generate_ssh_key_salt:
  cmd.run:
    - name: ssh-keygen -q -N '' -C 'salt@{{ grains['id'] }}' -f /etc/salt/pki/master/ssh/salt
    - creates: /etc/salt/pki/master/ssh/salt
    - require:
      - pkg: pkg_openssh-client
      - pkg: pkg_salt-master
      - file: master_pki_ssh_dir

generate_ssh_key_pillar:
  cmd.run:
    - name: ssh-keygen -q -N '' -C 'pillar@{{ grains['id'] }}' -f /etc/salt/pki/master/ssh/pillar
    - creates: /etc/salt/pki/master/ssh/pillar
    - require:
      - pkg: pkg_openssh-client
      - pkg: pkg_salt-master
      - file: master_pki_ssh_dir

salt-master:
  service.running:
    - enable: True
    - watch:
      - file: manage_master_config
    - require:
      - pkg: pkg_salt-master
      - pip: pkg_salt_pip_pygit2
      - cmd: generate_ssh_key_salt
      - cmd: generate_ssh_key_pillar

manage_minion_config:
  file.managed:
    - name: /etc/salt/minion.d/master.conf
    - source: salt://files/minimal-minion.conf
    - makedirs: True
    - require:
      - pkg: pkg_salt-minion

salt-minion:
  service.running:
    - enable: True
    - watch:
      - file: manage_minion_config
    - require:
      - pkg: pkg_salt-minion
      - service: salt-master

restart_salt_services:
  cmd.run:
    - name: |
        systemctl restart salt-master
        sleep 30
        systemctl restart salt-minion
        sleep 30

preaccept_local_minion:
  file.rename:
    - name: /etc/salt/pki/master/minions/{{ grains['id'] }}
    - source: /etc/salt/pki/master/minions_pre/{{ grains['id'] }}
    - require:
      - cmd: restart_salt_services
