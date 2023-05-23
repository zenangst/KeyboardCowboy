# Keyboard Cowboy 3

## Installation

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
