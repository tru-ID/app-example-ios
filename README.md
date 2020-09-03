# phone-check-ios-example

## Quick Notes

- Requires the [4Auth Node Server](https://gitlab.com/4auth/devx/4auth-node-server) to be running
- 4Auth Node Server needs to have a public URL. Use something like [Ngrok](https://ngrok.com/)

## Implementation Notes

- 4Auth Node Server url should be set in `Build Settings -> User-Defined : MY_APP_SERVER_URL`
- App to Server communications is located in `APIManager.swift`
- `check_url` handler is located in `RedirectManager.swift`
- UI logic is located in `ViewController.swift`


