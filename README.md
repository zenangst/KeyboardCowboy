# Keyboard Cowboy 3

<img src="https://github.com/zenangst/KeyboardCowboy/blob/main/App/Resources/Assets.xcassets/AppIcon.appiconset/icon_256x256.png?raw=true" alt="Keyboard Cowboy Icon" align="right" />

### Simplify complex tasks and streamline workflows for Mac users.
With Keyboard Cowboy, users can automate repetitive actions, launch applications and scripts, control system settings, manipulate files and folders, and perform a wide range of actions – all without ever having to take their hands off the keyboard.

Keyboard Cowboy's intuitive interface and simple setup process make it easy for users of all levels to get started. And with its lightning-fast performance and seamless integration with macOS, Keyboard Cowboy is the ultimate tool for power users and casual users alike.

### The best shortcut is no shortcut at all.

**With contextual application triggers, you can set up workflows that respond to a wide range of conditions, such as when an application is opened, closed, or when the user switches to the application.**

Once you've created your workflow, it will run automatically, without the need for any keyboard shortcuts or manual intervention. This powerful automation tool can help you save time and effort by automating a variety of tasks based on your context.

## Development

To get this up and running, you'll need to have `tuist` installed.

#### Installing tuist 

The easiest way to install tuist is by using Homebew

```fish
brew install tuist 
```

For more information about [tuist](https://tuist.io), refer to the projects README.

#### Setting up a `.env`

Create a new `.env` file in the root folder.
Add the following contents to the `.env`-file.

```
APP_NAME=Keyboard Cowboy
APP_SCHEME=Keyboard-Cowboy
APP_BUNDLE_IDENTIFIER=com.zenangst.Keyboard-Cowboy
TEAM_ID=XXXXXXXXXX
```

#### Generating an Xcode project

Simply run the following commands in the root folder of the repository

```fish
tuist fetch
tuist generate
```
