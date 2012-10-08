== Changes

0.3.0 - Adding oAuth2 support for the forthcoming next generation API.  This is a breaking change.  Usage of Mavenlink::Client changes from

    > client = Mavenlink::Client.new(<user_id>, '<api_token>')

to

    > client = Mavenlink::Client.new(:user_id => <user_id>, :api_token => '<api_token>')

0.2.8 - Switched from HTTParty to faraday.  Allow configuration of network library and timeout settings on client creation.
0.2.4 - Add client.create_workspace and workspace.create_invitation methods.
