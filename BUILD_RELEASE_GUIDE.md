# Ejectify Release Build Guide

To properly distribute or install Ejectify for everyday use (without encountering Privileged Helper connection issues), you must create a Release build (Archive) rather than running it directly from Xcode in Debug mode.

## Steps to Build a Release Version

### 1. Xcode Setup
- Open `Ejectify.xcodeproj` in Xcode.
- Navigate to the **Signing & Capabilities** tab and ensure a valid Development Team is selected for both targets:
  - `Ejectify`
  - `EjectifyPrivilegedHelper`

### 2. Select Destination
- Look at the top bar in Xcode (next to the Play/Stop buttons) and click on the current device/simulator name.
- Select **Any Mac (Apple Silicon, Intel)** from the top of the list.
- *Note: Do not click the Run (Play) button while "Any Mac" is selected.*

### 3. Archive the Application
- On the Mac menu bar at the top of your screen, click **Product** -> **Archive**.
- Wait for Xcode to compile the application. This process generates a production build without the `get-task-allow` debug flag, allowing the Privileged Helper to run legally under macOS launch constraints.

### 4. Export the Application
- Once archiving completes, the **Organizer** window will automatically appear (If it doesn't, open it via *Window -> Organizer*).
- Select the newly created Archive from the list.
- Click the **Distribute App** button on the right pane.
- Choose **Custom** -> **Copy App** (this extracts the raw `.app` file instead of uploading it to the App Store).
- Click **Next** continuously and choose a location (e.g., Desktop) to save the app.

### 5. Installation and Usage
- Open the exported folder to locate **Ejectify.app**.
- Copy this file to your Mac's `/Applications/` directory.
- Launch the application directly from `/Applications/`.

*(macOS Background Task Management will now correctly recognize the installation path, and the XPC connection between the App and the Helper daemon will function properly).*
