# Infrastructure Migration Solution - Static IPs repository 

The repository contains IMS premigration scripts for Static IP migration on top of MS Windows OS.  

## Prerequisities:
WinRM setup and enabled - all necesssary prerequisite scripts from ansible are included in setup section  
  
See also:  
https://docs.ansible.com/ansible/2.8/user_guide/windows_setup.html  
https://docs.ansible.com/ansible/latest/user_guide/windows_winrm.html  
  
Default authentication method is Kerberos  

## Recommendation
Integrate as CloudForms premigration playbook utilizing Embeded Ansible feature  

## Cnfiguration
Folder files/pre-migrate.ps1 contains static configuration for creation of local admin user that will  
configure and execute tasks connected to backup and restore of static network settings.  
  
Inventory file needs to point to IP address or fqdn of the machine.  
  
Group_vars or vars of the playbook include configuration for Windows remote connection.
