egory
=====
Video-editing preprocessing tool.

This tool sits on top of [VLC Media Player](http://videolan.org/vlc) and [FFmpeg](http://ffmpeg.org) and allows cutting videos easily into various clips and annotating them with tags. Additionally customizable filters can be applied on the video clips.
The tags may be sorted into different categories (which corresponds to different file directories), hence the name ~~cat~~ **egory**. This tool is for Windows only.

**egory** is very useful for video editing, since long videos can already be preprocessed into smaller chunks before adding them to video editing software. Other benefits are:

- Reduction of file size before importing video files into video-editing software
- Cutting away massive amounts of unnecessary video material beforehand
- Grouping similiar video-parts by using tags (also useful for making video montages of similar events)
- Omission of video-editing software all-together for simple video-splitting/-cutting

Before cutting the video a preview is available. After satisfying results are found and stored to disk the processed video file can be archived or deleted and **egory** automatically advances to the next file provided there is one in the VLC playlist.

![egory preview](http://i.imgur.com/Xu5Feql.png)

Installation
------------

A production build setup for **egory** is already available for [download](bin/build). The installation is very simple.

![setup preview](http://i.imgur.com/h2gx0sk.png)

Tags, Categories and Filters
----------------------------

Filters as well as tags for each category are stored in a file named `tags.ini` in the windows user appdata.

- **Tags** can easily be added through **egory's** UI.
- **Categories** appear in **egory** as soon as the respective directory is created in the category directory.
- **Filters** need to be manually added directy to the `tags.ini`.

**Filters** consist of a `name` and an FFmpeg `filtergraph`, additionally they can be set to be applied by `default` (increases processing time). For help consult the [FFmpeg documentation on filtergraphs](https://www.ffmpeg.org/ffmpeg.html#Filtering). The order of filters in the file is the order that they will be applied in, should several be selected. Video and audio input and output need to be referenced by `[inV]`, `[inA]`, `[outV]` and `[outA]`, respectively. Make sure other link labes (e.g. `[vid5]`) are unique to each filter, otherwise they will overwrite each other or cause erros. The file `log.cfg` helps with debugging as it logs every attempt of FFmpeg processing. Here are some usefull examples, from simple to more complex.

``` ini
[filter1]
name=Select audio track 1 only
filtergraph=[0:a:0]volume=1.2[outA]
[filter2]
name=Select audio track 2 only
filtergraph=[0:a:1]volume=1.2[outA]
[filter3]
name=Mute audio
filtergraph=[inA]volume=0[outA]
[filter4]
name=Color correct
filtergraph=[inV]hue=h=-7.4:s=1.2, eq=gamma=1.0:contrast=1.18:gamma_r=1.01:gamma_g=1.02:gamma_b=1.01[outV]
default=0

[filter5]
name=Add Intro and Outro
filtergraph=[inV] pad=ih*16/9:ih:(ow-iw)/2:(oh-ih)/2, scale=1280x720, setsar=sar=1/1 [vid5]; movie=\'C:\\Data\\Videos\\Editing\\intro_720p.mp4\':s=dv+da [v51] [a51]; movie=\'C:\\Data\\Videos\\Editing\\outro_720p.mp4\':s=dv+da [v52] [a52]; [v51] [a51] [vid5] [inA] [v52] [a52] concat=n=3:v=1:a=1[outV][outA]
```

Applying filters increases the video cutting processinf time, since the clips need to be re-encoded. When omiting filters, no re-encoding is necessary and cutting is much faster. It is recommended to first preview the clips without filters enabled and once the results satisfy re-run the cutting process with the desired filters enabled.


Building
--------

This is *not* a VLC Player plug-in. **egory** merely runs VLC Player as a sub-process. No files in the VLC Player installation will be modified, no binary files of either VLC nor FFmpeg are altered or included in this software. To build **egory** the latest Version of [AutoHotkey](http://autohotkey.com) is recommended. The compiler needs to find the icons in the [bin](bin/) directory (compile from working directory).

**Used scripts**

Besides making use of VLC Player and FFmpeg, the following AHK-scripts are included.

- **[VLC Media Player HTTP Functions Library](https://autohotkey.com/board/topic/64266-vlc-http-interface-library/)** authored by *'Richard "Specter333" Wells'* (modified)
- **[CtlColors](https://autohotkey.com/boards/viewtopic.php?t=2197)** authored by *'just me'*
- **[API_GetWindowInfo](https://autohotkey.com/board/topic/69254-func-api-getwindowinfo-ahk-l/)** authored by *'just me'*

Limitations and Known Issues
----------------------------

AutoHotkey is not the fastest scripting language, thus the responsiveness to windows resizing is a little slow. When switching between maximizing VLC media player and fullscreen, the timeline-bar jumps out of place on rare occaisons. Sometimes the coloring of the timeline clips disappears. It usually re-appears after clicking the timeline again.
