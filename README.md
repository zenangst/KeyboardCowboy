# Keyboard Cowboy 3
[![Test](https://github.com/zenangst/KeyboardCowboy/actions/workflows/test.yml/badge.svg)](https://github.com/zenangst/KeyboardCowboy/actions/workflows/test.yml)
<img src="https://github.com/zenangst/KeyboardCowboy/blob/main/App/Resources/Assets.xcassets/AppIcon.appiconset/icon_256x256.png?raw=true" alt="Keyboard Cowboy Icon" width="20%" align="right" />

### Boost macOS productivity with Keyboard Cowboy.

Introducing Keyboard Cowboy - the ultimate productivity app for macOS that empowers users with incredible efficiency and control,
all at the tip of their fingers.

[Download Keyboard Cowboy today](https://github.com/zenangst/KeyboardCowboy/releases), and see what you can accomplish when you saddle up and take control of your Mac like a true cowboy. Experience the incredible power and efficiency of Keyboard Cowboy for yourself and take your macOS experience to the next level.

<hr/>
<div align="center">
<img src="https://github.com/zenangst/KeyboardCowboy/blob/main/gh-pages/img/app.png?raw=true" width="80%" alt="Application image" align="center" />
</div>

## Simplify complex tasks and streamline workflows for Mac users.

With Keyboard Cowboy, users can automate repetitive actions, launch applications and scripts, control system settings, manipulate files and folders, and perform a wide range of actions – all without ever having to take their hands off the keyboard.

Keyboard Cowboy's intuitive interface and simple setup process make it easy for users of all levels to get started. And with its lightning-fast performance and seamless integration with macOS, Keyboard Cowboy is the ultimate tool for power users and casual users alike.

# Feature overview

| 🧃Applications  | 🛞Automation |
| :--- | :--- |
| A single key or combination bound to open or activate an application improves workflow efficiency and saves time.  | Automating workflows by triggering them through application events, such as opening, switching, or closing an application.  |

| 🎛️ App-specific  | 📜AppleScripts |
| :--- | :--- |
| By binding groups of workflows to specific applications, you can stay focused and run workflows seamlessly, making you a multitasking master.  | Leveraging the power of AppleScripts can enhance the overall user experience of macOS, allowing you to accomplish tasks quickly and efficiently.  |

| 📁Files & Folders | ⚫️ShellScripts |
| :--- | :--- |
| By utilizing keyboard shortcuts to open files and folders, macOS users can significantly improve their productivity and save valuable time in their daily workflow.  | With keyboard shortcuts at their fingertips, programmers can unleash the power of shell scripts and turbocharge their productivity, leaving tedious tasks in the dust.  |

| ⌨️Rebinding | 💻 System commands |
| :--- |:--- |
| By rebinding keys to perform different actions or execute complex key sequences, power users can unlock a new level of efficiency and customize their workflow to fit their unique needs.  | Switch effortlessly between open application windows or invoke Exposé with a key of your choosing.  |

| 🧭Websites | 🪟Window Management |
| :--- | :--- |
| Save time and customize your browsing experience by opening websites in a browser of your choice with a single keystroke.  | Adjust the window by moving it, enlarging or reducing its size, centering it, switching to fullscreen, or transferring it to the next display. |

# The best shortcut is no shortcut at all.
<div align="center">
<img src="https://github.com/zenangst/KeyboardCowboy/blob/main/gh-pages/img/automation.png?raw=true" width="80%" alt="Automation" align="center" />
</div>

**With contextual application triggers, you can set up workflows that respond to a wide range of conditions, such as when an application is opened, closed, or when the user switches to the application.**

Once you've created your workflow, it will run automatically, without the need for any keyboard shortcuts or manual intervention. This powerful automation tool can help you save time and effort by automating a variety of tasks based on your context.

<div align="center">
<img src="https://github.com/zenangst/KeyboardCowboy/blob/main/gh-pages/img/new-command-xcode.png?raw=true" width="80%" alt="New command screenshot" align="center" />
</div>

### Using the function key to bind up commands can be incredibly useful for programmers and power users.

By assigning frequently-used commands to the function key, you can streamline your workflow and save time. Overall, utilizing function keys can help you work more efficiently and effectively, making it a valuable tool for any programmer or power user.

### Security and Privacy

Keyboard Cowboy is designed to be secure and private. It does not collect any personal information or send any data to third parties. All data is stored locally on your computer and is never transmitted over the internet.

In addition, macOS comes with built in security, so Keyboard Cowboy will be disabled when you are focsed on a password field or when you are in a secure input mode.

**tl;dr**

We don't stalk you, we don't collect your data, we don't sell your data. We don't even know who you are. But we care about your privacy and security. ❤️


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
