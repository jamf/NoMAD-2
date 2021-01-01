#  NoMAD 2

A complete ground-up rewrite of NoMAD utilizing the same AD Auth Framework foundin NoMAD Login.

## Why?

Well... that's a good question. 

NoMAD 1.x hasn't seen a lot of updates in the last few years. A lot of this is because Active Directory itself hasn't changed much. Also, with the introduction of Apple's improved Kerberos SSO Extension there was a hope that NoMAD's time had perhaps passed.

However, after watching the number of people in #nomad Slack channel increase and continued usage of the product, it started becomming more clear that the time had perhaps come to do a major rework of the code base to allow for modernization.

While many organziations won't get much use out of the new features, everyone should be able to benefit from a much improved code base which should finally put to bed some long suffering NoMAD "features" like not checking for tickets on first launch.

Even with Apple's included Kerberos apps, there's still a significant need to allow for customization of the user experience. Either through allowing the use of logos and custom titles for menu, or full on customization of the application's behavior. NoMAD 2 provides this.

Plus for anyone looking to learn Swift and how it might help with administration tasks, this code will be much less infuriating to try and decipher and perhaps reuse in your own projects.

## What's New

Most of NoMAD 2 is focused on code cleanup and modernization with a particular focus on ensuring lingering threading and other issues are properly addressed. However there are some new features that you'll find in NoMAD 2.

- Support for Single Sign On Extensions. NoMAD 2 has a full Credential SSOE.
- Lights Out Operation where the NoMAD menu bar item is not visible.  The background operations still occur and users will get notified when they need to react. This also includes an "Actions Only" mode where the only elements in the menu bar are the Actions menu.
- Multi-account support. You can have an unlimited number of accounts from any AD domain you'd like listed in NoMAD 2. Accounts can all have saved passwords and be enabled for automatic sign in for each account.
- PAM module to support authentication to AD, without binding, for administration purposes.

## Single Sign On Extension

NoMAD 2 provides a Credential SSOE for macOS 10.15 and above. This means that if you attempt to load a webpage that requires Kerberos authentication, and you have the proper configuration profile in place, but you don't have a ticket for the realm you are connecting to, you'll see the NoMAD 2 authentication window.

To achieve this you'll need to push a configuration profile via MDM with two items configured:

- `menu.nomad.nomad.nomadssoe` for the Extension bundle ID
- `VRPY9KHGX6` as the Team Identifier

You can find a sample version of the profile in the NoMAD repo.

And then install a signed copy of NoMAD 2.

## Building NoMAD 2

NoMAD 2 is fairly straightforward to build in recent versions of Xcode as long as you ensure to build the AD Framework first. The existing code base uses Carthage to do this, so once you have Carthage installed a simple `carthage update` in the project folder should do the necessary.

The AD Framework requires some ObjC code which prevents it from being a Swift Package, or else this would be even easier.

## What's the current progress

At this point NoMAD 2 would be best characterized as an early beta. AD auth and getting the user record works. The SSOE is working. Accounts and passwords can be saved and used. Much of the previous NoMAD preference keys for customizing the menu also work.

### Jan 1, 2021

- SSOE working
- Release to the world!

### Dec. 27, 2020

- New Code base using NoMAD AD Auth Framework
- Support for multiple accounts
- Support for lights out operation
    set `LightsOutIKnowWhatImDoing` to true
- Support for actions only menu
    set `ActionItemOnly` to true
