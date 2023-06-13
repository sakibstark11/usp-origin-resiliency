Playing with usp origin to see if I can failover to an identical packager using docker containers and nginx load balancer.

# Setup
- export your UspLicenseKey
    ```bash
    export UspLicenseKey=<you can request unified streaming for a trial license key for 7 days>
    ```
- add `origin.test` to your `/etc/hosts` file
- run the stack
    ```bash
    docker compose up
    ```

# Playing Back
- wait a minute
- visit [shaka-player](https://shaka-player-demo.appspot.com/demo/#audiolang=en-US;textlang=en-US;uilang=en-US;asset=http://origin.test/channel/channel.isml/.m3u8;panel=CUSTOM%20CONTENT;build=uncompiled)
- make sure you enable insecure content (as we don't use `https`) for this

# Testing
- try killing `origin-1` packager from your docker dashboard. You should see no interruption in playback. You will notice that the active container id change
- try turning `origin-1` back up. You should see the opposite of step 1 happen but it will take 60s as nginx config waits for 60s before trying `origin-1`
