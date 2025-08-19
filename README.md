# WKPlayer

---

## WKPlayer

**WKPlayer** is a powerful, cross-platform (iOS, tvOS, macOS) media player built upon **FFmpeg 7.0.1**. It leverages `AVSampleBufferDisplayLayer` for high-performance video rendering, with optional Metal support for specific processing tasks. It supports virtually all media formats and features robust SMB protocol playback capabilities.

### Features

*   **Cross-Platform**: Seamlessly runs on iOS, tvOS, and macOS.
*   **Powerful Decoding**: Utilizes FFmpeg 7.0.1 to decode a vast array of audio and video formats.
*   **High-Performance Rendering**: Uses the system's native `AVSampleBufferDisplayLayer` for efficient video playback, ensuring low power consumption and smooth performance.
*   **Metal Support**: Includes optional Metal-based rendering pipelines for advanced video processing.
*   **SMB Playback**: Supports streaming media directly from SMB shares via two independent libraries:
    *   **libsmbclient (Native FFmpeg Integration)**: Use the `smb://` scheme.
        Example: `smb://user:password@192.168.1.100:/Movies/video.mp4`
    *   **libsmb2 (Faster, Modern Protocol)**: Use the `smb2://` scheme for improved speed and SMB2/SMB3 protocol support.
        Example: `smb2://user:password@192.168.1.100:/Movies/video.mp4`
*   **High-Resolution Playback**: Fully capable of playing 4K HDR content.

### Dependencies

*   **FFmpeg 7.0.1**
*   **libsmb2**

### Required System Frameworks

You must link the following system frameworks and libraries in your Xcode project:

**Project -> Your Target -> Build Phases -> Link Binary With Libraries**

*   `VideoToolbox.framework`
*   `libresolv.tbd`
*   `libiconv.tbd`
*   `libz.tbd`

### Installation

1.  Clone or download the WKPlayer project.
2.  Ensure all submodules (FFmpeg, libsmb2) are initialized and updated.
    ```bash
    git submodule update --init --recursive
    ```
3.  Open the `.xcworkspace` or `.xcodeproj` file in Xcode.
4.  Build and run the target for your desired platform (iOS, tvOS, macOS).

### Usage

```objective-c

// Basic example to initialize and play a URL
import WKPlayer

// Initialize the player and set playview
self.player = [[WKPlayer alloc] init];
self.player.playView = self.view;

//Play a URL
self.url = URL(string: "smb2://user:pwd@192.168.1.10:/media/movie.mkv")
or
self.url = URL(string: "smb://user:pwd@192.168.1.10:/media/movie.mkv")
WKAsset *asset = [WKAsset assetWithURL:self.url];
[self.player replaceWithAsset:asset];
[self.player play];
```

### Development Progress:
- Version: Beta 0.1
- Task: Core feature completion

### License

This project is licensed under the MIT License - see the LICENSE file for details. Note that it includes FFmpeg and other libraries which are licensed under their respective terms.

---