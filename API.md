API Documentation
-----------------

API Endpoint: **https://njal.la/api/1/**  
Requests follow the JSON-RPC 2.0 protocol.  
You can use session cookies or token based authentication.  
POST JSON body to the API Endpoint:

    {
        "jsonrpc": "2.0",
        "method": "...",
        "params": {...},
        "id": "123"
    }

and you will get a JSON response. Success:

    {
        "jsonrpc": "2.0",
        "result": {}.
        "id": "123"
    }

or error:

    {
        "jsonrpc": "2.0",
        "error": {
            "code": 0
            "message": ""
        },
        "id": "123"
    }

Example using python requests

    import requests
    
    def njalla(method, **params):
        url = 'https://njal.la/api/1/'
        token = '<your-api-token>'
        headers = {
            'Authorization': 'Njalla ' + token
        }
        response = requests.post(url, json={
            'method': method,
            'params': params
        }, headers=headers).json()
        if 'result' not in response:
            raise Exception('API Error', response)
        return response['result']
    
    
    print(njalla('list-domains'))
    print(njalla('get-domain', domain='example.com'))
    

Example using curl

    NJALLA_TOKEN='<your-api-token>'
    curl -s \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "Authorization: Njalla ${NJALLA_TOKEN}" \
        --data '{"method":"get-domain", "params": {"domain": "exampe.com"}}' \
        https://njal.la/api/1/
    

api
===

add-token

Add a new API token

    params: {
        comment: string (optional)
        from: [string] (optional)   array of IPv4 or IPv6 IPs or networks
                                    that are allowed to use the token.
                                    i.e.: ['8.8.8.8', '192.168.0.0/24']
        allowed_domains: [string] (optional) restrict token to subset of your domains
        allowed_servers: [string] (optional) restrict token to subset of your servers by id
        allowed_methods: [string] (optional) restrict token to subset of possible API calls
        allowed_prefixes: [string] (optional) restrict token to DNS record name prefixes
        allowed_types: [string] (optional) restrict token to subset of possible types of DNS records
        acme: bool (optional)       syntax sugar adding allowed_methods,
                                    allowed_prefixes and allowed_types
                                    needed for ACME DNS challenge
    }
    returns: {
    }

check-task

Check status of a long running task

    params: {
        id: string
    }
    returns: {
        id: string
        status: object
    }

edit-token

Edit API token

    params: {
        key: string
        comment: string (optional)
        from: [string] (optional) array of IPv4 or IPv6 IPs or networks
                                  that are allowed to use the token.
                                  i.e.: ['8.8.8.8', '192.168.0.0/24']
        allowed_domains: [string] (optional) restrict token to subset of your domains
        allowed_servers: [string] (optional) restrict token to subset of your servers by id
        allowed_methods: [string] (optional) restrict token to subset of possible API calls
        allowed_prefixes: [string] (optional) restrict token to DNS record name prefixes
        allowed_types: [string] (optional) restrict token to subset of possible types of DNS records
    }
    returns: {
    }

list-tokens

List existing API authorization tokens.

    params: {
    }
    returns: {
        tokens: [...]
    }

remove-token

Remove an existing API token

    params: {
        key: string
    }
    returns: {
    }

domain
======

add-dnssec

Add DNSSEC record for domain

    params: {
        domain: string
        algorithm: integer
    
        digest: string
        digest_type: integer
        key_tag: integer
    
        or
    
        public_key: string
    }
    returns: {
    }

add-forward

Add email forward

    params: {
        domain: string
        from: string
        to: string
    }
    returns: {
        domain: string
        from: string
        to: string
    }

add-glue

Add glue record for the domain, name is the subdomain

    params: {
        domain: string
        name: string
        address4: string
        address6: string
    }
    returns: {
    }

add-record

Add new DNS Record to domain

    params: {
        domain:         string
        type:           string  (types: A, AAAA, ANAME, CAA, CNAME, DS, Dynamic, HTTPS, MX, NAPTR, NS, PTR, SRV, SSHFP, SVCB, TLSA, TXT)
        name:           string  (all types)
        content:        string  (types: A, AAAA, ANAME, CAA, CNAME, DS, MX, NAPTR, NS, PTR, Redirect, SRV, SSHFP, Static, TLSA, TXT)
        ttl:            int     (types: A, AAAA, ANAME, CAA, CNAME, DS, MX, NAPTR, NS, PTR, Redirect, SRV, SSHFP, TLSA, TXT)
        prio:           int     (types: HTTPS, MX, Redirect, SRV, SVCB)
        weight:         int     (types: SRV)
        port:           int     (types: SRV)
        target:         string  (types: HTTPS, SVCB)
        ssh_algorithm:  int     (types: SSHFP, values: 1-5 // RSA, DSA, ECDSA, Ed25519, XMSS)
        ssh_type:       int     (types: SSHFP, values: 1-2 // SHA-1, SHA-256)
    }
    returns: {
        id:             string
        domain:         string
        type:           string  (types: A, AAAA, ANAME, CAA, CNAME, DS, Dynamic, HTTPS, MX, NAPTR, NS, PTR, SRV, SSHFP, SVCB, TLSA, TXT)
        name:           string  (all types)
        content:        string  (types: A, AAAA, ANAME, CAA, CNAME, DS, MX, NAPTR, NS, PTR, Redirect, SRV, SSHFP, Static, TLSA, TXT)
        ttl:            int     (types: A, AAAA, ANAME, CAA, CNAME, DS, MX, NAPTR, NS, PTR, Redirect, SRV, SSHFP, TLSA, TXT)
        prio:           int     (types: HTTPS, MX, Redirect, SRV, SVCB)
        weight:         int     (types: SRV)
        port:           int     (types: SRV)
        target:         string  (types: HTTPS, SVCB)
        ssh_algorithm:  int     (types: SSHFP, values: 1-5 // RSA, DSA, ECDSA, Ed25519, XMSS)
        ssh_type:       int     (types: SSHFP, values: 1-2 // SHA-1, SHA-256)
    }

edit-domain

Edit domain configuration

    params: {
        domain: string
        ...
    }
    possible keys:
        mailforwarding: boolean
        dnssec: boolean
        lock: boolean
        contacts: custom whois contact ids
        nameservers: list of custom nameservers or empty list to use our nameservers
    
    returns: {
        name: string,
        ...
    }

edit-glue

Edit glue record

    params: {
        domain: string
        name: string
        address4: string
        address6: string
    }
    returns: {
    }

edit-record

Edit DNS Record

    params: {
        id:             string
        domain:         string
        type:           string  (types: A, AAAA, ANAME, CAA, CNAME, DS, Dynamic, HTTPS, MX, NAPTR, NS, PTR, SRV, SSHFP, SVCB, TLSA, TXT)
        name:           string  (all types)
        content:        string  (types: A, AAAA, ANAME, CAA, CNAME, DS, MX, NAPTR, NS, PTR, Redirect, SRV, SSHFP, Static, TLSA, TXT)
        ttl:            int     (types: A, AAAA, ANAME, CAA, CNAME, DS, MX, NAPTR, NS, PTR, Redirect, SRV, SSHFP, TLSA, TXT)
        prio:           int     (types: HTTPS, MX, Redirect, SRV, SVCB)
        weight:         int     (types: SRV)
        port:           int     (types: SRV)
        target:         string  (types: HTTPS, SVCB)
        ssh_algorithm:  int     (types: SSHFP, values: 1-5 // RSA, DSA, ECDSA, Ed25519, XMSS)
        ssh_type:       int     (types: SSHFP, values: 1-2 // SHA-1, SHA-256)
    }
    returns: {
        domain:         string
        type:           string  (types: A, AAAA, ANAME, CAA, CNAME, DS, Dynamic, HTTPS, MX, NAPTR, NS, PTR, SRV, SSHFP, SVCB, TLSA, TXT)
        name:           string  (all types)
        content:        string  (types: A, AAAA, ANAME, CAA, CNAME, DS, MX, NAPTR, NS, PTR, Redirect, SRV, SSHFP, Static, TLSA, TXT)
        ttl:            int     (types: A, AAAA, ANAME, CAA, CNAME, DS, MX, NAPTR, NS, PTR, Redirect, SRV, SSHFP, TLSA, TXT)
        prio:           int     (types: HTTPS, MX, Redirect, SRV, SVCB)
        weight:         int     (types: SRV)
        port:           int     (types: SRV)
        target:         string  (types: HTTPS, SVCB)
        ssh_algorithm:  int     (types: SSHFP, values: 1-5 // RSA, DSA, ECDSA, Ed25519, XMSS)
        ssh_type:       int     (types: SSHFP, values: 1-2 // SHA-1, SHA-256)
    }

find-domains

Find new domains

    params: {
        query: string
    }
    returns: {
        domains: [
            {price: int, status: string, name: string}
        ]
    }

get-domain

Get information about one of your domains

    params: {
        domain: string
    }
    returns: {
        name: string,
        ...
    }

get-tlds

Get list of supported TLDs

    params: {
    }
    returns: {
        tld: {price: int, max_year: int, dnssec: boolean},
    }

import-zone

Import BIND zone file

    params: {
        domain: string
        zone: string
    }
    returns: {
    }

list-dnssec

List DNSSEC records for domain

    params: {
        domain: string
    }
    returns: {
        dnssec: list
    }

list-domains

Get list of your domains

    params: {
    }
    returns: {
        domains: list
    }

list-forwards

List existing email forwards

    params: {
        domain: string
    }
    returns: {
        forwards: list
    }

list-glue

List glue records for domain

    params: {
        domain: string
    }
    returns: {
        glue: list
    }

list-records

List DNS records for given domain

    params: {
        domain: string
    }
    returns: {
        records: list
    }

register-domain

Register a new domain

    params: {
        domain: string
        years: int (default: 1)
    }
    returns: {
        task: string
    }
    use check-task for response

remove-dnssec

Remove DNSSEC record from domain

    params: {
        domain: string
        id: string
    }
    returns: {
    }

remove-forward

Remove email forward

    params: {
        domain: string
        from: string
        to: string
    }
    returns: {
    }

remove-glue

Remove glue record

    params: {
        domain: string
        name: string
    }
    returns: {
    }

remove-record

Remove DNS Record

    params: {
        domain: string
        id: string
        name: string // optional
        type: string // optional
        ...          // optional
    }
    
    remove a dns record by id
    or multiple records by passing name, type and any other existing record's field
    
    returns: {
        records: list
    }

renew-domain

Renew one of your domains

    params: {
        domain: string
        years: int (default: 1)
    }
    returns: {
        task: string
    }
    use check-task for response

server
======

add-server

Create a new server with the given name, type, os and ssh\_key. Returns an id of the newly created server

    params: {
        name: string,
        type: string
        os: string
        ssh_key: string
        months: int (max 12)
        autorenew: bool
    }
    returns: {
        id: string
        ...
    }

add-traffic

Add extra traffic package.

    params: {
        id: string
        amount: int
        months: int
        starts_today: bool
    }
    returns: {
    ...
    }

edit-server

Edit an existing server identified by id

    params: {
        id: string
        name: string,
        type: string
        ssh_key: string
        reverse_name: string
        autorenew: bool
    }
    returns: {
        ...
    }

get-server

Returns information about one of your servers

    params: {
        id: string
    }
    returns: {
        ...
    }

list-server-images

Returns a list of server images that can be used for new servers

    params: {
    }
    returns: {
        images: list
    }

list-server-types

Returns a list of server types that can be used for new servers

    params: {
    }
    returns: {
        types: list
    }

list-servers

Returns a list of your servers

    params: {
    }
    returns: {
        servers: list
    }

list-traffic

List extra traffic packages per server.

    params: {
        id: string # server id
    }
    returns: {
      traffic: []
    }

remove-server

Remote an existing server, your server will be stopped and all data deleted.

    params: {
        id: string
    }
    returns: {
        task: string
    }

renew-server

Renew an existing server identified by id, your wallet must have enough credit to complete this operation.

    params: {
        id: string
        months: int
    }
    returns: {
        ...
    }

reset-server

Reset existing server and reinstall the given os. All data will be lost. Required field: \`id\`

    params: {
        id: string
        os: string
        ssh_key: string
        type: string
    }
    returns: {
        ...
    }

restart-server

Restart existing server

    params: {
        id: string
    }
    returns: {
        ...
    }

start-server

Start existing server

    params: {
        id: string
    }
    returns: {
        ...
    }

stop-server

Stop existing server

    params: {
        id: string
    }
    returns: {
        ...
    }

user
====

delete-account

Delete your account. You can only delete the account if all domains and servers have been removed and your wallet is empty.

    params: {
    }
    returns: {
    }

login

Login into an existing account (cookie based session). Consider using API tokens instead

    params: {
        email: string [or] xmpp: string
        password: string
    }
    returns: {
    }

logout

Logout and end your current session

    params: {
    }
    returns: {
    }

vpn
===

add-vpn

Add a new VPN client Returns an id

    params: {
        name: string,
        autorenew: boolean
    }
    returns: {
        id: string
        ...
    }

edit-vpn

Edit an existing VPN identified by id

    params: {
        id: string
        name: string,
        autorenew: boolean
        backend: wireguard|openvpn
        publickey: WireGuard PublicKey, set to your public key or null to generate a new one
    }
    returns: {
        ...
    }

get-vpn

Returns information about VPN

    params: {
        id: string
    }
    returns: {
        ...
    }

list-vpns

Returns a list of your VPNs

    params: {
    }
    returns: {
        vpns: list
    }

remove-vpn

Remove an existing VPN

    params: {
        id: string
    }
    returns: {
        ...
    }

renew-vpn

Renew an existing VPN identified by id, your wallet must have enough credit to complete this operation.

    params: {
        id: string
        months: int
    }
    returns: {
        ...
    }

wallet
======

add-payment

Refill your wallet

    params: {
        amount: int (5 or multiple of 15, max: 300)
        via: string (options: paypal, bitcoin, litecoin, monero, zcash, ethereum)
    }
    returns: {
        amount: int
        address: string (payment address)
        url: string (paypal url to process payment)
    }

get-balance

    params: {
    }
    returns: {
        balance: int (in euros)
    }

get-payment

Get details about a payment

    params: {
        id: string
    }
    returns: {
        id: string
        amount: int
        status: string
        address: string
        url: string
    }

list-transactions

List transactions (payments, registrations, renewals, etc..) of the last 90 days

    params: {
    }
    returns: {
        transactions: list
    }
