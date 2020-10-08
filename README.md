# Advanced Hello World in Zig
Become and EXTREME Zig programmer!


## Abstract
This is the code demoed during the "Advanced Hello World in Zig" talk I gave on [Zig SHOWTIME](https://zig.show).

This demo shows how to extend `std.log` and even implement a custom panic handler to log messages on Twitch and Discord. I don't really recommend to use it in production, but it's a funny example of what can be done with `std.log`.

If you want to run the code locally, there's some work you need to do:
1. Create a Discord bot, invite it into a server and give it appropriate persmissions.
2. Grab a Discord token for the bot from the dev control panel and export it as an environment variable (or edit the corresponding line in `main.zig`). 
3. Change the Discord channel ID in `main.zig` to the ID of a channel in your server (enable developer mode in Discord to be able to copy the channel ID easily by right-clicking on it).
4. Use https://twitchapps.com/tmi/ to get a twitch oauth token for your Twitch channel
5. Change the Twitch channel name in `main.zig`, set the oauth token as an env variable or change the corresponding line in the source code.
6. Congratulations, now everytime you log something, it also gets sent to both Discord and Twitch!

Uncomment the panic handler to send to Twitch panic messages.