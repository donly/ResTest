# Integrating CarPlay with Your Navigation App

Configure your navigation app to work in CarPlay.

## Overview

Coastal Roads is a sample navigation app that demonstrates how to display a custom map and navigation instructions from a CarPlay–enabled vehicle. Coastal Roads integrates with the CarPlay framework by implementing the map and additional `CPTemplate` subclasses, such as [`CPGridTemplate`](https://developer.apple.com/documentation/carplay/cpgridtemplate) and [`CPListTemplate`](https://developer.apple.com/documentation/carplay/cplisttemplate). This sample's iOS app component provides a logging interface to help you understand the life cycle of a CarPlay app.

## Configure the Sample Code Project

CarPlay navigation apps require a CarPlay navigation entitlement. For more information, see [Adding CarPlay Support to Your Navigation App
](https://developer.apple.com/documentation/carplay/adding_carplay_support_to_your_navigation_app). (Alternatively, you can request the entitlement [here](https://developer.apple.com/contact/carplay/)). Once the entitlement is granted:

1. Log in to your account on the Apple Developer website and create a new provisioning profile that includes the CarPlay navigation app entitlement.

2. Import the newly created provisioning profile into Xcode.

3. Create an `Entitlements.plist` file in your project, if you don't have one already. 

4. Create a key for the CarPlay navigation app entitlement as a Boolean. Make sure that your target project setting `CODE_SIGN_ENTITLEMENTS` is set to the path of your `Entitlements.plist` file. 

For more information about configuring projects for CarPlay, see [adding CarPlay support to your navigation app](https://developer.apple.com/documentation/carplay/adding_carplay_support_to_your_navigation_app?language=objc).

## Handle Communication with CarPlay

Implement the following methods on `CPApplicationDelegate` to handle tasks during various points in the app's life cycle:

* [`func application(UIApplication, didConnectCarInterfaceController: CPInterfaceController, to: CPWindow)`](https://developer.apple.com/documentation/carplay/cpapplicationdelegate/2968287-application)  
* [`func application(UIApplication, didDisconnectCarInterfaceController: CPInterfaceController, from: CPWindow)`](https://developer.apple.com/documentation/carplay/cpapplicationdelegate/2968288-application)

You're also responsible for adding and removing the root view controller of your CarPlay window in response to connections and disconnections.  

The following code shows an example implementation of setting a root template:

``` swift
let mapTemplate = CPMapTemplate.coastalRoadsMapTemplate(compatibleWith: mapViewController.traitCollection, zoomInAction: {
    MemoryLogger.shared.appendEvent("Map zoom in.")
    self.mapViewController.zoomIn()
}, zoomOutAction: {
    MemoryLogger.shared.appendEvent("Map zoom out.")
    self.mapViewController.zoomOut()
})

mapTemplate.mapDelegate = self

baseMapTemplate = mapTemplate

installBarButtons()

interfaceController.setRootTemplate(mapTemplate, animated: true)
```
[View in Source](x-source-tag://did_connect)

## Render a Map as Your Base Template

The sample includes an image to serve as the map. In your app, you'll use your own map or image to serve as the base template. The base template must be an instance of `CPMapTemplate` with no additional graphics or UI elements. All overlays should be of a template type that is provided by CarPlay. Your map template can use trait collections to handle size classes programmatically. Your map must cover the entire screen, which you can accomplish by using constraints.
