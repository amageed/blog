---
date: 2012-02-25 21:57:57+00:00
layout: post
url: /posts/designating-different-audio-devices-for-playback-and-communication-on-windows-7
title: Designating different audio devices for playback and communication on Windows 7
tags: ['post','windows7']
---

My desktop is hooked up to external speakers, which all audio is emitted from. However, if I want to jump on a Skype call (or similar), all sound is routed to the USB headset as soon as I plug it in. This is great for the duration of the call, but since I have Pandora running almost constantly, or might want to watch (and hear) a video, I don't want to wear the headset all day. Plus, if I kept it plugged in I might miss all audio cues from Outlook, Skype notifications, and so on. True, most programs have visual cues too, but I might not be looking at that portion of the screen, or at the monitor the application lives on in the case of dual monitors.

I also didn't want to keep plugging and unplugging the USB, which meant I had to use an accessible USB slot instead of one behind the desktop - let's face it, who wants to see a distracting bunch of cable near them?

Determined to find a solution to a seemingly simple need, I played around with the sound settings. Originally I thought there might be a way to specify the audio device on a per application basis. Instead, I was happy to find a user-friendly option that's built right into Windows 7 (maybe Vista too, not sure, but you're not really using that are you?). Essentially, Windows 7 allows us to specify a _default device_ and a _default communications device_. Without further ado, here's how I set it up!

### Setting up playback devices

**Step 1:** Right-click the volume control, and select _"Playback devices"_

<p class="text-center">
    ![Volume Menu to select Playback devices](/images/audio-setup/VolumeMenu.png)
</p>

This will bring up the Sound control panel, which will look similar to the following image. On the _Playback_ tab notice that the USB headset is currently set as the default device. Your setup might be different, which is fine since the next couple of steps are the important ones.

<p class="text-center">
    ![Sound dialog with USB headset plugged in](/images/audio-setup/SoundDialog.png)
</p>

**Step 2:** set your desired speakers as the default device. A green check-mark icon will appear next to it.

<p class="text-center">
    ![Set default device](/images/audio-setup/SoundDialogSetDefault.png)
</p>

**Step 3:** set the USB headset as the default communication device.

<p class="text-center">
    ![Set the default communication device](/images/audio-setup/SoundDialogSetCommunication.png)
</p>

Upon doing so a green phone icon will appear next to it. The final setup should resemble the image below.

<p class="text-center">
    ![Different playback devices set to default and communications](/images/audio-setup/SoundDialogResult.png)
</p>

That's it! With the above setup I can now leave my USB headset plugged in, and only use it when speaking to someone on Skype or attending an online presentation. In the meantime all my audio is coming from my external speakers.

### Controlling other sounds when placing a call

Windows 7 provides a neat feature that adjusts the sound from other devices when using the communications device. The feature is known as [ducking, or stream attenuation](http://msdn.microsoft.com/en-us/library/windows/desktop/dd316773%28v=vs.85%29.aspx). By default, I found that the volume was lowered by 80% when I initiated a Skype call. It's a reasonable default, but I prefer to completely mute all other sounds. To do so, bring up the Sound control panel again, select the _Communications_ tab, then choose your desired option.

<p class="text-center">
    ![Ducking (stream attenuation) options](/images/audio-setup/SoundDialogCommunicationsDucking.png)
</p>
