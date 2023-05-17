# Authenticated Requests

This package aims to make your authenticated requests easier to perform.

It has two sub-targets that helps you to perform OAuth Authentication flows and one to easily perform rest requests: 
*   [AuthenticatedRequests](#AuthenticatedRequests)
*   [CodeFlowOAuth](#CodeFlowOAuth)

## AuthenticatedRequests

Each resource is described by the `Resource` protocol, which describes all the necessary information to retrieve a REST object from a remote service.

Before requesting a resource you need to instantiate an `Authenticator` instance.
An Authenticator is an `actor` which is responsible to keep track of the authentication status for each client.

Before configuring an Authenticator, you need to know the flow used to retrieve the authentication token from the service, for this purpose you can use the `OAuthFlow` protocol, which is divided into three main implementations:

- **ARClientCredentials**: The client credentials authentication flow, where there's a
- **ARCodeFlow**: The code flow authentication flow. It supports both challenge flow or the simpler version.
- **ARRefreshToken**: The refresh token flow, for refreshing an existing code flow authentication.


If you want a customized flow, you can provide your own implementation, by conforming an object to `OAuthFlow` protocol.

### Authenticator


Configuring an Authenticator is really simple:

```swift
// Define an authentication endpoint, from which the authentication flow should be performed.
let endpoint = AuthenticationEndpoint(baseEndpoint: URL(staticString: "https://api.example.com"), path: "auth/v2/token")

// Create an authenticator instance and specify the base endpoint from which the authentication  should be performed.

let authenticator = ARAuthenticator(baseEndpoint: endpoint)

// Create an OAuthFlow that needs to be used for authenticating with the base endpoint.

let client = ARClientCredentials(clientID: "example", clientSecret: "example", scope: Set([]))
await authenticator.configure(with: client)
// We are ready to get our first Authenticated resource!
```

>If you look close, you'll see that `AuthenticationEndpoint` is a `Resource` as well!

Now that we know what a Resource is, we can also integrate an `AuthenticatedResource`, which is an extension of what a Resource is.
If you need some sort of authentication to retrieve a resource, you need to conform your `Resource` object to `AuthenticatedResource` as well.

```swift
struct UserFavoritesRequest: Resource, AuthenticatedResource { 

    // Resource
    
    typealias Input = UserProfile

    var httpMethod: HttpMethod { 
        return .get
    }
    
    func urlRequest(using parameter: Input) throws -> URLRequest {
        // Decide how you compose your URLRquest...
    }
    
    // AuthenticatedResource
    
    var authenticator: AnyAuthenticator<OAuthFlow> { 
        // .. return an authenticator
    }
    

}
```

By conforming to `AuthenticatedResource`, the SDK will automatically embed a bearer token to every request that you perform for this object (based on your `ARClientCredentials` clientID).
If you explore the `AuthenticatedResource` definition, you'll see that it only has one requirement: **Provide an Authenticator object**.

***

We are now ready to perform our first request!


```swift
let resourceRequest = UserFavoritesRequest(authenticator: authenticator)
        
let result = try await resourceRequest.request(using: userInput)
```

## CodeFlowOAuth

This package helps you to perform code-flow authentication to third party services.
It features both the standard code-flow procedure or the PKCE with the code challenge check.

To get started you need to configure an `AuthenticationConfiguration` object, which hold all the required information to perform the authentication.

If we look closer to the initializer, we see that the requirements are quite simple:

```swift
public init(baseURL: URL,
            clientId: String,
            redirectURI: String,
            scope: String,
            codeFlowConfiguration: some CodeFlowConfiguration)
```

| **Field**             | **Description**                                                                    |
|-----------------------|------------------------------------------------------------------------------------|
| baseURL               | The base url from which the authentication should be performed.                    |
| clientId              | The client id for your application.                                                |
| redirectURI           | The redirect URI that the service should use to share the authentication response. |
| scope                 | The scope that you request to access.                                              |
| codeFlowConfiguration | An object that describes the code flow procedure that needs to be used.            |

### CodeFlowConfiguration

A protocol requirement that is used to describe how the code flow procedure needs ton be performed.
The package has already two implementations of this requirement:
- **BasicCodeFlowConfiguration**:  The basic code flow procedure;
- **PKCECodeFlowConfiguration**: Which implements the PKCE flow, with the challenge code verifier.

Once you've got the AuthenticationConfiguration ready, you can feed it into the `CodeFlowManager`.

### CodeFlowManager

The code flow manager is responsible for presenting a proper webview to the user from which interact with the login frontend.
