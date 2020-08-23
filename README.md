# phone-check-ios-example

## Quick Notes

- Requires the [4Auth Node Server](https://gitlab.com/4auth/devx/4auth-node-server) to be running
- 4Auth Node Server needs to have a public URL. Use something like [Ngrok](https://ngrok.com/)
- The URL to the [4Auth Node Server](https://gitlab.com/4auth/devx/4auth-node-server) will need to be updated within the code (should be moved to config). Search for `LOCAL_ENDPOINT`.

## Implementation Notes

- 4Auth Node Server url should be set in `Build Settings -> User-Defined : MY_APP_SERVER_URL`
- App to Server communications is located in `APIManager.swift`
- UI logic is located in `ViewController.swift`
- `check_url` handling is using Boku legacy Objective-C library `NetworkingLogic` via the `Sample-Bridging-Header.h` 

## TODO

- [ ] Remove Boku lib dependency

