AirplayVisualizer
=================

Test project to demonstrate sample level playback of iTunes Library music files using Audio Units for playback, and a simple visualizer using Airplay mirroring.

This project came about when I wanted a visualizer running on my TV, powered by the iPad. Since you can't get sample level data from the iTunes library using any part of MPMediaPlayer, the visualizer cannot play when the iPad lock screen engages, or from the background so this app must disable the idle timer to keep playing. Sadly, iOS doesn't provide an API to control the backlight so when the visualizer is running like this, battery consumption is high, still it will give you visuals for a few hours on a full charge.

If anyone find this useful and thinks it would be fun to develop a plugin API to integrate new visualizers I would be into maintaining that so let me know.

The organization of this project leaves something to be desired and will get cleaned up.
