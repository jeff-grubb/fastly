resource "fastly_tls_subscription" "my_tls_subscription" {
  domains               = [for domain in fastly_service_vcl.my_fastly_service_vcl.domain : domain.name]
  certificate_authority = "lets-encrypt"
  configuration_id      = "TLS v1.3"
}

resource "ns1_record" "domain_validation" {

  depends_on = [fastly_tls_subscription.my_tls_subscription]
  for_each = {
    # The following `for` expression (due to the outer {}) will produce an object with key/value pairs.
    # The 'key' is the domain name we've configured (e.g. a.example.com, b.example.com)
    # The 'value' is a specific 'challenge' object whose record_name matches the domain (e.g. record_name is _acme-challenge.a.example.com).
    for domain in fastly_tls_subscription.my_tls_subscription.domains :
    domain => element([
      for obj in fastly_tls_subscription.my_tls_subscription.managed_dns_challenges :
      obj if obj.record_name == "_acme-challenge.${domain}" # We use an `if` conditional to filter the list to a single element
    ], 0)                                                   # `element()` returns the first object in the list which should be the relevant 'challenge' object we need
  }

  zone            = "poc.fox"
  domain          = each.value.record_name
  type            = each.value.record_type
  ttl             = 60

  meta = {
    up = true
  }

  answers {
    answer  = each.value.record_value
  }
}

# This is a resource that other resources can depend on if they require the certificate to be issued.
# NOTE: Internally the resource keeps retrying `GetTLSSubscription` until no error is returned (or the configured timeout is reached).
resource "fastly_tls_subscription_validation" "my_tls_subscription_validation" {
  subscription_id = fastly_tls_subscription.my_tls_subscription.id
  depends_on      = [ns1_record.domain_validation]
}

data "fastly_tls_configuration" "default_tls" {
  default    = true
  depends_on = [fastly_tls_subscription_validation.my_tls_subscription_validation]
}

data "fastly_tls_configuration" "tls_one_dot_three" {
  name = "TLS v1.3"
}

resource "ns1_record" "service_hostname_record" {
  depends_on      = [fastly_tls_subscription.my_tls_subscription]
  for_each        = fastly_tls_subscription.my_tls_subscription.domains

  zone            = "poc.fox"
  domain          = each.value
  type            = "CNAME"
  ttl             = 60

  meta = {
    up = true
  }

  answers {
    answer  = [for record in data.fastly_tls_configuration.tls_one_dot_three.dns_records : record.record_value if record.record_type == "CNAME"][0]
  }
}
