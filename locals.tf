# Import users from user.yaml external file

resource "null_resource" "call_generate_users" {
    provisioner "local-exec" {
        command = "bash ./generate_user_data.sh"
    }
}

locals {
    users_list = try(yamldecode(file("users.yml")).users, []) 
    server_data = try(yamldecode(file("users.yml")).server, []) 

    depends_on = [null_resource.call_generate_users]
}


locals {
    server_wireguard_private = local.server_data.wireguard_keys.private
    server_wireguard_public = local.server_data.wireguard_keys.public

    usernames = [for user in local.users_list : user.name]
    passwords = [for user in local.users_list : user.password]
    ssh_private = [for user in local.users_list : user.ssh_keys.private]
    ssh_public = [for user in local.users_list : user.ssh_keys.public]
    wireguard_private = [for user in local.users_list : user.wireguard_keys.private]
    wireguard_public = [for user in local.users_list : user.wireguard_keys.public]
}


