resource "fastly_service_vcl" "my_fastly_service_vcl" {
  name = var.service_name

  domain {
    name    = var.service_hostname
    comment = "demo"
  }

  backend {
    address           = "d2b03hize28ial.cloudfront.net"
    name              = "d2b03hize28ial_cloudfront_net"
    port              = 443
    override_host     = "www-fox-com.platformexperience.fox"
    use_ssl           = true
    ssl_check_cert    = true
    ssl_cert_hostname = "d2b03hize28ial.cloudfront.net"
    ssl_sni_hostname  = "d2b03hize28ial.cloudfront.net"
  }

  request_setting {
    name = "force tls"
    force_ssl = true
  }

  activate = true
}
