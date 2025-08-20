def create_certificate(params = {})
  params['cert']    ||= params[:cert]    || "-----BEGIN CERTIFICATE-----\n" \
                                            "MIIFKzCCBBOgAwIBAgISA11qRPW4BPDV/sS4j3ZP1iktMA0GCSqGSIb3DQEBCwUA\n" \
                                            "MDIxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQswCQYDVQQD\n" \
                                            "EwJSMzAeFw0yMTAzMzAxNjUyNDBaFw0yMTA2MjgxNjUyNDBaMBYxFDASBgNVBAMT\n" \
                                            "C2liYWNsb3VkLmJ5MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtMxZ\n" \
                                            "6sQ9nxarcUajNb0tbSJVhuku3UfU4nT5oYppdWH4ghLBDz2e/GnBv4o7pNRn6Orn\n" \
                                            "jbIS+IpUb7tGOK8NJGNSCVxDKPgjwwyfgyGPT+xobnzB10FOCbF15XzA645s5W7h\n" \
                                            "gWpLDHVvsGI9OPqDiN6kYEofuvynRhlsF706NQIl6moSuYYCvBmQ1co0VGh4slr6\n" \
                                            "CvK5mqUvUVX+7WZA5WoT6Uawg/76tkaOjRTvw+MvAw1bh1X9PVFYgrTeU9MCeVKu\n" \
                                            "osv6teVYacRA1cVh1MfE4YCFiwCbNgEZG5Em4HjSLHyteu7SMo2uAxYdahBpbxKL\n" \
                                            "M5zHXsyE6ja7uTUgSQIDAQABo4ICVTCCAlEwDgYDVR0PAQH/BAQDAgWgMB0GA1Ud\n" \
                                            "JQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAMBgNVHRMBAf8EAjAAMB0GA1UdDgQW\n" \
                                            "BBQ5lkExwa4PJYIKOWpsVSDYE+UotDAfBgNVHSMEGDAWgBQULrMXt1hWy65QCUDm\n" \
                                            "H6+dixTCxjBVBggrBgEFBQcBAQRJMEcwIQYIKwYBBQUHMAGGFWh0dHA6Ly9yMy5v\n" \
                                            "LmxlbmNyLm9yZzAiBggrBgEFBQcwAoYWaHR0cDovL3IzLmkubGVuY3Iub3JnLzAl\n" \
                                            "BgNVHREEHjAcgg0qLmliYWNsb3VkLmJ5ggtpYmFjbG91ZC5ieTBMBgNVHSAERTBD\n" \
                                            "MAgGBmeBDAECATA3BgsrBgEEAYLfEwEBATAoMCYGCCsGAQUFBwIBFhpodHRwOi8v\n" \
                                            "Y3BzLmxldHNlbmNyeXB0Lm9yZzCCAQQGCisGAQQB1nkCBAIEgfUEgfIA8AB2AESU\n" \
                                            "ZS6w7s6vxEAH2Kj+KMDa5oK+2MsxtT/TM5a1toGoAAABeIREH2EAAAQDAEcwRQIh\n" \
                                            "ANQPaCiRN7lqZZQAgbo+gXZt7sxbxcqDgEs4Tvx/IPOiAiAPyKcjwYoS1wd0GFSI\n" \
                                            "og7Do9LZWJ/dQmn9VZ/iDBfwOwB2AH0+8viP/4hVaCTCwMqeUol5K8UOeAl/LmqX\n" \
                                            "aJl+IvDXAAABeIREH78AAAQDAEcwRQIhAKdB0sAy8Rk6VWmByBWgge1bIZf4ty5p\n" \
                                            "xdfBInUUTNODAiAwDj+pvYOagv4rMvPtiboPjySQfVKwamECccxOdp6i3jANBgkq\n" \
                                            "hkiG9w0BAQsFAAOCAQEAMPiCumhQP4DfPukDQa//GGWpOXQYvt8YgbwiHs0+VMPM\n" \
                                            "ypQuHzB9yJZCrkyqc+GpCs+qrjjeQx4lXJ3IJCmEFluT5rUK8eddiySgg3WxkOtY\n" \
                                            "ElIqOIAczUvHIL0h9ZYQ8QaCYNYfNFTwNRtc+4t2HJmmaxN7ujeo5/QKCDEsWGPQ\n" \
                                            "7KzXq/bD7RczKTKVw56zX2kCkznFKRFclMKOl+M2EcmCxEMCNpAtrvlMZrOXcQSF\n" \
                                            "/cw4xvFfG1WH+EmM73M8UjsaslmGFuBWucUMqpATxrs4N4ej9opA2afs8sQHLNhw\n" \
                                            "45Ac/jcxOsFi0e2pGLlOxkTH/k/zTbuJ/T/Q+vEk5Q==\n" \
                                            "-----END CERTIFICATE-----"
  params['key']     ||= params[:key]     || "-----BEGIN PRIVATE KEY-----\n" \
                                            "MIIJRQIBADANBgkqhkiG9w0BAQEFAASCCS8wggkrAgEAAoICAQDfZiC8vaaxVZ4h\n" \
                                            "c1hf411WtRkdZ/p8O2sN3JP8ZvH1vb+eyMVm/1Px+NbNeJBmHSapytmmwHHYD6ce\n" \
                                            "CEElNMmEzjOoXwAf1HqtLzEd4jjxG5uIfudiDLetCgEZUcettxIf8eUezEh8oM0z\n" \
                                            "BcW+9nWkcG5OeknHVGEF6J/rYvjBMTFXKZY1WarGrgq/8MwxkEnLvdqkz3VAMlKS\n" \
                                            "I8+pfdeZfpaiwt0btIVPfR4NmP2Nm3tCnc6EPkp7qWjFUNZdIyDeMayakGyqBFuE\n" \
                                            "9OyWaHBY0AcVkdT4L99HqA0x+1PT7BDysE7l+o+UMll8rMtfGTsSFZJ8Kh/s5DIy\n" \
                                            "YdTyeBOX+EVy5yGavWOVvSM5Xq7eR/KXWzZTzgn/Lav+n2LYK+li0kfFHOm6P+/r\n" \
                                            "D3eVZaRXGdSrKOrO+xaoJvKWJPgdnDrUR67soMXUribzTQIoFd55Ws98inI9RxeB\n" \
                                            "hvHzhNWxg6o3e/ySO4huOneU6Cqy7LzuB+Dxk1Q1H1rbVHveW8X9YavsH8wrHxOs\n" \
                                            "Z/iCK/aFqI1MVYP/pIQjYhqoEEELY/567K6zDNQtPA534Fu6Oyz5/LCK9QjrSbQ7\n" \
                                            "2b037ZA+zQuSq2dXp5bGWs3omvgTkoHgFkatbxvbQatJmv5DwXZyaGErpfIO+r0D\n" \
                                            "tGS4Z4lsc2AX+HGAvXgEB2zeO8xzUwIDAQABAoICAQCgw2PnrysYDp7/P3xndL0k\n" \
                                            "uqpaKQtu/2tozEWKq6KPz37oC19TYYbNaN9bedmgQnYiViIPCAplC86dpB8NYVFr\n" \
                                            "yuAN2F/EiCnIG1/jO3ryt4VT0s88Fh7P3ZUw3VMuxcG7T14sraG0XhuNDihh5gZ+\n" \
                                            "0ZHv07zoPuabU+5RfCW7EWWKbhj0R5TH6VM/EVBAkq8oeXWwiMK98fjNxguY00Cl\n" \
                                            "6x0H/+cSGvScYVORQXmlwDARnnKRZCpBl4YYCLZay/7JJ0Io8KniJ8Sch40CKCJB\n" \
                                            "J2MRuKJkAD9T17G3OD/5D7aajxoYEhnk8d7IA6lOxF9oAjIqPD5BQW6GJzURUCv4\n" \
                                            "JhnL1hYZ5/TOZ8cI8cg2DSIlCEJsijstcMlPO6s3s58xvBzUfXieqUty8Ji5DrhT\n" \
                                            "yiUBWtNWHmkoVlXZmCyUz+sHMOG1++KzUFtr4cFxM/bO8sZDsto6bnIb+L4eijMz\n" \
                                            "oplSduOE3wxV7o2Jhhf/PZeOVOWqX/YVM4RwER5MZ+zh8KGwlN+BouBP+Pk6oKRB\n" \
                                            "wKakFno2WqmX8ZpVrHDITsK56qTvgwEXnrbanO3KINbqh1+HJrojkTlm95ltLhjo\n" \
                                            "k5FfVxeofWwexGWI9EhBYnclvi+mtKGim++QokSwTeyi8EVGj1we54f66ThI7xGE\n" \
                                            "SN8sD2gfeaQl7h9QFH00AQKCAQEA/dYVUOToJ0BofgQWvCfKANC4aopcc8IKiGZs\n" \
                                            "wZUPBooTwihGugr7rHopTV8GlBgAK1sfYlt+OOG8xZR/w6DJoeMS6BLdnekbovI8\n" \
                                            "3kmfCRR/LQz+7bmAfrdxwpi5yRNOvlytYJB8LGLKFA3Ro0QNKkVvya+98O6sXxwj\n" \
                                            "30PjVNmiS9k2vPU4+TepB/MWVRW1R7Y3dLdsqPrGf7cbvPxP7UyOCWIdPYYXUY9g\n" \
                                            "PBVmeQP61JsVhfzYq3cc3iCT1wXktS+0Pj1+QV0SBiVzkKwdIoFcFxKqI84E4Tcd\n" \
                                            "khrXO/p/0R++6GcJwbCRInXNqrh1Pcnrfq3Hfr2z6vNB2+LJAQKCAQEA4U2f9ljs\n" \
                                            "e3W5rd5lV36DuyxTERHQkh20geMogzegT69VV3S+gFPqJzvkXhRhT/jSoqaaGIrF\n" \
                                            "vxK9dhzaWGfQMRox2BvG8GcnkKKse1mrL2BzN328XaXDwnSnTdS3+nobLNgXY3bK\n" \
                                            "q6/V1YQAdOjgavuzSKse6XKsuwZt8/Z6E273qrT9EQbfjJS/nVSZAHltouBTt/Tb\n" \
                                            "Y37tPlmmtmTaCYT85LHqhWHDtsOcBfpyjdalH+MYDuiVDEWcCnM992S+DfKK4q0o\n" \
                                            "PfTadzj3sg/U/FOK7UAUgrONobhmbl1sOZggKQVEHPGRDXTIt+QSHdMmuYvxL9Jt\n" \
                                            "0URMK0Eiw71IUwKCAQEAzU4teXtbpfu7SEloVhDcmqI2tr1oH5yPRlmJl11HhOOD\n" \
                                            "LaPD6M/fVVaNN24ndPqgkHCoRrZ3tewm8au1VvYif5SZAynXI9SaLMY+ow/q2L5C\n" \
                                            "Sp7bRk2md1dKZLmAcvjx1JhDBvp15LSWe3fd2m69MzZsPzWsrEVvF5I8FWXkZgmM\n" \
                                            "8koistyokzIIvkxIANOJBxKDchy1f0st57ijb8ynnOgxbbd0rQFatPYBQTeR5Ulp\n" \
                                            "xDIXS4MBgFXb/HFfAihbHo0R/NFh3942KNB700TSX8k/Qc4v3LvSSJJ6kWSyN2nZ\n" \
                                            "nbxOfcxxIL799GBR08ZT1YEOvywxUfp/ngXYe8/HAQKCAQEAvq8/InVyeK9Tnmcq\n" \
                                            "qFmITmMeTsUgHHqNqpzCTgRHZwnDFgjVrrDW7avQBRwEnHXAeC6/HuRcpvHKbmvP\n" \
                                            "FKGQX+6GnxwrTI5RuyUjDCcBLlDYUu/U/AFu5GZsrv/JUnIEC/k8Gk+RCqwAM/zL\n" \
                                            "kicCwSkUPP2vZO9MZ+HyL1e9TDNP5CfYQ4/opgfDAPp3oCIle4OW94uCHvxu+KVR\n" \
                                            "5u8GZqYqj7hQ/+CVj1qQ87JbP9aZ3JoMY5nPhBpqDaIpoPefrxhHGcBp3b4dJGiP\n" \
                                            "oyGpJoHihBgHA/PJfEUgVGo3TauGFJHDaye8l4Hu20xpVNq/3KwnTk0v6rx+JuGy\n" \
                                            "9a1+xwKCAQEAvd/zRbG/pct1lhrFQNm0crbjGN4H4wzKpHjo6F4jUr9556RGzNWU\n" \
                                            "mhPiuz2u6HKKMhsI3ktkmUiNhOvsfde/U0fl+CE4pvluAvwIQBeY82h3kRLtcw7p\n" \
                                            "xwCMXrcM9bjt41wQpO31E3bdKnR9bbO+A9UDtmOsIzfl08NtYAUkc7jgNIr7RqCE\n" \
                                            "HTUIhv6o6OEumEYhDDKVy5OMOE6mcb0GX7801LD0b0zjxI/6HMMDa9iytNU+rg8l\n" \
                                            "0jfPHTl3rMqyRN9tDY+lzQEQJnnFUG6a4FiNdutdrg0J78DHoRRUClufIcvUvpPr\n" \
                                            "5ABeDQkqJFWJyTPhLw5Io3QZaLecpXxvxA==\n" \
                                            "-----END PRIVATE KEY-----\n"
  params['ca']      ||= params[:ca]      || ""
  params['dest_ca'] ||= params[:dest_ca] || ""
  params['owner']   ||= params[:owner]   || "test_member@test.com"
  params['name']    ||= params[:name]    || rand(1_000_000_000..9_999_999_999).to_s(36)
  params['account'] ||= params[:account] || 'test'
  User.current_user = User.new(account: params['account'])
  $current_account = params['account']
  params = ActionController::Parameters.new params
  Certificate.store(params.permit('cert', 'key', 'ca', 'dest_ca', 'owner',
                                  'name'))
end
