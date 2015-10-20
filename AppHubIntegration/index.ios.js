/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 */
'use strict';

var React = require('react-native');
var {
  AppRegistry,
  StyleSheet,
  Text,
  View,
  Image,
  AlertIOS,
  NativeAppEventEmitter
} = React;

let AppHub = React.NativeModules.AppHub;
let AppHubExampleTests = React.NativeModules.AppHubExampleTests;

var subscription = NativeAppEventEmitter.addListener(
  'AppHub.newBuild',
  (build) => {
    AppHubExampleTests.newBuildFound(build);
  }
);

var AppHubExample = React.createClass({
  render: function() {
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>
          buildIdentifier:{AppHub.buildIdentifier}
          buildName:{AppHub.buildName}
          buildDescription:{AppHub.buildDescription}
          buildCreatedAt:{AppHub.buildCreatedAt}
          buildCompatibleIOSVersions:{AppHub.buildCompatibleIOSVersions}
        </Text>
        <Text style={styles.instructions}>
          To get started, edit index.ios.js
        </Text>
        <Text style={styles.instructions}>
          Press Cmd+R to reload,{'\n'}
          Cmd+D or shake for dev menu
        </Text>
      </View>
    );
  }
});

var styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});

AppRegistry.registerComponent('HelloWorld', () => AppHubExample);
