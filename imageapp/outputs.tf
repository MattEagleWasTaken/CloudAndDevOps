# –––– Output Management –––––––––––––––––––––––––––––––––––



output "app_service_url" { # To access the webapp
    description = "URL of the web app"
    value       = "https://${azurerm_linux_web_app.imageapp.default_hostname}"
}

