# MistKit

Hello, and welcome to my presentation today, CloudKit as your backend from iOS to server side. I am really excited to be with you today and to talk about this project

## What is CloudKit?

So let's first talk about what actually is CloudKit. So let's travel back in time to an ancient era of ice bucket ch- challenges and Luigi's cold stare. Let's travel all the way back to 2014. WWDC 2014 to be exact

This was the year of introducing Swift and also some partners that didn't stay so friendly anymore

and the introduction of CloudKit. 

The idea is a simple and easy way for iOS developers to write a backend

## Some basics about CloudKit

so let's explain how CloudKit works. So let's talk about how to set it up. The easiest way to do this is within Xcode. You just go in and you

Check the box under CloudKit and add your container right there. Another piece for helping you set up the CloudKit, your CloudKit setup is the CloudKit console, which contains a really nice interface for creating new record types within your CloudKit container. Records are the main way data is stored.

### Records

Consider them like a table row. You have the ability to do strings, ints, doubles, bytes, data, location, references, assets and lists. You can even... If you don't want use the console, I didn't know if you know this but there's actually a schema set up where you can run a command that Apple provides where you can create records like SQL, which is really cool

And then this is what a typical record would look like in console kit, in CloudKit console. So then next, let's talk about databases. There is typically two databases in a container. You have your private database and your public database 

### Databases

The private database is for the user. So every user has their own individual database

Public database is shared by everybody within your app

### Authenticaion

To access these, there's three different kinds of authentication methods outside of your iOS app

#### API Token

You can go ahead and create what's called an I- API token

With the API token, you can give it a name And you can specify a sign-in callback method, what domains, whether user discoverability is available or needed

There's not a lot you can do with the API token. What-- But what it is it's your way of then being able to

So now that you have the API token

#### Web Token

You go ahead and use that with CloudKit JS

In JavaScript, you would, if you're gonna do the there's two ways of doing it. You can either wait for the message within the window, or you can use a callback

What this will do is save the information in a token, or excuse me, in the cookie.

##### CKFetchWebAuthTokenOperation

If you're an iOS developer and you want to have access to the user's, to the WebAuthToken, you could do that through the CK fetchWebAuthToken operation. All you need is that API token, and then you just run that operation within CloudKit Here's an example of a way to fetch the WebAuthn token using an async method

#### Server to Server

the other way you can authenticate outside of an Apple device is the server-to-server token To that, you have to give it a name, and you paste the public key within this dialog.

If you don't know how to go ahead and create a private key you could just go ahead and run the command

You then go ahead and once you've generated that key, you wanna go ahead and paste the public key in step three and save it

And that will allow you to have access it's the easiest way to do access as far as from a server

#### Compare Capabilities

As far as the differences in access for a on different authentication methods and different databases, so you have- Access to search and pull a-- You have access to queries, record queries and record identification

And 

You have access to zones as well except you can't do zones and you can't do tracking changes on a public databases. And

You also, you do have the ability to zone notifications, and you could also do query native notifications on private and public but not shared. And then assets are available on all three database types

As far as the access API key doesn't really give you access to anything

## Introduction

So today we'll be talking about what is CloudKit Web Services, what are some use cases for CloudKit, server-side CloudKit, how s- server-side CloudKit has been built and how it works How I coded CloudKit web services, converting documentation to documentation

And ch- specific challenges I ran into with Swift

Lastly, we'll talk about what's next.

## What is CloudKit Web Services?

So what is CloudKit's web services? Part of the introduction to CloudKit was allowing access to it on the web. And

There are really two main ways of doing it. There's one main way of doing it and that's by just using their Rust API. But if you want something that's just built for JavaScript right out of the box, there is the CloudKit JavaScript library that you can import as well. If you go with the service requests you can pull up the documentation on how to do this, but essentially there's ab- there's each way it involves a different authentication path and a different access

## Why Server Side Cloud

So you might be wondering why would anybody wanna do this?

### Private Database

Let me take you back to about 2019, 2018 with HeartTwitch. HeartTwitch was an app I had built about five or six years ago that uses Swift both on the server side and on the client side as well. And this was before the days of Sign in with Apple. The way it works is it'll post your heart rate to a server, and then on the other end, your web browser will open a WebSocket and listen for the heart rate.

And then that way, it can go ahead and point OBS or some sort of streaming software to that URL or to the browser window, and then that would get shared on a live stream So the issue is I really don't wanna make users have to log in on their Apple Watch. It's an awful experience, and of course, I didn't have Sign In with Apple at the time.

With my server backend, I was using Postgres, and I needed a... The easiest way I could have a user sign in was just by using their CloudKit account. So if there's a way I can the server side can know that a client Kit u- CloudKit user is the same person as somebody stored with a username and password

The way this would work on the web interface is that once you log in, you would go ahead and tap a button that would lo-log you into CloudKit using the CloudKit JS interface. And then I would have access to a WebAuthn token that I can then save in my Postgres database. And I can also add that Apple Watch information so that way it'll know anything that comes from that Apple Watch is linked to you, and then it will stream that data appropriately

### Public Database

The one reason I'm more recently looking at using Serverless CloudKit is for a public database. so for Bushel I-- Bushel is my macOS VM virtualization app for developers. And w-what, if a person's gonna use Bushel, then we need a way for them to download different versions of macOS. So The way I'm doing this now is I have this concept of a hub where you can put in a URL to some sort of list of, or feed of macOS images, and then it will automatically pull that list and allow you to download from there.

What's became pretty evident to me is that they're all just basically Apple URLs obviously. And if I could somehow get that data and go through the web, go through a few websites, pull that data, store it in CloudKit in a public database, I'll then have access to that in Bushel So that's kind of the reason why I went ahead and built Miskit.

So here's an example of how Miskit works. This is the demo, web demo interface where you can go ahead and

Do queries via Miskit, a backend server that you're running using Hummingbird. Or if you want to, you could switch to CloudKit. You can see you got querying, you've got the ability to add new notes. There's a lot more to this actually now if you look at it now. But this is the basic idea. You can switch between a public and private database

## Building MistKit

So how am I gonna do this? When I first started so there's documentation available. Scary enough, the last time it was updated was more than 10 years ago, so not super great. That's my reaction looking at the documentation and it became really painful. I only implemented what I absolutely needed. I didn't implement anything that I wasn't gonna use in HeartTwitch at the time. But then lo and behold, we got this new library that come out from Apple called thing OpenAPI Swift OpenAPI generator and a series of libraries to use it in, to use it either on the server or on the client using a standard URL session.

### OpenAPI Generator

The Swift OpenAPI generator, that is actually really well documented, and it even includes some DocC tutorials on how to do stuff.

#### Introduce openapi.yaml

The challenge then became is how can I take the documentation and create an open API document out of it?

### Using AI to create an openapi.yaml

If only there was something that would come out that would revolutionize the way we do software development and just automatically create this OpenAPI document for me. And yes, that was one of my first ideas when I could see the things that AI can do. So here is the OpenAPI document that I've generated using the help of various AI tools. I will say it's not automatic by any means. We basically had to test it, run it, see if it works okay, do it again and again until we were able to get it to have the complete API set up. And there were really two main challenges on how to do this.

## Authentication

And the first biggest one the biggest one was authentication. So how am I gonna integrate authentication with the OpenAPI libraries? And this is where o- the OpenAPI middleware comes in. This is all part of the Swift library. And they have an idea of server middleware, where you can catch requests and change them before they get thrown to the correct function, or you can do something like client middleware, which is the same idea

### Using OpenAPI Middleware 

And that allows me to, before it actually does the request on the network, it allows me to modify things like the URL, the headers, et cetera, things like that. So here's an example of an intercept method that air- adds, for instance, a bearer token for authentication using bearer tokens So this is what I end up doing is I, I created what's called a token manager and, and what's called an authenticator, and depending on what authentication method you're using, it will then modify the request or the body as needed

So here's a fun little diagram just to show you how that would work. So when you make a call to create a record, it then goes to the OpenAPI cl- client, which then calls the intercept method, and then that goes ahead and it create... gets the authenticator. And once it gets the authenticator, it calls authenticate, which modifies the request in the body, and then it

Then goes ahead and once it modifies that, it uses that to make the request and the response

#### API Token

So our first authenticate authentication method is the API token. How would we do that? Assuming that you have the API token in the API token authenticator, it will then go ahead and just append the query item for the CK API token, which is...

That's it. That's pretty easy.

#### Web Token

For web authentication, I needed, that, what that has to do is it has to encode the WebAuth token that you pass to it. And it does like a URL encoding for a lot of the pieces within the in the string. It then attaches that to the request, and that's how you can then give a user access to their private database. So here you go.

That's an example of that

#### Server to Server

Then we have server-to-server, which uses a private and public key. So we showed how to do that in the previously So in the server-server authentication, we need the private key, and we call... We create what's called a request signature, and then that is added to the header. So

We grab the body, we then take the body and we create the signature from the the private key, the body and

other pieces, and then that goes ahead and

That creates a body hash and a web services. We pass in the web service subpath and the ISO 861 date string, and it will use that to then create the headers that are then passed

Here is a screenshot of what Apple shows. Oops

So here's the three headers you need to pass when you do any sort of private or server-to-server authentication.

## Field Types

Next there's the challenge of field type polymorphism. There... So CK value, or basically the value is given to you. There's what we had said earlier about the different types available.

And so what I ended up using for that is, of course, an enum and

So here's what we had shown earlier about what's avail- what data type you have either from Objective-C or from Swift

And in my library I created my own version of location, asset, and reference. 

And then I have my own custom reference type and asset type. Essentially the reference is a enum of what's called action and the record name. So you have that And then the asset is basically a URL for downloading an asset when you make a query

In the OpenAPI document, this is what it ends up looking like

## Error Handling

And then lastly, let's talk about how error handling is done. So luckily we have all the error codes available to us in the documentation. And those can get mapped out into the open A... This is what it looks like when you have a failure. You get this URL with all the information attached to it. So then in the OpenAPI document, we just need the UUID.

We have the UR- UID, and then we have an enum for the server error code

And then this is what the error response and the server error code look like.

### NEW ERRORS

Unfortunately, there are instances where I received a f- now there was one call where I received a 500 error, and that's in discover user i- user identities. This is not documented anywhere, but this method doesn't even exist.

Or it does exist, but it gives you a 500 error, and like nobody at CloudKit knew about this or had kept track of it surprisingly

And so I ended up having to file a feedback for it.

## Deployment

So then let's talk about how we would deploy something like this. And let's specifically talk about how you do this, like in GitHub for instance. Let's say a GitHub Action. So you could either do like the private key, just paste it in or you could do a Base64 encoded version of the private key.

And then here's an example of me using kind of a cron job to update, sync to CloudKit for th- the new images that are coming out every so often And then I created my own separate action for that. And then what we do is I'm downloading the binary that I create that's based around Miskt

And then once I have that executable, I just run it and I pass in my secrets, which We're over here

And then it runs my Swift command to then update the CloudKit database. So what's next?

Basically at this point, not a lot

Most of these, as of today every API has been fully implemented in Mi- MiscKit. You can try it out. Notifications sharing, all that stuff should be working now. And what I could use from you is just testing, trying this, seeing if you can find various features you'd like me to add or bugs throughout the process.

Thank you so much, and I'm glad you joined me for today's presentation
