# Authenticated Requests

This package aims to make your authenticated requests easier to perform.
Each resource is described by the `Resource` protocol, which describes all the necessary information to retrieve a REST object from your backend.

Before requesting a resource you need to instantiate an `Authenticator` instance.
An Authenticator is an `actor` which is responsible to keep track of the authentication status for each client.

Configuring an Authenticator is really simple:

```swift
let endpoint = AuthenticationEndpoint(baseEndpoint: URL(staticString: "https://api.example.com"), path: "auth/v2/token")
let authenticator = ARAuthenticator(baseEndpoint: endpoint)
let client = ARClientCredentials(clientID: "esempio", clientSecret: "esempio", scope: Set([]))
await authenticator.configure(with: client)
// We are ready to get our first Authenticated resource!
```

>If you look close, you'll see that `AuthenticationEndpoint` is a `Resource` as well!

Now that we know what a Resource is, we can also integrate an `AuthenticatedResource`, which is an extension of what a Resource is.
If you need some sort of authentication to retrieve a resource, you need to conform your `Resource` object to `AuthenticatedResource` as well.

```swift
struct UserFavorites: Resource, AuthenticatedResource { 

    // Resource

    var httpMethod: HttpMethod { get }
    
    func urlRequest(using parameter: Input) throws -> URLRequest {
    
    }
    
    // AuthenticatedResource
    
    var authenticator: AnyAuthenticator<ARClientCredentials> { 
    
    }
    
    func configure(with credentials: ARClientCredentials) async {
    
    }

}
```

By conforming to `AuthenticatedResource`, the SDK will automatically embed a bearer token to every request that you perform for this object.
If you explore the `AuthenticatedResource` definition, you'll see that it only has a single requirement: to provide some sort of Authenticator into your object.

