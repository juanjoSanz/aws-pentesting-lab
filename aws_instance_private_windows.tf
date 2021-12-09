# Windows AD Pen-Testing lab
# Based on https://blog.focal-point.com/how-to-build-a-cheap-active-directory-pen-test-lab-in-aws-without-any-effort
# CloudFormation code: https://cf-template-pub.s3.us-east-2.amazonaws.com/pentest-lab.json


//Vulnerable Instance: Microsoft Windows Server 2012 R2

// Ami Id: ami-09a015f8b891cdc6c
// Ami Alias: /aws/service/marketplace/prod-miayn6czrf6yi/2021.09.15 Learn More  New
// Product Code: pbucpm8t34wjexnsv8hgyaf6

variable "admin_password" {
  description = "Windows Administrator password to login as."
  default = "123456789"  # vulnerable password listed by default in Infection Monkey
}
variable "DomainDNSName" {
  description = "DomainDNSName"
  default = "DomainDNSName"
}

variable "DomainNetBiosName" {
  description = "DomainNetBiosName"
  default = "DomainNetBiosName"
}



# data "http" "ftpu" {
#   url = "hhttps://www.exploit-db.com/apps/6388a2ae7dd2965225b3c8fad62f2b3b-ftpu_10.zip"

#   # Optional request headers
#   request_headers = {
#     Accept = "application/zip"
#   }
# }

data "aws_ami" "windowsserver2012R2ami" {
  most_recent = true
  owners = ["801119661308"]  

  filter {
    name   = "name"
    values = ["*Windows_Server-2012-R2_RTM-English-64Bit-Base*"]
  }
}


resource "aws_instance" "windowsserver2012R2" {
  count         = var.deploment-control["windowsserver"] ? 1 :0     // control variable from variables.tf

  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    type     = "winrm"
    user     = "Administrator"
    password = var.admin_password

    # set from default of 5m to 10m to avoid winrm timeout
    timeout = "10m"
  }

  ami           = data.aws_ami.windowsserver2012R2ami.id
  instance_type = "t2.micro"
  #key_name      = "key12345"
  key_name                    = aws_key_pair.kali-key-pair.key_name
  private_ip    = "10.0.1.10"
  subnet_id                   = aws_subnet.privateSubnet.id
  vpc_security_group_ids = [aws_security_group.SecurityGroup-VulnerableMachines.id]
  tags = {
    Name = "Windows Server 2012 R2"
  }

  # Vulnerability - Konica Minolta FTP Utility 1.00 - CWD Command Overflow (SEH) 
  # https://www.exploit-db.com/exploits/39215
  # https://security.stackexchange.com/questions/119107/install-a-vulnerable-service-for-windows-7



  # provisioner "file" {
  #   source     = data.http.ftpu
  #   destination = "C:/6388a2ae7dd2965225b3c8fad62f2b3b-ftpu_10.zip"
  #   # connection   = {
  #   #   type       = "winrm"
  #   #   user       = "Administrator"
  #   #   password   = var.admin_password
  #   #   agent       = "false"
  #   # }
  # }

  # Note that terraform uses Go WinRM which doesn't support https at this time. If server is not on a private network,
  # recommend bootstraping Chef via user_data.  See asg_user_data.tpl for an example on how to do that.
  user_data = <<EOF
<script>
  winrm quickconfig -q & winrm set winrm/config @{MaxTimeoutms="1800000"} & winrm set winrm/config/service @{AllowUnencrypted="true"} & winrm set winrm/config/service/auth @{Basic="true"}
</script>
<powershell>
  # Disable Win Firewall
  Get-NetFirewallProfile | Set-NetFirewallProfile -Enabled False
  #netsh advfirewall firewall add rule name="WinRM in" protocol=TCP dir=in profile=any localport=5985 remoteip=any localip=any action=allow
  # Set Administrator password
  $admin = [adsi]("WinNT://./administrator, user")
  $admin.psbase.invoke("SetPassword", "${var.admin_password}")
  # Install AD
  #Install-WindowsFeature AD-Domain-Services, rsat-adds -IncludeAllSubFeature
  #Install-ADDSForest -DomainName "${var.DomainDNSName}" -SafeModeAdministratorPassword (ConvertTo-SecureString '"${var.admin_password}"' -AsPlainText -Force) -DomainMode Win2012R2 -DomainNetbiosName "${var.DomainNetBiosName}" -ForestMode Win2012R2 -Confirm:$false -Force
  # Restart AD service
  #Restart-Service NetLogon -EA 0
</powershell>
EOF


  depends_on = [
    aws_vpc.VPC,
    aws_subnet.privateSubnet,
    aws_route_table.PublicRouteTable,
    aws_security_group.SecurityGroup-VulnerableMachines
  ]

}






/*
    "DC1": {
      "Type": "AWS::EC2::Instance",
      "Metadata": {
        "AWS::CloudFormation::Init": {
            "configSets": {
                "config": [
                  "setup",
                  "rename",
                  "installADDS",
                  "finalize"
                ]
            },
            "setup": {
                "files": {
                  "c:\\cfn\\cfn-hup.conf": {
                    "content": {
                      "Fn::Join": [
                        "",
                        [
                          "[main]\n",
                          "stack=",
                          {
                            "Ref": "AWS::StackName"
                          },
                          "\n",
                          "region=",
                          {
                            "Ref": "AWS::Region"
                          },
                          "\n"
                        ]
                      ]
                    }
                  },
                  "c:\\cfn\\hooks.d\\cfn-auto-reloader.conf": {
                    "content": {
                      "Fn::Join": [
                        "",
                        [
                          "[cfn-auto-reloader-hook]\n",
                          "triggers=post.update\n",
                          "path=Resources.DC1.Metadata.AWS::CloudFormation::Init\n",
                          "action=cfn-init.exe -v -c config -s ",
                          {
                            "Ref": "AWS::StackId"
                          },
                          " -r DC1",
                          " --region ",
                          {
                            "Ref": "AWS::Region"
                          },
                          "\n"
                        ]
                      ]
                    }
                  },
                  "c:\\cfn\\scripts\\Set-StaticIP.ps1": {
                    "content": {
                      "Fn::Join": [
                        "",
                        [
                          "$netip = Get-NetIPConfiguration;",
                          "$ipconfig = Get-NetIPAddress | ?{$_.IpAddress -eq $netip.IPv4Address.IpAddress};",
                          "Get-NetAdapter | Set-NetIPInterface -DHCP Disabled;",
                          "Get-NetAdapter | New-NetIPAddress -AddressFamily IPv4 -IPAddress $netip.IPv4Address.IpAddress -PrefixLength $ipconfig.PrefixLength -DefaultGateway $netip.IPv4DefaultGateway.NextHop;",
                          "Get-NetAdapter | Set-DnsClientServerAddress -ServerAddresses $netip.DNSServer.ServerAddresses;",
                          "\n"
                        ]
                      ]
                    }
                  }
                },
                "services": {
                  "windows": {
                    "cfn-hup": {
                      "enabled": "true",
                      "ensureRunning": "true",
                      "files": [
                        "c:\\cfn\\cfn-hup.conf",
                        "c:\\cfn\\hooks.d\\cfn-auto-reloader.conf"
                      ]
                    }
                  }
                },
                "commands": {
                  "a-disable-win-fw": {
                    "command": {
                      "Fn::Join": [
                        "",
                        [
                          "powershell.exe -Command \"Get-NetFirewallProfile | Set-NetFirewallProfile -Enabled False"
                        ]
                      ]
                    },
                    "waitAfterCompletion": "0"
                  }
                }
            },
            "rename": {
                "commands": {
                  "a-set-static-ip": {
                    "command": {
                      "Fn::Join": [
                        "",
                        [
                          "powershell.exe -ExecutionPolicy RemoteSigned -Command c:\\cfn\\scripts\\Set-StaticIP.ps1"
                        ]
                      ]
                    },
                    "waitAfterCompletion": "15"
                  },
                  "b-run-powershell-RenameComputer-no-reboot": {
                    "command": {
                      "Fn::Join": [
                        "",
                        [
                          "powershell.exe Rename-Computer -NewName DC1 -force -restart"
                        ]
                      ]
                    },
                    "waitAfterCompletion": "forever"
                  }
                }
            },
            "installADDS": {
                "commands": {
                    "1-install-prereqs": {
                        "command": {
                          "Fn::Join": [
                            "",
                            [
                              "powershell.exe -Command \"Install-WindowsFeature AD-Domain-Services, rsat-adds -IncludeAllSubFeature"
                            ]
                          ]
                        },
                        "waitAfterCompletion": "0"
                    },
                    "2-install-adds": {
                        "command": {
                          "Fn::Join": [
                            "",
                            [
                              "powershell.exe -Command Install-ADDSForest -DomainName ",
                              {
                                "Ref": "DomainDNSName"
                              },
                              " -SafeModeAdministratorPassword (ConvertTo-SecureString '",
                              {
                                "Ref": "AdminPassword"
                              },
                              "' -AsPlainText -Force) -DomainMode Win2012R2 -DomainNetbiosName ",
                              {
                                "Ref": "DomainNetBiosName"
                              },
                              " -ForestMode Win2012R2 -Confirm:$false -Force"
                            ]
                          ]
                        },
                        "waitAfterCompletion": "forever"
                    },
                    "3-restart-service": {
                        "command": {
                        "Fn::Join": [
                            "",
                            [
                                "powershell.exe -Command Restart-Service NetLogon -EA 0"
                            ]
                        ]
                        },
                        "waitAfterCompletion": "20"
                    },    
                    "4-start-ADWS": {
                        "command": {
                          "Fn::Join": [
                            "",
                            [
                              "powershell.exe -Command $s = Get-Service -Name ADWS; while ($s.Status -ne 'Running'){ Start-Service ADWS; Start-Sleep 3 }"
                            ]
                          ]
                        },
                        "waitAfterCompletion": "30"
                    },                    
                    "5-create-adminuser": {
                        "command": {
                        "Fn::Join": [
                        "",
                        [
                          "powershell.exe -Command $u = New-ADUser ",
                          {
                            "Ref": "DomainAdminUser"
                          },
                          " -SamAccountName ",
                          {
                            "Ref": "DomainAdminUser"
                          },                  
                          " -UserPrincipalName ",
                          {
                            "Ref": "DomainAdminUser"
                          },
                          "@",
                          {
                            "Ref": "DomainDNSName"
                          },
                          " -AccountPassword (ConvertTo-SecureString '",
                          {
                            "Ref": "AdminPassword"
                          },
                          "' -AsPlainText -Force) -Enabled $true -PasswordNeverExpires $true -PassThru; Add-ADGroupMember -Identity 'domain admins' -Members $u"
                        ]
                      ]
                    },
                    "waitAfterCompletion": "0"
                    },
                    "6-create-spnuser": {
                        "command": {
                        "Fn::Join": [
                        "",
                        [
                          "powershell.exe -Command $u = New-ADUser ",
                          {
                            "Ref": "SPNUser"
                          },
                          " -SamAccountName ",
                          {
                            "Ref": "SPNUser"
                          },
                          " -UserPrincipalName ",
                          {
                            "Ref": "SPNUser"
                          },
                          "@",
                          {
                            "Ref": "DomainDNSName"
                          },
                          " -AccountPassword (ConvertTo-SecureString 'Summer2019!' -AsPlainText -Force) -Enabled $true -PasswordNeverExpires $true -PassThru; Add-ADGroupMember -Identity 'domain admins' -Members $u"
                        ]
                      ]
                    },
                    "waitAfterCompletion": "0"                
                    },                  
                    "7-make-user-spn": {
                        "command": {
                        "Fn::Join": [
                            "",
                            [
                                "powershell.exe -Command setspn -A SERVICE_X/SERVICE_X ",
                                {
                                  "Ref": "SPNUser"
                                }
                            ]
                        ]
                        },
                        "waitAfterCompletion": "0"
                    }
              }
            },
            "finalize": {
                "commands": {
                    "a-signal-success": {
                        "command": {
                        "Fn::Join": [
                        "",
                        [
                          "cfn-signal.exe -e 0 ",
                          {
                            "Fn::Base64": {
                              "Ref": "DomainControllerWaitHandle"
                            }
                          },
                          ""
                        ]
                        ]
                        }
                    }
                }
            }
        }
      },
      "Properties": {
        "BlockDeviceMappings": [
          {
            "DeviceName": "/dev/sda1",
            "Ebs": {
              "VolumeSize": "40"
            }
          }
        ],
        "ImageId": {
          "Ref": "WindowsAmiId"
        },
        "InstanceType": "t2.micro",
        "KeyName": {
          "Ref": "KeyName"
        },
        "DisableApiTermination": "false",
        "InstanceInitiatedShutdownBehavior": "stop",
        "Monitoring": "false",
        "Tags": [
          {
            "Key": "Name",
            "Value": "Windows Domain Controller"
          }
        ],
        "NetworkInterfaces": [
          {
            "DeleteOnTermination": "true",
            "Description": "Primary network interface",
            "DeviceIndex": 0,
            "SubnetId": {
              "Ref": "PublicSubnet"
            },
            "PrivateIpAddresses": [
              {
                "PrivateIpAddress": "192.168.1.100",
                "Primary": "true"
              }
            ],
            "GroupSet": [
              {
                "Ref": "LabSecurityGroup"
              }
            ]
          }
        ],
        "UserData": {
          "Fn::Base64": {
            "Fn::Join": [
              "",
              [
                "<script>\n",
                "cfn-init.exe -v -c config -s ",
                {
                  "Ref": "AWS::StackId"
                },
                " -r DC1",
                " --region ",
                {
                  "Ref": "AWS::Region"
                },
                "\n",
                "</script>\n"
              ]
            ]
          }
        }
      }
    },
*/